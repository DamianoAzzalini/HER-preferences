%%% Extract_HERAmp_ManualScouts.m
%%%
%%% This script extract the amplitude of HER at the source level, based on
%%% scouts defined manually with p<0.005 & MinSize=20 vertices. 
%%% It saves the HER amplitude for each subject and trials.  
%%% 
%%% 
%%% DA 2018/10/10
%%% DA 2019/07/25: The same code is used for extracting different ROIs used
%%%                for analyses. Here it is shown for anterior r-vmPFC for the 
%%%                preference-based trials. 
%%%                Polished. 

% SUBJECTS
% ss                  = [11:13 15:17 19:30 32:34];

clear
clc

%% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 1;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
    strtaskID = getenv('SLURM_ARRAY_TASK_ID');
    iS  = str2double(strtaskID);
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
    iS = 11; 
end

%% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));

fprintf('\n Processing subject %02d \n\n',iS)

% SCOUT DEFINITION
% The scout from which stats
scout_name          = 'scout_R_vmPFC_HER_p0.005_MinSize20.mat';
% Which scout (number)
which_scout         = 1; % This was used for scouts defined from non-parametric stats. 
                         % It is not used anymore as there is only one scout per file

% WHICH TASK TO COMPUTE
Tasks               = {'SUB'};
ToI                 = [0.201 0.262];
tot_NbTrials        = 512; 
% PATHS
BS_root             = fullfile(root_dir,'Brainstorm_db/PREFER/data');
regress_fld         = fullfile(root_dir,'Final_Results/GLM_regressors');
Scouts_fld          = fullfile(root_dir,'Final_Results/Sources/HER_cue/ManualScouts');

% LOAD THE SCOUT & create the mask
Scouts_region       = sprintf('R_vmPFC_avg%1.3f-%1.3f',ToI); %%% THE NAME FOR SAVING

load(fullfile(Scouts_fld,scout_name));
scout_msk           = zeros(TessNbVertices,1);

% ARE THERE MORE THAN ONE ROI IN THE SCOUT? 
if any(size(Scouts)>1)
    scout_msk(Scouts(which_scout).Vertices) = 1;
    fprintf('\n'); 
    fprintf(' The Scout has more than one ROI. You''re using the number %02d',which_scout); 
else
    fprintf('\n'); 
    fprintf(' The Scout has only one ROI'); 
    scout_msk(Scouts.Vertices) = 1;
end
scout_msk           = logical(scout_msk);

trialInfo_fn        = sprintf('TrialNum_HERsingleT.mat');
save_dir            = fullfile(root_dir,'Final_Results/Sources/HER_cue/HERamp_AvgInTrl_ManualScouts');
if ~exist(save_dir,'dir')
    mkdir(save_dir);
end


for iTask = 1:length(Tasks)
    
    % LOAD TRIAL INFO (this is in the BrainStorm db)
    TrlsList    = [];
    TbT_DefAnat         = fullfile(root_dir,'Final_Results/Sources/HER_cue',sprintf('TrialByTrial_DefAnat_%s_AvgInTrl_avgTime_%1.3fto%1.3f',Tasks{iTask},ToI));
    load(fullfile(BS_root,sprintf('S%d/TbT_HER_Cue_%s_AvgInTrl_avgTime_%1.3fto%1.3f/%s',iS,Tasks{iTask},ToI,trialInfo_fn)));
    ntrial              = length(TrlsList);
    her_amp             = zeros(ntrial,1);
    her_amp_AllVert     = zeros(ntrial,sum(scout_msk)); 
    
    % Feedback on screen
    fprintf('\n Retrieving HER amplitude for %d trials',ntrial);
        
    for itrial = 1:ntrial
        % LOAD INDIVIDUAL TRIALS
        load(fullfile(TbT_DefAnat,sprintf('S%d/S%d_results_TbTsources_trial%d.mat',...
            iS,iS,itrial)));
        
        % Check if the sizes are correct
        if any(size(ResultsMat.ImageGridAmp,1)~=size(scout_msk,1)) % | size(ResultsMat.ImageGridAmp,2)~=size(time_trial,2)) time check is no needed anymore
            error(' Mismatch between source data and mask files');
        end
        
        % Mean cluster amplitude (avg over space)
        her_amp(itrial,1)           = mean(ResultsMat.ImageGridAmp(scout_msk,:),1);
        % Amplitude of all vertices (trial X n Vertices)
        her_amp_AllVert(itrial,:)   = ResultsMat.ImageGridAmp(scout_msk,:)';
    end
    fprintf('\n %d trials retrieved',itrial); 

    % CREATE A COMPLETE VECTOR WITH HER AMPLITUDES (512 entries)
    HER                    = NaN(tot_NbTrials,1);
    HER(TrlsList)          = her_amp;
    
    % This is the activity for all vertices 
    HER_allVert            = NaN(tot_NbTrials,sum(scout_msk));
    HER_allVert(TrlsList,:)= her_amp_AllVert; 
    
    % SAVE
    save_filename       = sprintf('S%02d_HERamp_Task%s_%s.mat',iS,Tasks{iTask},Scouts_region);
    save(fullfile(save_dir,save_filename),'HER','TrlsList','HER_allVert');
    
    % CLEAR SOME VARS
    TrlsList               = [];
end

