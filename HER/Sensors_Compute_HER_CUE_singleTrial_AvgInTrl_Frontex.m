% Compute_HER_CUE_singleTrial_AvgInTrl_Frontex.m
%
%
% The script computes HER for artifact-free, correct and incorrect trials.
%
% Criteria for trial exclusion:
%   - Error trials for which RT > 2STD | RT < .250 s are excluded 
%       (outliers computed within 4 difficulty level bins for correct & error trials separately)
%   - Eyes closed >20% time
%   - Trials contain movie that subjects have reported to have difficulty
%       with (not remebered, confused, asked during debriefing).
% 
% If multiple HBs are present in the same trials they are averaged to
% produce one HER per trial. 
% 
% DA 2018/04/24
% DA 2019/07/24 Code polished

% FRONTEX
clear
clc
% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 1;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
end
% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;

%%%%%%%%% =========== SUBJECT TO RUN =========== %%%%%%%%%
% ss                      = [11:13 15:17 19:30 32:34];  % Subjects to include
strtaskID             = getenv('SLURM_ARRAY_TASK_ID');
iS                    = str2double(strtaskID);
% iS                      = 11;
fprintf('\n Processing subject %02d \n\n',iS);
%%%%%%%%% ===================================== %%%%%%%%%

% ANALYSIS PARAMETERS
blocks                  = 1:8;                        % Blocks to include

% CHANNEL SELECTION
which_channels          = 'meg';             % 'megmag' 'meggrad'
if strcmp(which_channels,'megmag')
    layout          = 'neuromag306mag.lay';
elseif strcmp(which_channels,'meggrad')
    layout          = 'neuromag306cmb.lay';
end

% CRITERIA FOR TRIALS REJECTION
Nbins                   = 4;                    % Nbins for difficulty level (DELTAQ)
stdRT                   = 2;                    % STD above which reject trial based on RT
shortRT                 = .250;                 % RTs considered too short (in seconds)
blink_percent_thd       = .20;                  % The percentage of time blinks are present (from CUE to R) above which a trial is removed

% CFG FOR DATA EPOCHING
parameters.moi          = 'T_CUE_300_350_TRinterval400' ;
parameters.channel      = which_channels; % 'megmag', 'BPCecg1'
parameters.prestim      = 0.050;
parameters.poststim     = 0.350;
SamplingFreq            = 1000;
% FILTERING
lpf_freq                = 25;

% PATH DEFINITION
meg_data_path           = fullfile(root_dir,'MEG_data');
behavior_data_path      = fullfile(root_dir,'Behavior');

% marker folder
mrk_fld                 = 'event';
% ICA corrected folder and mat filename
data_folder_name        = 'correcteddata_ICA2'; 
data_suffix             = '_ICAblink.mat'; 

save_fld                = fullfile(root_dir,'Final_Results/HER_Cue/SingleTrl');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

% SAVING FILENAME APPENDIX
fn_end                  = '_AvgInTrl.mat';

%% PRINT PARAMETERS
fprintf('\n Parameters for HER epoching \n');
disp(parameters);
fprintf('\n Low-pass filter at %d Hz \n',lpf_freq);
% Keep time for computing
tstart = tic;

% Initialize variables
Epoch2analyse               = [];
artifacts_allBlocks         = [];
TrlLongBlink                = [];
EpochLongBlink              = [];
RT                          = [];
TrlN_allBlocks              = [];
epoched_data                = cell(1,max(blocks));
block_behavior              = cell(1,max(blocks));

