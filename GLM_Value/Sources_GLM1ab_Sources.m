%%% S01_GLM1ab_Sources.m
%%%
%%% This script implements the same GLM run on the sensor-level, but on
%%% sources. SourceActivation = Chosen + Unchosen + Choice
%%%
%%% DA 2018/03/23
%%% DA 2018/03/27: Test how beta estimation changes when using individual
%%%                trials on subjects surfaces.
%%% DA 2018/04/09: Added time as second variable to save as bookkeeping.
%%% DA 2019/07/24: Note that betas are estimated on the cortical surface of
%%%                individual participants (it corresponds to averaging in HER case)
%%%                Betas are then projected on default anatomy and then smoothed.  
%%%                Name has changed (formerly S01_GLM_Hunt2013_Sources.m)
%%%                to comply with the name of the models in the main text. 
%%%                Note that the same code is used to run the GLM1a & GLM1b
%%%                at source level. 

clear
clc

%% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 1;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
end
addpath(fullfile(root_dir,'Final_Scripts/General/'));

%% WHICH DATA TO USE
GLMdata       = 'avgTime';

%% SUBJECT DEF
strtaskID 	 = getenv('SLURM_ARRAY_TASK_ID');
iS           = str2double(strtaskID);
% iS = 11;
fprintf('\n Processing subject %02d \n\n',iS);

% Single trial smoothed and default anatomy projected data
% Src_defAnat_fld     = fullfile(root_dir,'Results/Sources/ERP_RESP');
BS_root             = fullfile(root_dir,'Brainstorm_db/PREFER/data'); % Brainstorm database path

% TASK TO RUN
Tasks               = {'SUB'};

