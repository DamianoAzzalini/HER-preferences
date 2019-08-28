% Plot_Clusters_GLM_stats.m 
% 
% This script just allows the user to manually load some stats and
% grandaverages and to plot the cluster, parameter specified in the cfg
% The script has been used to plot figures 2D,2E. 
% 
% DA 2017/10/20
% 
% DA 2018/08/17: Added the plot of the two clusters together for paper
% DA 2019/07/24: Polished

% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 0;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
end
addpath(fullfile(root_dir,'Final_Scripts/General')); 
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705')); ft_defaults

layout             = 'neuromag306mag.lay'; 

% Plot topography and timecourse of the two negative cluster chosen val together
statcmb             = []; 
statcmb.time        = stat_sub.time; 
statcmb.stat        = stat_sub.stat; 

% Two neg clusters as one in new structure
statcmb.negclusterslabelmat = zeros(size(stat_sub.negclusterslabelmat)); 
statcmb.negclusterslabelmat(stat_sub.negclusterslabelmat==1 | stat_sub.negclusterslabelmat==2) = 1;  


cfg = []; 
cfg.parameter2plot = 'difference'; 
cfg.posnegCluster  = 'negative'; 
cfg.ClusterNb      = 1; 
cfg.layout         = layout; 
cfg.legendNames    = {'Beta Chosen','Beta Zero'};  
cfg.LineColors     = {'r','k'};
Plot_cluster(cfg,statcmb,GA_SUB,GA_ZERO_SUB);

% Plot Beta for Button Press
cfg = []; 
cfg.parameter2plot = 'tstat'; 
cfg.posnegCluster  = 'positive'; 
cfg.ClusterNb      =  1; 
cfg.layout         = layout; 
cfg.legendNames    = {'Beta Choice','Beta Zero'};  
Plot_cluster(cfg,stat_obj,GA_SUB,GA_ZERO_OBJ);

cfg.posnegCluster  = 'negative'; 
Plot_cluster(cfg,stat_obj,GA_SUB,GA_ZERO_OBJ);

