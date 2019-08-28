%%% Stats_singleTrial_AvgInTrl.m
%
% Statistical test on HER effect for the AvgInTrl HER.
%
% DA 2018/04/25
% DA 2018/08/01: Added last part to save up the cluster averaged amplitude
%                for HER of SUB and OBJ as well as their difference for further analyses. 
% DA 2019/07/24: Polished
% 
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
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;
%% DATA PATH

HER_path                    = fullfile(root_dir,'Final_Results/HER_Cue/SingleTrl');
ss                          = [11:13 15:17 19:30 32:34];
tasksName                   = {'SUB','OBJ'};
fn_end                      = '_SingleTrl_T_CUE_300_350_TRinterval400_meg_lpfreq25_AvgInTrl.mat';
REG_fld                     = fullfile(root_dir,'Final_Results/GLM_regressors');
reg_end                     = '_allTrials.mat';
% PARAMETERS STATS
stat_channels               = 'megmag';
stat_latency                = [.05 .300];
alpha_1st_level             = 0.05;
minnbchan                   = 3;
if strcmp(stat_channels,'megmag')
    layout                  = 'neuromag306mag.lay';
    template                = 'neuromag306mag_neighb_last.mat';
elseif strcmp(stat_channels,'meggrad')
    layout                  = 'neuromag306cmb.lay';
    template                = 'neuromag306cmb_neighb.mat';
end

SUB                         = cell(length(ss),1);
OBJ                         = cell(length(ss),1);
SubN                        = 0;
nT_Sub                      = NaN(length(ss),1);
nT_Obj                      = NaN(length(ss),1);

% Display some info
fprintf('\n -------------------------------------');
fprintf('\n LOADING SUBS');
fprintf('\n ------------------------------------- \n');
for iS = ss
    SubN                    = SubN + 1;
    fprintf('\n Loading SUBJ %02d',iS);
    HER     = [];
    HER     = load(fullfile(HER_path,sprintf('S%02d%s',iS,fn_end)));
    
    REG     = [];
    REG     = load(fullfile(REG_fld,sprintf('S%02d%s',iS,reg_end)));
    
    Task    = [];
    Task    = REG.Task(HER.TrialNb);
    
    for iTask = 1:length(tasksName)
        if strcmp(tasksName{iTask},'SUB')
            cfg           = [];
            cfg.channel   = stat_channels;
            cfg.trials    = Task==1;
            cfg.removemean       = 'no';
            SUB{SubN,1}   = ft_timelockanalysis(cfg,HER);
            nT_Sub(SubN,1)= sum(Task==1);
            if strcmp(stat_channels,'meggrad')
                cfg           = [];
                cfg.method    = 'sum';
                SUB{SubN,1}   = ft_combineplanar(cfg,SUB{SubN,1});
            end
        elseif strcmp(tasksName{iTask},'OBJ')
            cfg           = [];
            cfg.channel   = stat_channels;
            cfg.trials    = Task==2;
            cfg.removemean       = 'no';
            OBJ{SubN,1}   = ft_timelockanalysis(cfg,HER);
            nT_Obj(SubN,1)= sum(Task==2);
            if strcmp(stat_channels,'meggrad')
                cfg           = [];
                cfg.method    = 'sum';
                OBJ{SubN,1}   = ft_combineplanar(cfg,OBJ{SubN,1});
            end
        end
    end
end
%% HOW MANY TRIALS 
fprintf('\n\n TRIALS N. PER CONDITION '); 
fprintf('\n MEAN N. TRIALS \t SUB = %1.3f \t OBJ = %1.3f',mean(nT_Sub),mean(nT_Obj));
fprintf('\n STD SUB = %1.3f \t OBJ = %1.3f',std(nT_Sub),std(nT_Obj));
fprintf('\n \n'); 
%% Neighbours
cfg = [];
cfg.method                  = 'template'; % 'template';
cfg.template                = template;   % 'neuromag306_neighb.mat' 'neuromag306planar_neighb.mat'
cfg.layout                  = layout;     
cfg.feedback                = 'no';
neighbours                  = ft_prepare_neighbours(cfg, SUB{1});