for iB = blocks
    
    % folder name
    Sub_fld             = sprintf('S%02d',iS);
    % filenames
    SubBlockID          = sprintf('S%02d_Block%d',iS,iB);
    meg_fn              = [SubBlockID,data_suffix];
    behavior_fn         = [SubBlockID,'.mat'];
    mrk_fn              = [SubBlockID,'_mrk.mat'];
    
    % load files
    MEG                 = load(fullfile(meg_data_path,Sub_fld,data_folder_name,meg_fn)); % MEG ICA corrected
    BEHAVIOR            = load(fullfile(behavior_data_path,behavior_fn)); % behavior
    MARKER              = load(fullfile(meg_data_path,Sub_fld,mrk_fld,mrk_fn)); % Events structure
    
    % rename variable & clean the old one
    data                = [];
    data                = MEG.data_ICAblink;
    MEG                 = [];
    
    %% COMBINE STIM AND RESPONSE MATRIX
    block_behavior{iB}   = Combine_BehavioralMat(BEHAVIOR.stim_matrix,BEHAVIOR.response_matrix);
    BEHAVIOR             = [];
    
    %% EPOCH DATA
    
    % If you create new markers
    Events              = [];
    if isempty(Get_samples(MARKER.Events,parameters.moi))
        Events          = Add_HER_single_marker(cfg_HER,MARKER.Events,false);
        % If you load already created markers
    elseif ~isempty(Get_samples(MARKER.Events,parameters.moi))
        fprintf('\n %s marker is already present. \n Use the present ones',parameters.moi); 
        Events          = MARKER.Events;
    end
    MARKER              = [];
    
    % Which trial do the R and T peaks correspond to?
    Mask                = [];
    Mask                = Create_mask_prefer(Events,[],0);
    
    TrlN                = [];
    TrlN                = sort(Mask.TrialContinuous(Get_samples(Events,parameters.moi)))';
    
    TrlN_allBlocks      = [TrlN_allBlocks; (64*(iB-1))+TrlN]; % All the trials that were used for the HER
    
    % To include only artifact-free trials
    artifacts                        =  [];
    [epoched_data{iB},~,~,artifacts] =  Epoch_data(parameters,data,block_behavior{iB},Events);
    % Check that artifacts in the block do not exceed 64 (tot n of trials in the block)
    if max(artifacts) > 64
        error(' Trial marked as artifact is incorrect (>64)');
    end
    artifacts_allBlocks              = [artifacts_allBlocks; (64*(iB-1))+artifacts];
    
    %% EXCLUDE TRIALS IN WHICH BLINK TIME > blink_percent_thd% OF TIME (CUE to R)
    
    % Subjects & blocks for which you use vEOG (bad Eyelink signal)
    if any(strcmp(SubBlockID,{'S13_Block6','S26_Block7','S30_Block6','S34_Block4',...
            'S15_Block5','S15_Block6','S15_Block7','S15_Block8'}));
        thdBlink = 0.2; % threshold above which EOG signal is considered a blink
        % Get and filter vEOG data
        vEOG_flt        = [];
        cfg             = [];
        cfg.channel     = 'BPCveog';
        cfg.lpfilter    = 'yes';
        cfg.lpfreq      = 25;
        vEOG_flt        = ft_preprocessing(cfg,data);
        % square vEOG and z-score it
        Z_vEOG = [];
        Z_vEOG = zscore(vEOG_flt.trial{1}.^2); % z-score after rectifying the signal to get a result more similar to eyelink
        % Create a Mask when z-score is > thdBlink
        MaskEOG = zeros(1,length(vEOG_flt.time{1}));
        MaskEOG(Z_vEOG>=thdBlink)=1;
        % Substitute mask based on Eyelink with mask based on EOG
        Mask.BlinkContinuous =[];
        Mask.BlinkContinuous = MaskEOG;
    end
    BlinkPercent        = []; 
    BlinkPercent        = Quantify_percentage_blink(Events,Mask,'CUE_ON_diode','RESP_corrected_12ms',0);
    if length(BlinkPercent)~=64 
       error(' Trials retrieved for blink percentage check different from 64'); 
    end
    LongBlinkBlock      = zeros(length(BlinkPercent),1);
    LongBlinkBlock(BlinkPercent>=blink_percent_thd) = 1; % 1s = trial has to be excluded because of too long blinks
    TrlLongBlink        = [TrlLongBlink; LongBlinkBlock];          % Trials with blink > X%
    EpochLongBlink      = [EpochLongBlink; LongBlinkBlock(TrlN)];   % HER epoch with blinks >X%
    
    %% RETRIEVE RTs
    
    % COMPUTE RT USING TRIGGERS TIMINGS
    Stim_On             = Get_samples(Events,'STIM_ON_diode')'; % retrieve and correct for delay
    Resp                = Get_samples(Events,'RESP_corrected_12ms')'; % retrieve and correct for delay
    No_Resp             = Get_samples(Events,'NO_RESP')';
    if ~isempty(No_Resp)
        RESP            = sort([Resp; No_Resp]);
        % Set non-responses to NaNs
        id_noresp       = ismember(RESP,No_Resp);
        RESP(id_noresp) = NaN;
        id_noresp       = [];
    else
        RESP            = Resp;
    end
    % Check that non-responses are coded as NaN in behavioral matrix
    if any(~isnan(block_behavior{iB}.Resp(isnan(RESP))))
        error('A non-response has been recorded as valid response in block %d trial %s',iB,mat2str(find(~isnan(block_behavior{iB}.Resp(isnan(Resp))))));
    end
    
    % Compute RTs
    RT = [RT; RESP-Stim_On];
    
    % Clear the samples for current block
    Stim_On = [];  Resp =[];  No_Resp = [];  RESP = [];
