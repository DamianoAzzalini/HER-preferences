%%% SR1_Compute_HER_Conditions.m
%
% This script computes the averaged (over trials and time) HERs 
% per each subject. 
%
% DA 2018/04/25
% DA 2019/07/24: Polished
%%%
clear
clc

%% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 0;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
end
%% USEFUL PATH
% addpath(fullfile(root_dir,'Final_Scripts/General/'));
% addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;
%% DATA PATH

HER_path                    = fullfile(root_dir,'Final_Results/HER_Cue/SingleTrl');
ss                          = [11:13 15:17 19:30 32:34];
tasksName                   = {'SUB','OBJ'};
fn_end                      = '_SingleTrl_T_CUE_300_350_TRinterval400_meg_lpfreq25_AvgInTrl.mat';
REG_fld                     = fullfile(root_dir,'Final_Results/GLM_regressors');
reg_end                     = '_allTrials.mat';
% SAVE FOLDER
save_fld                    = fullfile(root_dir,'Final_Results/HER_Cue/GAVG_src');
if ~exist(save_fld,'dir'); mkdir(save_fld); end
% PARAMETERS
channels                    = 'meg';

%%%%%%%%%%%%%%% ========== AVERAGE OVER TIME ========== %%%%%%%%%%%%%%%
avgovertime                 = 'yes';
time_win                    = [0.201 0.262];
if strcmp(avgovertime,'yes')
    save_end                    = '_AvgInTrl_AvgTime';
    fprintf('\n');
    warning(' YOU''RE AVERAGING OVER TIME %1.3f - %1.3f',time_win);
elseif strcmp(avgovertime,'no')
    save_end                    = '_AvgInTrl_fullTime';
    fprintf('\n');
    warning(' YOU''RE USING THE WHOLE TRIAL LENGTH');
end
%%%%%%%%%%%%%%% ======================================== %%%%%%%%%%%%%%%

% Display some info
fprintf('\n -------------------------------------');
fprintf('\n LOADING SUBS');
fprintf('\n ------------------------------------- \n');

for iS = ss
    
    fprintf('\n\n Loading SUBJ %02d',iS);
    HER     = [];
    HER     = load(fullfile(HER_path,sprintf('S%02d%s',iS,fn_end)));
    
    REG     = [];
    REG     = load(fullfile(REG_fld,sprintf('S%02d%s',iS,reg_end)));
    
    Task    = [];
    Task    = REG.Task(HER.TrialNb);
    
    for iTask = 1:length(tasksName)
        if strcmp(tasksName{iTask},'SUB')
            SUB             = [];
            
            cfg             = [];
            cfg.channel     = channels;
            cfg.trials      = Task==1;
            cfg.removemean  = 'no';
            SUB             = ft_timelockanalysis(cfg,HER);
            
            % AVG across TIME
            if strcmp(avgovertime,'yes')
                cfg             = [];
                cfg.latency     = time_win;
                cfg.avgovertime = 'yes';
                SUB             = ft_selectdata(cfg,SUB);
            end
            
            % Save the file
            if strcmp(avgovertime,'yes')
                save_fn         = sprintf('S%02d_%s_%s%s_%1.3fto%1.3f.mat',iS,channels,tasksName{iTask},save_end,time_win);
            elseif strcmp(avgovertime,'no')
                save_fn         = sprintf('S%02d_%s_%s%s.mat',iS,channels,tasksName{iTask},save_end);
            end
            fprintf('\n Saving %s',save_fn);
            save(fullfile(save_fld,save_fn),'-struct','SUB','-v7.3');
            
        elseif strcmp(tasksName{iTask},'OBJ')
            OBJ             = [];
            
            cfg             = [];
            cfg.channel     = channels;
            cfg.trials      = Task==2;
            cfg.removemean  = 'no';
            OBJ             = ft_timelockanalysis(cfg,HER);
            if strcmp(avgovertime,'yes')
                % AVG across TIME
                cfg             = [];
                cfg.latency     = time_win;
                cfg.avgovertime = 'yes';
                OBJ             = ft_selectdata(cfg,OBJ);
            end
            % Save the file
            if strcmp(avgovertime,'yes')
                save_fn         = sprintf('S%02d_%s_%s%s_%1.3fto%1.3f.mat',iS,channels,tasksName{iTask},save_end,time_win);
            elseif strcmp(avgovertime,'no')
                save_fn         = sprintf('S%02d_%s_%s%s.mat',iS,channels,tasksName{iTask},save_end);
            end
            fprintf('\n Saving %s',save_fn);
            save(fullfile(save_fld,save_fn),'-struct','OBJ','-v7.3');
        end
    end
end