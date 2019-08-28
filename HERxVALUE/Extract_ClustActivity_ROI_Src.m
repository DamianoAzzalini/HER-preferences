%%% Extract_ClustActivity_ROI_Src.m
%%%
%%% The script extract cluster activity from the source activity using the
%%% scout provided by the user. 
%%%
%%% NB: YOU HAVE TO USE THE TRIALS PROJECTED TO DEFAULT ANATOMY !!!!!!
%%%
%%% DA 2018/04/09 
%%% Da 2019/07/24: This script is used for extracting activities in all the ROIs 
%%%                defined from statistical tests during choice (i.e. both decision types
%%%                for chosen value and chosen contrast).  Therefore, names, paths & 
%%%                timings should be adapted. 
%%%                As an example, here we show the extraction of activity in posterior r-vmPFC
%%%                encoding the value of the chosen option. 

clear
clc

% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 1;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
    strtaskID 	 = getenv('SLURM_ARRAY_TASK_ID');
    iS           = str2double(strtaskID);
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
    iS                  = 11;                       % Examplar subject
end
fprintf('\n Processing subject %02d \n\n',iS);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath(fullfile(root_dir,'Final_Scripts/General/'));

% SUBJECTS DEFINITION

%%%%%%%%% ======== ANALYSIS PARAMS ======== %%%%%%%%%
Task                = 'SUB';
TotNbTrials         = 512;             
save_fld            = fullfile(root_dir,'Final_Results/Sources/ERP_RESP/GLM_Hunt2013/avgTime_-0.580to-0.197/ChosenVal_ClusterAmp');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

%%%%%%%%% ============================ %%%%%%%%%

% SOURCES CHOSEN VALUE 
Chosen_scout_dir            = fullfile(root_dir,'Final_Results/Sources/ERP_RESP/GLM_Hunt2013/avgTime_-0.580to-0.197/Stats/Scouts');
Chosen_scout_name           = 'scout_R_vmPFC_avgTime_-0.580to-0.197_ChosenVal_smooth6.mat'; % name of the file containing the scout for the cluster
load(fullfile(Chosen_scout_dir,Chosen_scout_name));

%%%%%%%%% ======== SCOUT MASK ======== %%%%%%%%%
scout_mask                  = zeros(TessNbVertices,1);
scout_mask(Scouts.Vertices) = 1;
scout_mask                  = logical(scout_mask);
%%%%%%%%% ============================ %%%%%%%%%

%%%%%%%%% ======== TIME MASK ======== %%%%%%%%%
% time_src                   = [-0.6:0.001:0];
% GLM_time                   = [-0.582 -0.200];
% time_mask                  = time_src>=GLM_time(1) & time_src<=GLM_time(2);
%%%%%%%%% ============================ %%%%%%%%%

% TbT DEF ANAT PATH
TbT_fld                  = fullfile(root_dir,sprintf('Final_Results/Sources/ERP_RESP/TrialByTrial_DefAnat_%s_avgTime_-0.580to-0.197',Task)); 

fprintf('\n COMPUTING SUBJ %02d \n',iS);

% LOAD VECTOR OF TRIALS (brainstorm database)
load(fullfile(root_dir,sprintf('Brainstorm_db/PREFER/data/S%02d/TbT_ERP_RESP_%s_avgTime_-0.580to-0.197/TrialNum_ERPsingleT.mat',iS,Task)));
TrialMat                = NaN(size(TrlsList));

fprintf('\n %d Trials to load',size(TrlsList,1)); 

for itrial = 1:length(TrlsList)
    
    % Print which trial you're loading on the same line
    if itrial == 1
        fprintf('\n Loading trial n ');
    elseif itrial > 1 && itrial <= 10
        fprintf('\b');
    elseif itrial <= 100
        fprintf('\b\b');
    elseif itrial >100
        fprintf('\b\b\b');
    end
    
    fprintf('%d',itrial);
    ResultsMat              = [];
    load(fullfile(TbT_fld,sprintf('S%02d/S%02d_results_TbTsources_trial%d.mat',iS,iS,itrial))); % single trials mat
    
    sel                     = [];
    
    % Select space and time (when you have time dimension in sources ImagegridAmp)
%     sel                     = ResultsMat.ImageGridAmp(scout_mask,time_mask);

    % Select only vertex when you have no time dimension in sources ImageGridAmp
    if size(ResultsMat.ImageGridAmp,2)>1
        error('\n Sources have more than 1 timepoint'); 
    end
    sel                     = ResultsMat.ImageGridAmp(scout_mask,1);
    % Average across all points
    TrialMat(itrial,1)      = mean(sel(:));
    
end

% VECTOR OF 512 ENTRIES
ClusterAmp           = NaN(TotNbTrials,1); 
ClusterAmp(TrlsList) = TrialMat; 

% SAVE SUBJECTS CLUSTER AMPLITUDE 
save_fn                     = sprintf('S%02d_%s_ClusterAmp_%s',iS,Task,Chosen_scout_name); 
save(fullfile(save_fld,save_fn),'ClusterAmp','TrlsList'); 