end

%% SUBSTITUTE correct RTs 
all_behavior        = append_behavior_data(block_behavior); % append behavior
RT                  = RT./SamplingFreq;
block_behavior      = [];
% Substitute the field RT with the RT calculated from triggers
all_behavior.RT_matlab = all_behavior.RT;
all_behavior.RT = []; all_behavior.RT = RT;

Trl2analyse                         = ones(length(all_behavior.Performance),1);
Trl2analyse(artifacts_allBlocks)    = 0;
Trl2analyse(isnan(all_behavior.RT)) = 0; % no response was given

%% REMOVE THE MOVIES THEY HAVE REPORTED NOT TO HAVE SEEN
% There are some subject who reported there were movies they
% haven't seen or they confused them with others -> exclude those
% trials
mov2rej       =[];
if iS == 12
    mov2rej       = find_pairs(all_behavior,{'Scream 3'}); % trials to be removed should be n. 337 & 471
    Trl2analyse(mov2rej)= 0;
    % Star Wars is a bit conservative too remove it, but just to be on the safe side.
elseif iS == 14
    mov2rej       = find_pairs(all_behavior,{'The Artist','Star Wars Ep. 1','Star Wars Ep. 2',...
        'Star Wars Ep. 3','Star Wars Ep. 4','Star Wars Ep. 6','Star Wars Ep. 7'});
    Trl2analyse(mov2rej)= 0;
elseif iS == 18
    mov2rej       = find_pairs(all_behavior,{'Gran Torino'});
    Trl2analyse(mov2rej)= 0;
elseif iS == 27
    mov2rej       = find_pairs(all_behavior,{'The Impossible'});
    Trl2analyse(mov2rej)= 0;
elseif iS == 29
    mov2rej       = find_pairs(all_behavior,{'Space Jam'});
    Trl2analyse(mov2rej)= 0;
elseif iS == 31
    mov2rej       = find_pairs(all_behavior,{49}); % index 49 corresponds to 'Joyeuses P?ques' that is not read in Mac's encoding
    Trl2analyse(mov2rej)= 0;
end

%% EXCLUDE RT > 2STD & < 250 ms for CORRECT TRIALS
idxDeltaQ                           = find(Trl2analyse==1&TrlLongBlink==0&all_behavior.Performance==1); % indeces correct and artifact-free trials
DeltaQ4Binning                      = all_behavior.DeltaQ(idxDeltaQ);    % vector of DeltaQ for correct trials only
[good_binned_DeltaQ,~,~]            = bin_data(DeltaQ4Binning,Nbins);    % bin only correct trials
corr_binned_DeltaQ                  = NaN(size(all_behavior.Performance,1),1);
corr_binned_DeltaQ(idxDeltaQ)       = good_binned_DeltaQ;             % put in a vector of the total length of trials the binning solutionLongRT
TrlLongRT_correct                   = zeros(length(all_behavior.RT),1); % Initialize vector
for iD = 1:Nbins
    for iTask = 1:2
        currIdx     =[];
        currIdx     = find((all_behavior.Task==iTask&corr_binned_DeltaQ==iD&all_behavior.Performance==1));
        if sum(isnan(all_behavior.RT(currIdx)))>0
            error('There are NaNs in Delta %d Task %d',iD,iTask); % Check if there are NaN in the selected RTs
        end
        RT2exclude  =[];
        RT2exclude  = (all_behavior.RT(currIdx) > (mean(all_behavior.RT(currIdx))+ stdRT*std(all_behavior.RT(currIdx))) ...
            | all_behavior.RT(currIdx) < shortRT);
        if sum(RT2exclude) > 0
            TrlLongRT_correct(currIdx(RT2exclude==1)) = 1; % 1 = trials with too long RT
        end
    end
end
EpochLongRT_corr           = TrlLongRT_correct(TrlN_allBlocks); % HER segments with too long blinks

