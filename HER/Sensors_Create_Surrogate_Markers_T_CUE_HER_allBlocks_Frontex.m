% Create_Surrogate_Markers_T_CUE_HER_allBlocks_Frontex.m
% DA 2017/11/09
%
% This function creates new markers for surrogates HBs. The timing of surrogate HBs is not
% the original trial "i", but it comes from trial "j" belonging to the same
% task.
% The randomisation of HB latency with respect to CUE presentation is done
% across blocks.
% 
% DA 2017/11/13: Script adapted to run on ENS Frontex
% 
% DA 2018/05/10: The original script has been modified to run this control on the
%                final trials selection. 

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
    iS  = str2double(strtaskID);
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
    iS = 11;                                            % SUBJECT FOR DEBUGGING 
end
% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;

%% GENERAL SETTINGS 

% BLOCK & PERMUTATIONS DEFINITION 
% ss                      = 11; %[11:13 15:17 19:30 32:34];  % Subjects to include
blocks                  = 1:8;                        % Blocks to include
nPerm                   = 500;
nTrialsBlock            = 64;

fprintf('\n ################################')
fprintf('\n Creating %d Permutations across blocks',nPerm);
fprintf('\n ################################\n')

% SAVE MARKERS
save_update_Events      = true;
if save_update_Events == true
    warning(' You are adding markers to the Events structure');
end

meg_data_path       = fullfile(root_dir,'MEG_data');
Reg_fld             = fullfile(root_dir,'Final_Results/GLM_regressors');
trial_msk_path      = fullfile(root_dir,'Final_Results/TrialMask');
save_fld            = fullfile(root_dir,'Final_Results/MRK/Surrogated_HER_allBlocks500');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

orig_cardiac_mrk    = 'T_CUE_300_350_TRinterval400';
permuted_cardiac_mrk= 'T_CUE_300_350_TRinterval400_Perm';
mrk_begin_epoch     = 'CUE_ON_diode';
tstart = tic;

% Randomize seed for permutations
rng('shuffle');
% PRINTF SOME INFO 
fprintf('\n Processing subject %02d \n\n',iS)
fprintf(' Random order check: %s \n',mat2str(randi([1,10],1,10))); 

% Load trials mask
MSK             = load(fullfile(trial_msk_path,sprintf('S%02d_HER_AvgInTrl.mat',iS)));
REG             = load(fullfile(Reg_fld,sprintf('S%02d_allTrials.mat',iS))); 

% Initialize
TrlPresallBlocks= [];
CUE_allBlocks   = [];
BlockN          = [];
orig_CUE_T_lat  = struct();

%% RETRIEVE LATENCY HB-CUE for all blocks
for iB = blocks
    
    fprintf('\n Retrieving T-peaks SUB%d BLOCK%d',iS,iB);
    
    % LOAD EVENTS
    load(fullfile(meg_data_path,sprintf('S%02d/event/S%02d_Block%d_mrk.mat',iS,iS,iB)));   % Events structure
    
    
    % RETRIEVE RELATIVE POSITION OF ORIGINAL MARKERS
    orig_cardiac_samples   = [];
    orig_cardiac_samples   = Get_samples(Events,orig_cardiac_mrk)';
    CUE_samples            = [];
    CUE_samples            = Get_samples(Events,mrk_begin_epoch)';
    CUE_allBlocks          = [CUE_allBlocks; CUE_samples];
    BlockN                 = [BlockN; iB*ones(length(CUE_samples),1)];
    % Which trial do T peaks correspond to?
    Mask                = [];
    Mask                = Create_mask_prefer(Events,[],0);
    TrlN                = [];
    TrlN                = sort(Mask.TrialContinuous(Get_samples(Events,orig_cardiac_mrk)))';
    Trial2IncludeBlock  = []; 
    Trial2IncludeBlock  = MSK.TrlMsk((iB-1)*nTrialsBlock + (1:nTrialsBlock));
    HB2Include          = [];
    HB2Include          = Trial2IncludeBlock(TrlN);
    TrlPres             = zeros(length(CUE_samples),1);
    TrlPres(unique(TrlN)) = 1;
    if iB == 1
        for iT = 1:length(CUE_samples)
            orig_CUE_T_lat(iT).time   = orig_cardiac_samples(TrlN==iT)-CUE_samples(iT);
        end
    else
        for iT = 1:length(CUE_samples)
            orig_CUE_T_lat(length(orig_CUE_T_lat)+1).time   = orig_cardiac_samples(TrlN==iT)-CUE_samples(iT);
        end
    end
    TrlPresallBlocks    = [TrlPresallBlocks; TrlPres];
    clear Events block_behavior
end

% Trial per condition
idx_SUB         = [];
idx_SUB         = find(REG.Task==1&MSK.TrlMsk==1&TrlPresallBlocks~=0);
block_SUB       = [];
block_SUB       = BlockN(REG.Task==1&MSK.TrlMsk==1&TrlPresallBlocks~=0);
idx_OBJ         = [];
idx_OBJ         = find(REG.Task==2&MSK.TrlMsk==1&TrlPresallBlocks~=0);
block_OBJ       = [];
block_OBJ       = BlockN(REG.Task==2&MSK.TrlMsk==1&TrlPresallBlocks~=0);
% All trials to permute
OrigTrl2Permute = [1:nTrialsBlock*max(blocks)]';
OrigTrl2Permute(MSK.TrlMsk==0|TrlPresallBlocks==0) = NaN;
%% CREATE nPerm new T-peaks
allShuffTrl     = NaN(nTrialsBlock*max(blocks),nPerm);