%% COMPUTE STATS
stat                        =[];
% Display some info
fprintf('\n -------------------------------------');
fprintf('\n COMPUTING STATS');
fprintf('\n ------------------------------------- \n');

% Stats CFG
cfg_stats                   = [];
cfg_stats.parameter         = 'avg';
cfg_stats.channel           = 'all';
cfg_stats.latency           = stat_latency;
% Methods
cfg_stats.method            = 'montecarlo';
cfg_stats.statistic         = 'depsamplesT';
cfg_stats.correctm          = 'cluster';
cfg_stats.clusteralpha      = alpha_1st_level;
cfg_stats.clusterstatistic  = 'maxsum';
cfg_stats.minnbchan         = minnbchan;
cfg_stats.clustertail       = 0;
cfg_stats.numrandomization  = 10000; 
cfg_stats.alpha             = 0.05;
cfg_stats.tail              = 0; % two-sided test
cfg_stats.correcttail       = 'prob';

% Design
subj = length(ss);
design = zeros(2,2*subj);
for i = 1:subj
    design(1,i) = i;
end
for i = 1:subj
    design(1,subj+i) = i;
end
design(2,1:subj)            = 1;
design(2,subj+1:2*subj)     = 2;
cfg_stats.design            = design;
cfg_stats.uvar              = 1;
cfg_stats.ivar              = 2;

cfg_stats.neighbours        = neighbours;
stat                        = ft_timelockstatistics(cfg_stats, SUB{:}, OBJ{:});

%% AVERAGE OVER SUBJECTS SUBJECTIVE & OBJECTIVE (magnetometers)

% Display some info
fprintf('\n -------------------------------------');
fprintf('\n COMPUTING GRANDAVERAGE');
fprintf('\n ------------------------------------- \n');
cfg                         = [];
cfg.channel                 = 'all'; % you have selected them already!
cfg.parameter               = 'avg';
cfg.method                  = 'across';
cfg.keepindividual          = 'yes';
GA_SubCue                   = ft_timelockgrandaverage(cfg,SUB{:});
GA_ObjCue                   = ft_timelockgrandaverage(cfg,OBJ{:});

% DISPLAY RESULTS

cfg                         = [];
cfg.parameter2plot          = 'difference';
cfg.posnegCluster           = 'positive';
cfg.ClusterNb               =  1;
cfg.layout                  = layout;
cfg.LineColors              = {[0.65 0.25 0.65],[ .2 .2 .6]};
cfg.legendNames             = {'Subjective','Objective'};
Plot_cluster(cfg,stat,GA_SubCue,GA_ObjCue);

%% SUBJECT-WISE EFFECT 

save_fld    = fullfile(root_dir,'Final_Results/HER_Cue/SubvsOBJ_Effect'); 
save_fn     = 'SingleSubjs_Effect.mat'; 
% 
msk_effect = stat.posclusterslabelmat==1; 

% Cut the time for GAVG
cfg         = []; 
cfg.latency = [stat.time(1) stat.time(end)];
S           = ft_selectdata(cfg,GA_SubCue); 
O           = ft_selectdata(cfg,GA_ObjCue);

effectHER       = nan(size(S.individual,1),1); 
ClusterHER_Sub  = nan(size(S.individual,1),1);
ClusterHER_Obj  = nan(size(S.individual,1),1);

for ii = 1:size(S.individual,1)
    ClusterHER_Sub(ii,1)  = mean(S.individual(ii,msk_effect)); 
    ClusterHER_Obj(ii,1)  = mean(O.individual(ii,msk_effect));
    effectHER(ii,1) = ClusterHER_Sub(ii,1)-ClusterHER_Obj(ii,1);
end

save(fullfile(save_fld,save_fn),'ClusterHER_Sub','ClusterHER_Obj','effectHER','ss'); 