%% EXCLUDE RT > 2STD & < 250 ms for ERROR TRIALS
idxDeltaQ                   = [];
idxDeltaQ                   = find(Trl2analyse==1&TrlLongBlink==0&all_behavior.Performance==0); % indeces error and artifact-free trials
DeltaQ4Binning              = all_behavior.DeltaQ(idxDeltaQ);    % vector of DeltaQ for error trials only
error_binned_DeltaQ         = bin_data(DeltaQ4Binning,Nbins);    % bin only error trials
err_binned_DeltaQ           = NaN(size(all_behavior.Performance,1),1);
err_binned_DeltaQ(idxDeltaQ)= error_binned_DeltaQ;             % put in a vector of the total length of trials the binning solutionLongRT
TrlLongRT_error             = zeros(length(all_behavior.RT),1); % Initialize vector
for iD = 1:Nbins
    for iTask = 1:2
        currIdx     =[];
        currIdx     = find((all_behavior.Task==iTask&err_binned_DeltaQ==iD&all_behavior.Performance==0));
        if sum(isnan(all_behavior.RT(currIdx)))>0
            error('There are NaNs in Delta %d Task %d',iD,iTask); % Check if there are NaN in the selected RTs
        end
        RT2exclude  =[];
        RT2exclude  = (all_behavior.RT(currIdx) > (mean(all_behavior.RT(currIdx))+ stdRT*std(all_behavior.RT(currIdx))) ...
            | all_behavior.RT(currIdx) < shortRT);
        if sum(RT2exclude) > 0
            TrlLongRT_error(currIdx(RT2exclude==1)) = 1; % 1 = trials with too long RT/too short RT
        end
    end
end

EpochLongRT_err           = TrlLongRT_error(TrlN_allBlocks); % HER segments with too long blinks

%% CREATE A UNIQUE MASK FOR HER segments and TRIALS TO INCLUDE
% HER segments artifact-free, no too long/short RTs, no too
% long blinks
Epoch2analyse   = Trl2analyse(TrlN_allBlocks); % HER SEGMENTS
MskEpochInclude = ones(length(Epoch2analyse),1);
MskEpochInclude(Epoch2analyse==0|EpochLongRT_corr==1|EpochLongRT_err==1|EpochLongBlink==1) = 0;

%% COMPUTE HER

% APPEND MEG DATA
all_meg      = ft_appenddata([],epoched_data{:});

cfg                  = [];
cfg.preproc.lpfilter = 'yes';
cfg.preproc.lpfreq   = lpf_freq;
cfg.trials           = [];
cfg.trials           = find(MskEpochInclude==1);
cfg.keeptrials       = 'yes';
cfg.removemean       = 'no';
her                  = ft_timelockanalysis(cfg,all_meg);

% Count # HER SUBJECTIVE store it in the subject structure
her.nHB             = sum(MskEpochInclude==1);
TrialNb             = TrlN_allBlocks(MskEpochInclude==1);
her.cfg             = [];
her.RT              = all_behavior.RT;

% Average HBs in the same trial 
uniTrl              = unique(TrialNb); 
avgHER              = NaN(length(uniTrl),size(her.trial,2),size(her.trial,3));
for iH = 1:length(uniTrl)
    if sum(TrialNb==uniTrl(iH)) > 1
        avgHER(iH,:,:) = mean(her.trial(TrialNb==uniTrl(iH),:,:),1);
    elseif sum(TrialNb==uniTrl(iH)) == 1
        avgHER(iH,:,:) = her.trial(TrialNb==uniTrl(iH),:,:); 
    end
end
% Check no value is NaN 
if any(isnan(avgHER(:)))
    error(' A NaN value is present in the data'); 
end

% Create new HER structure with the within-trial average 
HER.time             = her.time; 
HER.label            = her.label; 
HER.trial            = avgHER; 
HER.dimord           = her.dimord; 
HER.initialHB        = her.nHB;
HER.TrialNb          = uniTrl; 
HER.RT               = her.RT; 
% SAVE SUBJECT-WISE AVG
save_fn = fullfile(save_fld,sprintf('S%02d_SingleTrl_%s_%s_lpfreq%d%s',iS,parameters.moi,which_channels,lpf_freq,fn_end));
save(save_fn,'-struct','HER','-v7.3');

% Get finish time & display
tend = toc(tstart);
fprintf('\n The analysis took %1.2f minutes \n',tend/60);