for iPerm = 1:nPerm
    
    if iPerm == 1
        msg = sprintf('\n Permutation \t%d',iPerm);
        fprintf('\n %s',msg);
    elseif iPerm < 10
        msg = sprintf('%d',iPerm);
        fprintf('\b');
        fprintf(msg);
    elseif iPerm > 10
        msg = sprintf('%d',iPerm);
        fprintf('\b\b');
        fprintf(msg);
    elseif iPerm >= 100
        msg = sprintf('%d',iPerm);
        fprintf('\b\b\b');
        fprintf(msg);
    end
    
    new_event_name = sprintf('%s%d',permuted_cardiac_mrk,iPerm);
    
    % Shuffle
    NoGoodPerm = true;
    while NoGoodPerm == true
        
        %Shuffle indeces
        Shuffled_SUB             = [];
        id_Sub                   = [];
        [Shuffled_SUB,id_Sub]    = Shuffle_frontex(idx_SUB);
        
        Shuffled_OBJ             = [];
        id_Obj                   = [];
        [Shuffled_OBJ,id_Obj]    = Shuffle_frontex(idx_OBJ);
        if ~any(Shuffled_SUB==idx_SUB) && ~any(Shuffled_OBJ==idx_OBJ)
            NoGoodPerm = false;
        end
        
    end
    
    % Store the permuted trials
    allShuffTrl(idx_SUB,iPerm)    = Shuffled_SUB;
    allShuffTrl(idx_OBJ,iPerm)    = Shuffled_OBJ;
    
    % shuffled blocks
    ShuffBlock_SUB          = [];
    ShuffBlock_SUB          = block_SUB(id_Sub);
    ShuffBlock_OBJ          = [];
    ShuffBlock_OBJ          = block_OBJ(id_Obj);
    
    Shuf_T_SUB              = [];
    Shuf_T_SUB_block        = [];
    for i = 1:length(idx_SUB)
        Shuf_T_SUB          = [Shuf_T_SUB; CUE_allBlocks(Shuffled_SUB(i)) + orig_CUE_T_lat(idx_SUB(i)).time];
        Shuf_T_SUB_block    = [Shuf_T_SUB_block; repmat(ShuffBlock_SUB(i),length(orig_CUE_T_lat(idx_SUB(i)).time),1)];
    end
    Shuf_T_OBJ              = [];
    Shuf_T_OBJ_block        = [];
    for i = 1:length(idx_OBJ)
        Shuf_T_OBJ          = [Shuf_T_OBJ; CUE_allBlocks(Shuffled_OBJ(i)) + orig_CUE_T_lat(idx_OBJ(i)).time];
        Shuf_T_OBJ_block    = [Shuf_T_OBJ_block; repmat(ShuffBlock_OBJ(i),length(orig_CUE_T_lat(idx_OBJ(i)).time),1)];
    end
    Shuffled_T_mrk          = [];
    Shuffled_T_mrk          = [Shuf_T_SUB; Shuf_T_OBJ];
    allShuffBlocks          = [];
    allShuffBlocks          = [Shuf_T_SUB_block; Shuf_T_OBJ_block];
    
    %% RE-LOAD BLOCKS and SAVE NEW MRKS
    for iB = blocks
        
        SubBlockID      = sprintf('S%02d_Block%d',iS,iB);
        mrk_fn          = [SubBlockID,'_mrk.mat'];
        
        if iPerm == 1
            load(fullfile(meg_data_path,sprintf('S%02d/event',iS),mrk_fn));
        else
            load(fullfile(save_fld,mrk_fn));
        end
        % Current block
        block_T_mrk     = [];
        block_T_mrk     = Shuffled_T_mrk(allShuffBlocks==iB);
        % Create structure to add events
        events2add = struct();
        % The candidate event's samples
        for i = 1:length(block_T_mrk)
            events2add(i).(new_event_name) = block_T_mrk(i);
        end
        Events = add_Events(Events,events2add,0,0);
        
        Mask                = [];
        Mask                = Create_mask_prefer(Events,[],0);
        TrlN                = [];
        TrlN                = sort(Mask.TrialContinuous(Get_samples(Events,orig_cardiac_mrk)))';
        Trial2IncludeBlock  = []; 
        Trial2IncludeBlock  = MSK.TrlMsk((iB-1)*nTrialsBlock + (1:nTrialsBlock));
        HB2Include          = [];
        HB2Include          = Trial2IncludeBlock(TrlN);
        TrlN_Perm           = [];
        TrlN_Perm           = unique(sort(Mask.TrialContinuous(Get_samples(Events,new_event_name)))');
        
        if any(unique(TrlN(HB2Include==1))~=TrlN_Perm)
            error(' \n Trials in original markers and permuted ones are not the same in block %d',iB);
        end
        % Save the permutations in MRK file
        if save_update_Events == true
            save(fullfile(save_fld,mrk_fn),'Events');
        end
        
        clear Events
    end
    
end
% Save permutation information for all blocks
Task = REG.Task ;
save(fullfile(save_fld,sprintf('S%d_PermInfo.mat',iS)),...
    'orig_CUE_T_lat','CUE_allBlocks','OrigTrl2Permute','allShuffTrl','Task');

tend = toc(tstart);
fprintf('\n Creating Surrogate Heartbeats took %1.2f min \n',tend/60);