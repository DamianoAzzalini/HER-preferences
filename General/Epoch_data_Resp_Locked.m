function [epoched_data,trials2analyse,ErrorTrl,artifact_Trials] =  Epoch_data_Resp_Locked(parameters,meg_data,behavioral_data,Events)
%
% [epoched_data,trials2analyse,trials2exclude] =  Epoch_data_Resp_Locked(parameters,meg_data,behavioral_data,Events)
%
% Epoch_data_Resp_Locked epochs MEG data with respect to a response
% trigger. The trial will go from prestim_wrt_Trigg-prestimTrigg to
% postimulus time. 
% NB: Trial will be of variable length (as RT are different in different trials)
% 
% (moi).
% INPUTS:
%           - parameters:       structure with the fields
%                   - moi:               string with the name response
%                                        trigger 
%                   - prestim_wrt_Trigg: scalar (in seconds). Prestimulus
%                                        time with respect to other trigger (because time from response is variable)
%                                        used as end of baseline e.g. 'CUE_ON_diode','STIM_ON_diode', etc. 
%                   - prestimTrigg:      string. Trigger name in the Events structure with respect to which calculate 
%                                        the baseline
%                   - poststim:          scalar (in seconds). Poststimulus time
%                   - channel            string, label corresponding to channel to
%                                        select ('meg','BCPecg1'...)
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
% DA 2017/10/05

%% GET PARAMETERS OPTIONS
baseline_Trigg      = parameters.baseline_Trigg;
baseline_twin       = parametes.baseline;
prestim_time        = baseline_twin(1); 
postTime_after_resp = parameters.postTime_after_resp; 
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

% TRIAL BEGINNING WRT TIME BEFORE OTHER TRIGGER (FOR BASELINE CORRECTION)
Resp                        = Get_samples(Events,'RESP_corrected')'; 
No_Resp                     = Get_samples(Events,'NO_RESP')';

if ~isempty(No_Resp)
    RESP = sort([Resp; No_Resp]);
    % Set non-responses to NaNs
    id_noresp = ismember(RESP,No_Resp);
    RESP(id_noresp) = NaN;
    id_noresp = [];
else
    RESP = Resp;
end

poststim_time           = RESP+postTime_after_resp;

% Epoch data locked to baseline trigger
cfg = [];
cfg.trialdef.fsample        = meg_dat.fsample;
cfg.trialdef.Events_struct  = Events;
cfg.trialdef.eventtype      = baseline_Trigg;
cfg.trialdef.prestim        = prestim_time;
cfg.trialdef.poststim       = poststim_time;
cfg.trialfun                = 'PREFER_create_trl'; % the function creates trl matrix in a customized way
cfg_marker_tool             = ft_definetrial(cfg);  % create the cfg to pass onto redefine trial

baselineLocked_epoch        = ft_redefinetrial(cfg_marker_tool, meg_dat);  % define epochs in ecg data

% Redifine trials locked to response 
cfg                         = []; 
cfg.endsample               = RESP; 
cfg.begsample               = x; 
responseLocked_epoch        = ft_redefinetrial(cfg, baselineLocked_epoch);


end