% TIME of PROJECTED DATA
if strcmp(GLMdata,'avgTime')
    time_src            = mean([-0.581:0.001:-0.207]);  % The Whole length of source time (here's the avg of the whole length)
    time_msk            = 1;                % Here is just not to change the code lower
    time                = [-0.581 -0.207]; % SUB = [-0.580  -0.197]; % The time you want to compute the GLM on (here's pointless)
elseif strcmp(GLMdata,'fullTime')
    time_src            = [-0.257:0.001:-0.025]; % The Whole length of source time 
    time                = [-0.257 -0.025]; % The time you want to compute the GLM on 
    time_msk            = time_src>=time(1)& time_src<=time(2); % the real time mask 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% IF YOU WANT TO USE THE CLUSTER FOUND WITH GLM TO SELECT THE TIME
% Cluster_Msk_dir     = fullfile(root_dir,'Results/GLM7Hunt2013_RESP');
% stats_name          = 'BETA_OBJ_megmag_ChosLum-UnchLum_p0.0250_nbchan2_latency-1.0to0.0_HER_PsychCurve.mat';%'BETA_SUB_megmag_ChosVal-UnchVal_p0.0250_nbchan2_latency-1.0to0.0_HER_PsychCurve.mat';
% load(fullfile(Cluster_Msk_dir,stats_name)); % Load the stats
% % Initiate mask
% cluster_msk         = zeros(size(stat_sub.posclusterslabelmat));
% cluster_msk(stat_sub.posclusterslabelmat==1) = 1;                   % Which cluster
% cluster_msk         = logical(cluster_msk);
% % Determine time (2 dimension)
% [~,t]               = find(cluster_msk==1);
% time_clus           = stat_sub.time(unique(t));
% time_msk            = ismember(time_src,time_clus);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% REGRESSORS
REG_fld             = fullfile(root_dir,'Final_Results/GLM_regressors');
reg_fn_end          = '_allTrials.mat';
REG                 = load(fullfile(REG_fld,sprintf('S%02d%s',iS,reg_fn_end)));

% Save folder
save_fld            = fullfile(root_dir,sprintf('Final_Results/Sources/ERP_RESP/GLMHunt2013/%s_%1.3fto%1.3f/Data',GLMdata,time));
if ~exist(save_fld,'dir'); mkdir(save_fld); end

for iTask = 1:length(Tasks)
    
    % Print info on the screen
    fprintf('\n Computing SUBJ %d TASK %s',iS,Tasks{iTask});
    
    % SELECT FOLDER BASED ON DATA
    if strcmp(GLMdata,'avgTime')
        SRC_fld             = sprintf('TbT_ERP_RESP_%s_avgTime_%1.3fto%1.3f',Tasks{iTask},time);
    elseif strcmp(GLMdata,'fullTime')
        SRC_fld             = sprintf('TbT_ERP_RESP_%s_fullTime_%1.3fto%1.3f',Tasks{iTask},time);
    end
    % load the bookkept trial list 
    load(fullfile(BS_root,sprintf('S%02d',iS),SRC_fld,'TrialNum_ERPsingleT.mat'));
    % Print info on the screen
    fprintf('\n Trials to load = %d',length(TrlsList));
    
    % Create matrix with all trials and vertex, averaged across time
    for trial = 1:length(TrlsList)
        
        
        % Print which trial you're loading on the same line
        if trial == 1
            fprintf('\n Loading trial n ');
        elseif trial > 1 && trial <= 10
            fprintf('\b');
        elseif trial <= 100
            fprintf('\b\b');
        elseif trial >100
            fprintf('\b\b\b');
        end
        fprintf('%d',trial);
        
        % Load single trial
        ResultsMat = [];
        
        % LOAD SOURCE DATA
        ResultsMat = load(fullfile(BS_root,sprintf('S%02d',iS),SRC_fld,... % Path to subject
            sprintf('results_TbTsources_trial%d.mat',trial)));                                        % Filename
        
        % Control that the time in the sources and those manually defined
        % are the same (give some tolerance of 0.1 ms)
        if any((ResultsMat.time-time_src)>1e-04)
            error(' Manually defined time and time in the source file are not the same');
        end
        % NUM OF VERTICES made subject dependent because it changes for
        % individual anatomies.
        % Read the size of the file for the subject and adjust accordingly
        if trial == 1
            VertNum             = size(ResultsMat.ImageGridAmp,1);
            %             trial_Src           = NaN(length(TrlsList),1,VertNum); % TO AVERAGE ACROSS TIME
            trial_Src           = NaN(length(TrlsList),sum(time_msk),VertNum); % TO COMPUTE ENTIRE GLM
        end
        
        %%%%%% DEPRECATED %%%%%%
        % AVG across the time of the cluster defined at sensor-level
        % trial_Src(trial,1,:)     = permute(mean(ResultsMat.ImageGridAmp(:,time_msk),2),[2,1]); % TO AVERAGE ACROSS TIME
        
        % FOR SOURCES WITH NO TIME DIMENSION
        % trial_Src(trial,1,:)    = ResultsMat.ImageGridAmp';
        %%%%%%%%%%%%%%%%%%%%%%%%
        
        if strcmp(GLMdata,'avgTime')
            % GLM ON ALL TIME-LENGTH
            trial_Src(trial,:,:)    = permute(ResultsMat.ImageGridAmp,[2,1]);
        elseif strcmp(GLMdata,'fullTime')
            % GLM ON ALL TIME-LENGTH
            trial_Src(trial,:,:)    = permute(ResultsMat.ImageGridAmp(:,time_msk),[2,1]);
        end
    end
    
    fprintf('\n\n');
    regressors           = [];
    % Prepare regressor matrix
    if     strcmp('SUB',Tasks{iTask})
        regressors       =      [zscore(REG.ChosenVal(TrlsList)), zscore(REG.UnchosVal(TrlsList)), REG.CHOICE(TrlsList)];
    elseif strcmp('OBJ',Tasks{iTask})
        regressors       =      [zscore(REG.ChosenLum(TrlsList)), zscore(REG.UnchosLum(TrlsList)), REG.CHOICE(TrlsList)];
    end
    
    % RUN GLM
    Beta                 = [];
    Beta                 = My_glm(trial_Src,regressors,1);
    
    % Save the results
    if strcmp(GLMdata,'avgTime')
        save_fn              = fullfile(save_fld,sprintf('S%02d_avgTime%1.3fto%1.3f_Task%s_IndivAnat.mat',iS,time(1),time(2),Tasks{iTask}));  % TO AVERAGE ACROSS TIME
    elseif strcmp(GLMdata,'fullTime')
        save_fn              = fullfile(save_fld,sprintf('S%02d_fullTime%1.3fto%1.3f_Task%s_IndivAnat.mat',iS,time(1),time(2),Tasks{iTask}));  % COMPUTE GLM ON TOTALITY OF TIME
    end
    save(save_fn,'Beta','time');
    
end

