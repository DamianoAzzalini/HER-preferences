function [epoched_data,trials2analyse,ErrorTrl,artifact_Trials] =  Epoch_data(parameters,meg_data,behavioral_data,Events)
% 
% [epoched_data,trials2analyse,trials2exclude] =  Epoch_data(parameters,meg_data,behavioral_data,Events)
% 
% Epoch_data epochs MEG data according to an marker/event of interest
% (moi). 
% INPUTS: 
%           - parameters:       structure with the fields
%                   - moi:          string with the name of the marker of interest
%                   - prestim:      scalar (in seconds). Prestimulus time 
%                   - poststim:     scalar (in seconds). Poststimulus time 
%                   - channel       string, label corresponding to channel to
%                                   select ('meg','BCPecg1'...)
%           - meg_data
%           - behavioral_data:  output of the Combine_BehavioralMat
%                               function
%           - Events
%
% 
% OUTPUTS: 
%           - epoched_data:     meg epoched data 
%           - trials2analyze    correct and artifact-free trials
%           - ErrorTrl:         trials containing beahvioral errors (Nx1 vector)
%           - artifact_Trials:  trials containing artifacts (Nx1 vector)
%           
% DA 2017/04/18
% DA 2017/04/20:    added outputs ErrorTrl and artifact_Trials
% DA 2017/05/02:    Removed Mask as input, since now it's computed on the
%                   fly based on Events through the function
%                   Create_mask_prefer (Anne's).
%% GET PARAMETERS OPTIONS 
prestim_time        = parameters.prestim;
poststim_time       = parameters.poststim; 
marker_of_interest  = parameters.moi; 
channel             = parameters.channel; 
%% DETERMINE GOOD TRIALS (THOSE CONTAINING ERRORS AND MEG ARTIFACTS ARE EXCLUDED)

% Error trials (indeces = trials number)
ErrorTrl = find(behavioral_data.Perf==0);

% Create Mask (Anne is not storing it anymore)
[Mask] = Create_mask_prefer(Events,[],0);

% Trials containing artifacts (indeces = trials number)
[~,artifact_Trials] = quantify_artifacts(Mask);
% Trials to exclude
trials2exclude = unique([ErrorTrl;artifact_Trials]);

% Check whether the number of trials in the mask and in the behavioral
% matrix is actually 64

% Mask check
if max(Mask.TrialContinuous) ~= 64
    error('Trials in the continuous mask are < 64 (pre-defined block length)')
end

% Behavioral matrix check
if length(behavioral_data.Resp)~= 64
    error('Behavioral matrix has less than 64 trials (pre-defined block length)')
end

trials2analyse = ones(length(behavioral_data.Perf),1);
trials2analyse(trials2exclude) = 0;

%% EPOCH DATA AROUND THE EVENT OF INTEREST (NB how to behave when baseline is distant from the event of interest)

% Select MEG channels
cfg                         = [];
cfg.channel                 = channel;
meg_dat                     = ft_selectdata(cfg,meg_data);

% Epoch data
cfg = [];
cfg.trialdef.fsample        = meg_dat.fsample;
cfg.trialdef.Events_struct  = Events;
cfg.trialdef.eventtype      = marker_of_interest;
cfg.trialdef.prestim        = prestim_time;
cfg.trialdef.poststim       = poststim_time;
cfg.trialfun                = 'PREFER_create_trl'; % the function creates trl matrix in a customized way
cfg_marker_tool             = ft_definetrial(cfg);  % create the cfg to pass onto redefine trial

epoched_data                = ft_redefinetrial(cfg_marker_tool, meg_dat);  % define epochs in ecg data

end