%%% Compute_stats_surrogate_HER.m
%%% DA 2015/05/16

% FRONTEX
clear
clc
tstart = tic;

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
    iPerm       = 24;
end
fprintf('\n Permutation number: %d \n',iPerm);

% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;

%% PARAMETERS DATA TO LOAD
ss              = [11:13 15:17 19:30 32:34];

which_channels  = 'megmag';
input_fld       = fullfile(root_dir,'Final_Results/HER_Cue/GAVG_SurrogateHER_allBlocks500');

save_fld        = fullfile(root_dir,'Final_Results/HER_Cue/Stats_SurrogateHER_allBlocks500');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

%% PARAMETERS STATS
stat_latency    = [0.05 0.300];
alpha_1st_level = 0.05; % thresholding per tail (default = 0.05)
minnbchan       = 3;

if strcmp(which_channels,'megmag')
    layout          = 'neuromag306mag.lay';
    template        = 'neuromag306mag_neighb_last.mat';
elseif strcmp(which_channels,'meggrad')
    layout          = 'neuromag306cmb.lay';
    template        = 'neuromag306cmb_neighb.mat';
end

input_fn        = sprintf('T_CUE_300_350_TRinterval400_Perm%d_%s_lpfreq25_HER_AvgInTrl.mat',iPerm,which_channels);

%% LOAD SUBJECTS DATA
SubCue          = cell(length(ss),1);
ObjCue          = cell(length(ss),1);
SubN            = 0;
Trl_Sub          = zeros(1,length(ss));
Trl_Obj          = zeros(1,length(ss));

for iS = ss
    
    SubN = SubN + 1;
    % SUBJECTIVE CUE
    sub_fn              = ['S',num2str(iS),'_SubCue_',input_fn];
    SubCue{SubN}        = load(fullfile(input_fld,sub_fn));
    Trl_Sub(SubN)        = SubCue{SubN}.nTrl;
    SubCue{SubN}        = rmfield(SubCue{SubN},{'cfg','nHB','nTrl'});
    % OBJECTIVE CUE
    obj_fn              = ['S',num2str(iS),'_ObjCue_',input_fn];
    ObjCue{SubN}        = load(fullfile(input_fld,obj_fn));
    Trl_Obj(SubN)        = ObjCue{SubN}.nTrl;
    ObjCue{SubN}        = rmfield(ObjCue{SubN},{'cfg','nHB','nTrl'});
    
end

%% PRINT THE NUMBER OF TRIALS PER CONDITION PER SUBJECT AND THEIR AVGs
fprintf('\n -------------------------------------');
fprintf('\n # Heartbeats');
fprintf('\n Subject nr.: %s',mat2str(ss));
fprintf('\n # Heartbeats SUBJECTIVE: %s',mat2str(Trl_Sub));
fprintf('\n Mean # Heartbeats SUBJECTIVE %1.2f',mean(Trl_Sub));
fprintf('\n STD # Heartbeats SUBJECTIVE %1.2f',std(Trl_Sub));
fprintf('\n # Heartbeats OBJECTIVE: %s',mat2str(Trl_Obj));
fprintf('\n Mean # Heartbeats OBJECTIVE %1.2f',mean(Trl_Obj));
fprintf('\n STD # Heartbeats OBJECTIVE %1.2f',std(Trl_Obj));
fprintf('\n ------------------------------------- \n');
% Check that the number of trials are the same in surrogated and real data 
if round(mean(Trl_Sub),3)~=211.095 || round(mean(Trl_Obj),3)~=210.571
    error(' The number of trials in the permutation %d and in the real dataset mismatch',iPerm); 
else
    fprintf('The number of trials in the permutation %d is equal to real dataset',iPerm')
end
%% Prepare neighbours
cfg = [];
cfg.method                  = 'template'; % 'template';
cfg.template                = template;   % 'neuromag306_neighb.mat' 'neuromag306planar_neighb.mat'
cfg.layout                  = layout;     %'neuromag306mag_MAGonly.lay'; % check if correct way of using it
cfg.feedback                = 'no';
neighbours                  = ft_prepare_neighbours(cfg, SubCue{1});


%% COMPUTE STATS
stat =[];
% Display some info
fprintf('\n -------------------------------------');
fprintf('\n COMPUTING STATS');
fprintf('\n ------------------------------------- \n');

% Stats CFG
cfg_stats                   = [];
% cfg_stats.parameter         = 'individual';
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
cfg_stats.numrandomization  = 2;
cfg_stats.alpha             = 0.05;
cfg_stats.tail              = 0; % two-sided test
cfg_stats.correcttail       = 'prob';
cfg_stats.feedback          = 'no'; % avoid messing up in parfor loop
% Design
subj = length(ss);
design = zeros(2,2*subj);
for i = 1:subj
    design(1,i) = i;
end
for i = 1:subj
    design(1,subj+i) = i;
end
design(2,1:subj)        = 1;
design(2,subj+1:2*subj) = 2;
cfg_stats.design            = design;
cfg_stats.uvar              = 1;
cfg_stats.ivar              = 2;

cfg_stats.neighbours        = neighbours;
stat                        = ft_timelockstatistics(cfg_stats, SubCue{:}, ObjCue{:});

%% RETRIEVE LARGEST POSITIVE CLUSTER
% If there are candidate clusters, take the biggest one
if isfield(stat,'posclusters') && ~isempty(stat.posclusters)
    maxSumT = stat.posclusters(1).clusterstat;
    fprintf('\n Permutation %d: maxSumT = %d',iPerm,round(maxSumT));
    % If there are no candidate clusters, maxSumT = -1
elseif ~isfield(stat,'posclusters') || isempty(stat.posclusters)
    maxSumT = -1;
    fprintf('\n Permutation %d: NO candidate clusters',iPerm);
end
% Save maxSumT
save(fullfile(save_fld,sprintf('MaxSumT_Perm%d.mat',iPerm)),'maxSumT');

% Get finish time & display
tend = toc(tstart);
fprintf('\n STATS on Surrogate HER took %1.2f minutes \n',tend/60);
