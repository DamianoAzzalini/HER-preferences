% Compute_GLM1ab_ERP_Resp.m
%
% This script implements GLM1 (either a or b depending on the task) 
% at the sensor level on single trial ERP time-locked to response:
%
% Predictors for SUBJECTIVE TASK are
% (1) Chosen value
% (2) Unchosen value
% (3) Choice (1 top/-1 bottom)
%
% Predictors fort OBJECTIVE TASK are 
% (1) Chosen Luminance 
% (2) Unchosen Luminance
% (3) Choice (1 top/-1 bottom)
% 
% DA 2018/02/14: This is the updated version that can be run on Frontex to
%                speed up analysis;
% DA 2018/03/22: Added if statement to change predictor matrix depending on
%                the task the user is analyzing.
% DA 2018/11/04: - Minor changes marked with PREVIOUS VERSION title. 
%                - Paths have been changed to write into Final_Results
%                - TrialMask is now the one from HER_AvgInTrl
% DA 2019/07/24: Polished and the script has renamed to comply with the
%                GLM name in the main text (previously called Compute_GLM7_Hunt2013_ERP_Resp.m). 

%% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 1;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
    strtaskID       = getenv('SLURM_ARRAY_TASK_ID');
    iS              = str2double(strtaskID);
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
    iS              = 26; 
end
fprintf('\n Processing subject %02d \n\n',iS);
%% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;

%% ANALYSIS PARAMETERS

% CHANNEL SELECTION
which_channels          = 'megmag';             % 'megmag' 'meggrad'
if strcmp(which_channels,'megmag')
    layout          = 'neuromag306mag.lay';
elseif strcmp(which_channels,'meggrad')
    layout          = 'neuromag306cmb.lay';
end

% TASK SELECTION
Cnames             = {'SUB','OBJ'};

% ERP LP FILTER
ERP_lpf_freq       = 25;
% PATH DEFINITION
ERP_fld         = fullfile(root_dir,'Final_Results/ERP_RESP_singleTrl_-1s');
MSK_fld     	= fullfile(root_dir,'Final_Results/TrialMask');
msk_fn_end      = '_HER_AvgInTrl.mat';
REG_fld         = fullfile(root_dir,'Final_Results/GLM_regressors');
reg_fn_end      = '_allTrials.mat';
save_fld        = fullfile(root_dir,'Final_Results/GLM_sensors/GLM7Hunt2013_RESP');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

% Keep time for computing
tstart          = tic;

%% LOAD FILES
ERP = load(fullfile(ERP_fld,sprintf('S%02d_meg_lpfreq%d.mat',iS,ERP_lpf_freq))); % single trials mat

REG = load(fullfile(REG_fld,sprintf('S%02d%s',iS,reg_fn_end))); % regressors
MSK = load(fullfile(MSK_fld,sprintf('S%02d%s',iS,msk_fn_end))); % Mask

for iT = 1:length(Cnames)
    
    %% On which task to perform the analysis
    if strcmp('SUB',Cnames{iT})
        iTask = 1;
    elseif strcmp('OBJ',Cnames{iT})
        iTask = 2;
    end
    fprintf('\n Running GLM on task %s \n',Cnames{iT});
    
    %% PREPARE DATA FOR GLM
    
    % SELECT CHANNELS YOU WANT TO USE (SingleTrl have all meg sensors)
    cfg                         = []; 
    cfg.channel                 = which_channels; 
    ERP                         = ft_selectdata(cfg,ERP); 
    
    % Change dimension so to comply with My_glm function 
    trl_filt                    = REG.Task==iTask&MSK.TrlMsk==1; 
    trialMat                    = permute(ERP.trial(trl_filt,:,:),[1,3,2]);
    
    % Prepare regressors according to the condition you chose
    if     strcmp('SUB',Cnames{iT})
        regressors       =      [zscore(REG.ChosenVal(trl_filt)), zscore(REG.UnchosVal(trl_filt)), REG.CHOICE(trl_filt)];
    elseif strcmp('OBJ',Cnames{iT})
        regressors       =      [zscore(REG.ChosenLum(trl_filt)), zscore(REG.UnchosLum(trl_filt)), REG.CHOICE(trl_filt)];
    end
    
    [beta, cst, red]   = My_glm(trialMat,regressors,1);
    
    % Check that there's no NaNs in the results
    if any(isnan(beta(:))) || any(isnan(cst(:))) || any(isnan(red(:)))
        warning('\n SUB%d: NaN is present in GLM in task %s',ss(iS),Cnames{iT});
    end
    
    %% CREATE FT-LIKE STRUCTURE
    BETA             = struct(); 
    BETA.betas       = permute(squeeze(beta),[1,3,2]);
    BETA.cst         = permute(squeeze(cst),[2,1]);
    BETA.residuals   = permute(red,[1,3,2]);
    BETA.TrialsNb    = ERP.TrialNb(trl_filt); 
    BETA             = copyfields(ERP,BETA,{'time','label'}); % function from FieldTrip
    
    % Clear variables 
    beta =[]; cst =[]; red=[]; regressors = []; trialMat =[]; trl_filt = []; 
    
    %% SAVE
    GLM_fn                  = fullfile(save_fld,sprintf('S%02d_GLM7Hunt2013_%s_RESP_%s_lpfreq%d%s',iS,Cnames{iT},which_channels,ERP_lpf_freq,msk_fn_end));
    save(GLM_fn,'-struct','BETA','-v7.3');
    
    
end
% Get finish time & display
tend = toc(tstart);
fprintf('\n The analysis took %1.2f minutes \n',tend/60);

