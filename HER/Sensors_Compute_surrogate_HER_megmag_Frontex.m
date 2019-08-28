% Compute_surrogate_HER_megmag_Frontex.m
% 
% The script computes the HERs on the surrogate HBs created by 
% Create_Surrogate_Markers_T_CUE_HER_allBlocks_Frontex.m
% 
% DA 2017/10/16

% FRONTEX
clear
clc
% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 1;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
    strtaskID = getenv('SLURM_ARRAY_TASK_ID');
    iPerm  = str2double(strtaskID);
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
    iPerm       = 1;
end
fprintf('\n Permutation number: %d \n',iPerm);

% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;

%% ANALYSIS PARAMETERS (same for all subjects)
blocks                  = 1:8;                        % Blocks to include
ss                      = [11:13 15:17 19:30 32:34];
% CHANNEL SELECTION
which_channels          = 'megmag';             % 'megmag' 'meggrad'
if strcmp(which_channels,'megmag')
    layout          = 'neuromag306mag.lay';
elseif strcmp(which_channels,'meggrad')
    layout          = 'neuromag306cmb.lay';
end

% FILTERING
lpf_freq                = 25;

% PATH DEFINITION
behavior_data_path  = fullfile(root_dir,'Behavior');
mrk_fld             = fullfile(root_dir,'Final_Results/MRK/Surrogated_HER_allBlocks500'); % Marker with the permuted HB

meg_data_path       = fullfile(root_dir,'MEG_data');
Reg_fld             = fullfile(root_dir,'Final_Results/GLM_regressors');
trialMask_path      = fullfile(root_dir,'Final_Results/TrialMask');
save_fld            = fullfile(root_dir,'Final_Results/HER_Cue/GAVG_SurrogateHER_allBlocks500');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

% ICA corrected folder and mat filename
data_folder_name    = 'correcteddata_ICA2'; 
data_suffix         = '_ICAblink.mat'; 

% SAVING FILENAME APPENDIX
fn_end              = ['_HER_AvgInTrl.mat'];

% CFG FOR DATA EPOCHING
parameters.moi          = sprintf('T_CUE_300_350_TRinterval400_Perm%d',iPerm);
parameters.channel      = which_channels; % 'megmag', 'BPCecg1'
parameters.prestim      = 0.050;
parameters.poststim     = 0.350;

%% PRINT PARAMETERS
fprintf('\n Parameters for HER epoching \n');
disp(parameters);
fprintf('\n Low-pass filter at %d Hz \n',lpf_freq);
% Keep time for computing
tstart = tic;



