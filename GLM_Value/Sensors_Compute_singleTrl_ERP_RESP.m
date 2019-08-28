%%% Compute_singleTrl_ERP_RESP.m
%%%
%%% This script computes single trials activity response-locked. 
%%%
%%%  DA 2018/03/22
%%%  DA 2019/07/24: Polished

clear
clc

%% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 1;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
    % GET THE SUBJECTS NUMBER FORM SLURM
    strtaskID           = getenv('SLURM_ARRAY_TASK_ID');
    iS                  = str2double(strtaskID);
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
    iS                  = 26; % for debugging locally
end

%% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'/Toolboxes/fieldtrip-20170705/'));ft_defaults;

%% ANALYSIS PARAMETERS
% ss                      = [11:13 15:17 19:30 32:34];  % Subjects to include

blocks                  = 1:8;                        % Blocks to include
BlockNtrials            = 64;

% CHANNEL SELECTION
which_channels          = 'meg';             % 'meg' 'megmag' 'meggrad'

% CFG FOR DATA EPOCHING
parameters.moi          = 'CUE_ON_diode' ;
parameters.channel      = which_channels; % 'megmag', 'BPCecg1'
parameters.prestim      = .5;
parameters.poststim     = 6;

baseline_twin           = [-.500 -.200];    % ERP baseline wrt to CUE
% Reduce time of ERP
Trl_begin               = -1;          % Beginning of trial wrt to RESP
Trl_end                 = .200;           % End of trial wrt to RESP

SamplingFreq            = 1000;         % Sampling frequency
lpf_freq                = 25;           % LP filter

% PATH DEFINITION
meg_data_path       = fullfile(root_dir,'MEG_data');
behavior_data_path  = fullfile(root_dir,'Behavior');
% trialMask_path      = fullfile(root_dir,'Final_Results/Trial_Mask'); % Common trial mask
mrk_fld             = 'event'; % marker folder
ICAcorrected_fld    = 'correcteddata_ICA2';
ICAcorrected_fn     = '_ICAblink.mat';

save_fld            = fullfile(root_dir,'Final_Results/ERP_RESP_singleTrl_-1s');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

%% PRINT PARAMETERS
fprintf('\n Parameters for epoching \n');
disp(parameters);
fprintf('\n Low-pass filter at %d Hz \n\n',lpf_freq);

% Keep time for computing
tstart = tic;

fprintf('\n Processing Subject %d \n',iS);
% initialize variables
epoched_data                = cell(1,max(blocks));

for iB = blocks
    
    % folder name
    Sub_fld = sprintf('S%02d',iS);
    % filenames
    SubBlockID      = sprintf('S%02d_Block%d',iS,iB);
    meg_fn          = [SubBlockID,ICAcorrected_fn];
    behavior_fn     = [SubBlockID,'.mat'];
    mrk_fn          = [SubBlockID,'_mrk.mat'];
    
    % load files
    MEG      = load(fullfile(meg_data_path,Sub_fld,ICAcorrected_fld,meg_fn)); % MEG ICA corrected
    BEHAVIOR = load(fullfile(behavior_data_path,behavior_fn)); % behavior
    MARKER   = load(fullfile(meg_data_path,Sub_fld,mrk_fld,mrk_fn)); % Events structure
    
    % rename variable & clean the old one
    data = [];
    data = MEG.data_ICAblink;
    MEG  = [];
    
    %% COMBINE STIM AND RESPONSE MATRIX
    block_behavior       = Combine_BehavioralMat(BEHAVIOR.stim_matrix,BEHAVIOR.response_matrix);
    BEHAVIOR             = [];
    
    %% EPOCH DATA
    
    % Epoch data
    baseline_data    =  Epoch_data(parameters,data,block_behavior,MARKER.Events);
    
    % Retrieve RESPONSE TRIGGERS TIMINGS
    cueOn   = Get_samples(MARKER.Events,'CUE_ON_diode')'; 
    Resp    = Get_samples(MARKER.Events,'RESP_corrected_12ms')'; % retrieve and correct for delay
    No_Resp = Get_samples(MARKER.Events,'NO_RESP')';
    if ~isempty(No_Resp)
        RESPTrigg   = sort([Resp; No_Resp]);
    else
        RESPTrigg   = Resp;
    end
    
    if length(RESPTrigg) ~= BlockNtrials
        error(' The number of trials is incorrect');
    end
    
    % FILTER & BASELINE
    cfg                 = [];
    cfg.lpfilter        = 'yes';
    cfg.lpfreq          = lpf_freq;
    cfg.demean          = 'yes';
    cfg.baselinewindow  = baseline_twin;
    baseline_data       = ft_preprocessing(cfg,baseline_data);
    
    % Create trials based on RESP/NO_resp trigger
    cfg             = [];
    resp_trl        = [];
    resp_trl(:,1)   = (RESPTrigg)+Trl_begin*SamplingFreq;
    resp_trl(:,2)   = (RESPTrigg)+Trl_end*SamplingFreq;
    resp_trl(:,3)   = Trl_begin*SamplingFreq;
    cfg.trl         = resp_trl;
    epoched_data{iB}= ft_redefinetrial(cfg,baseline_data);
    
    % Clear the samples for current block
    baseline_data = []; RESPTrigg =[]; Resp =[]; No_Resp =[]; MARKER =[]; block_behavior = []; 
    
end

%% SEPARATE CONDITIONS & COMPUTE ERPs

% APPEND MEG DATA
all_meg             = ft_appenddata([],epoched_data{:});

cfg                 = [];
cfg.removemean      = 'no';
cfg.keeptrials      = 'yes';
if strcmp(which_channels,'megmag') || strcmp(which_channels,'meg')
    ERP                 = ft_timelockanalysis(cfg,all_meg);
elseif strcmp(which_channels,'meggrad')
    avg             = ft_timelockanalysis(cfg,all_meg);
    cfg             = [];
    cfg.method      = 'sum';
    ERP             = ft_combineplanar(cfg,avg);
    avg             = [];
end
ERP.cfg             = [];
ERP.TrialNb         = [1:size(ERP.trial,1)]'; 
%% Save GLM RESULTS
ERP_fn                  = fullfile(save_fld,sprintf('S%02d_%s_lpfreq%d.mat',...
    iS,which_channels,lpf_freq));
save(ERP_fn,'-struct','ERP','-v7.3');

% Get finish time & display
tend = toc(tstart);
fprintf('\n The analysis took %1.2f minutes \n',tend/60);