for iS = ss 
    
    
    fprintf('\n Processing subject %02d \n\n',iS)
    % Load trial Mask
    MSK         = load(fullfile(trialMask_path,sprintf('S%d%s',iS,fn_end)));
    REG         = load(fullfile(Reg_fld,sprintf('S%02d_allTrials.mat',iS))); 

    % Initialize variables
    TrlN_allBlocks      = [];
    epoched_data        = cell(1,max(blocks));
    Epoch_task          = [];
    MskEpochInclude     = []; 
    
    for iB = blocks
        
        % folder name
        Sub_fld         = sprintf('S%02d',iS);
        % filenames
        SubBlockID      = sprintf('%s_Block%d',Sub_fld,iB);
        meg_fn          = [SubBlockID,data_suffix];
        behavior_fn     = [SubBlockID,'.mat'];
        mrk_fn          = [SubBlockID,'_mrk.mat'];
        
        % load files
        load(fullfile(meg_data_path,Sub_fld,data_folder_name,meg_fn)); % MEG ICA corrected
        load(fullfile(behavior_data_path,behavior_fn)); % behavior
        load(fullfile(mrk_fld,mrk_fn));                 % Events structure
        
        % rename variable & clean the old one
        data = [];
        data = data_ICAblink;
        data_ICAblink =[];
        %% COMBINE STIM AND RESPONSE MATRIX
        block_behavior = [];
        block_behavior = Combine_BehavioralMat(stim_matrix,response_matrix);
        stim_matrix = []; response_matrix = [];
        
        %% EPOCH DATA
        
        % Which trial do the R and T peaks correspond to?
        Mask    = [];
        Mask    = Create_mask_prefer(Events,[],0);
        
        TrlN    = [];
        TrlN    = sort(Mask.TrialContinuous(Get_samples(Events,parameters.moi)))';
        
        TrlN_allBlocks   = [TrlN_allBlocks; (64*(iB-1))+TrlN]; % All the trials that were used for the HER
        
        epoched_data{iB} =  Epoch_data(parameters,data,block_behavior,Events);
             
    end
    
    %% CREATE A UNIQUE MASK FOR HER segments to include based on TRIAL-MASK
    % HER segments correct, artifact-free, no too long/short RTs, no too
    % long blinks
    MskEpochInclude   = MSK.TrlMsk(TrlN_allBlocks); % HER SEGMENTS
    Epoch_task        = REG.Task(TrlN_allBlocks);   % Task for HB
    %% SEPARATE CONDITIONS & COMPUTE ERPs
    
    % APPEND MEG DATA
    all_meg      = ft_appenddata([],epoched_data{:});
    epoched_data = [];
    
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
%     HER.initialHB        = her.nHB;
%     HER.TrialNb          = uniTrl;
    
    % Cut the mask and task to comply with present trials
    avgTrlMsk            = MSK.TrlMsk(uniTrl);
    avgTrlTask           = REG.Task(uniTrl);
    
    % SUBJECTIVE CUE
    cfg                  = [];
    cfg.trials           = [];
    cfg.trials           = find(avgTrlMsk==1&avgTrlTask==1);
    cfg.removemean       = 'no';
    if strcmp(which_channels,'megmag')
        SubCue          = ft_timelockanalysis(cfg,HER);
        % If using grads, combine them after ERFs
    elseif strcmp(which_channels,'meggrad')
        avg_SubjCue     = ft_timelockanalysis(cfg,HER);
        cfg             = [];
        cfg.method      = 'sum';
        SubCue          = ft_combineplanar(cfg,avg_SubjCue);
        avg_SubjCue     = [];
    end
    
    % Count # HER SUBJECTIVE store it in the subject structure
    SubCue.nHB          = sum(MskEpochInclude==1&Epoch_task==1); % total number of heartbeats
    SubCue.nTrl         = sum(avgTrlMsk==1&avgTrlTask==1);
    SubCue.cfg          =[];

    % OBJECTIVE CUE
    cfg                  = [];
    cfg.trials           = [];
    cfg.trials           = find(avgTrlMsk==1&avgTrlTask==2);
    cfg.removemean       = 'no';
    if strcmp(which_channels,'megmag')
        ObjCue           = ft_timelockanalysis(cfg,HER);
        % If using grads, combine them after ERFs
    elseif strcmp(which_channels,'meggrad')
        avg_ObjCue      = ft_timelockanalysis(cfg,HER);
        cfg             = [];
        cfg.method      = 'sum';
        ObjCue          = ft_combineplanar(cfg,avg_ObjCue);
        avg_ObjCue      = [];
    end
    % Count # trials OBJECTIVE
    ObjCue.nHB          = sum(MskEpochInclude==1&Epoch_task==2);
    ObjCue.nTrl         = sum(avgTrlMsk==1&avgTrlTask==2);
    ObjCue.cfg          =[];
    % Check that the trials in 2 conditions are not the same
    if ~isempty(intersect(find(MskEpochInclude==1&Epoch_task==1),...
            find(MskEpochInclude==1&Epoch_task==2)))
        error('\n The same trial(s) is/are present in both conditions');
    end
    
    % SAVE SUBJECT-WISE AVG
    save_fn_Sub = fullfile(save_fld,['S',num2str(iS),'_SubCue_',parameters.moi,'_',which_channels,'_lpfreq',num2str(lpf_freq),fn_end]);
    save(save_fn_Sub,'-struct','SubCue');
    save_fn_Obj = fullfile(save_fld,['S',num2str(iS),'_ObjCue_',parameters.moi,'_',which_channels,'_lpfreq',num2str(lpf_freq),fn_end]);
    save(save_fn_Obj,'-struct','ObjCue');
    
    % Clear Variables
    SubCue; ObjCue =[]; all_meg = []; HER = []; uniTrl =[]; her =[]; avgTrlMsk =[]; avgTrlTask =[]; 
end

% Get finish time & display
tend = toc(tstart);
fprintf('\n %d Permutations of SUBJ %d took %1.2f minutes \n',iPerm,iS,tend/60);

