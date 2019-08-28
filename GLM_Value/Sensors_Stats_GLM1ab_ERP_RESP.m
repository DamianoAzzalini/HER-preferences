% Stats_GLM1ab_ERP_RESP.m
% This script can be used to test for significance of betas for
% all the GLMs computed on response-locked ERP.
%
% DA 2017/10/20
% DA 2017/11/14: Changed to accomodate multiple betas (DELTAQ, RT, and Trial Number)
% DA 2017/11/16: Added if statement to take the only beta estimate if no
%                others are computed
% DA 2018/02/14: Cleaned the code
% DA 2018/03/22: Added Task name as parameter
% DA 2019/07/24: Script's name has been changed to comply with the GLM name in the main
%                text (Previously called Stats_GLMHunt2013_ERP_RESP.m)

%% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 0;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
end
% Keep time for computing
tstart          = tic;
%% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
addpath(fullfile(root_dir,'Toolboxes/fieldtrip-20170705/')); ft_defaults;

%% PARAMS
ss                      = [11:13 15:17 19:30 32:34];  % Subjects to include
beta_names              = {'ChosenVal'}; % UnchosenVal or %Choice
alphaP                  = 0.05;
nbNeigh                 = 3;

% WHICH ON WHICH TASK 
Task                    = 'SUB';

% CHANNEL SELECTION
which_channels          = 'megmag';             % 'megmag' 'meggrad'
if strcmp(which_channels,'megmag')
    layout          = 'neuromag306mag.lay';
    template        = 'neuromag306mag_neighb_last.mat';
elseif strcmp(which_channels,'meggrad')
    layout          = 'neuromag306cmb.lay';
    template        = 'neuromag306cmb_neighb.mat';
end

% WHICH LP FILTER ON ERP 
lpfreq              = 25; 

% WHICH GLM TO TEST 
input_fld           = fullfile(root_dir,'Final_Results/GLM_sensors/GLM7Hunt2013_RESP');
input_fn            = sprintf('_GLM7Hunt2013_%s_RESP_%s_lpfreq%d_HER_AvgInTrl.mat',Task,which_channels,lpfreq);
output_fld          = input_fld; 

for iBeta = 1:length(beta_names)
    BETA            = cell(length(ss),1);
    ZEROS           = cell(length(ss),1);
    SubN            = 0;
    %% LOAD REAL GLM DATA
    for iS = ss
        fprintf('\n Loading SUBJ %02d \n',iS);
        SubN           = SubN+1;
        x = load(fullfile(input_fld,sprintf('S%02d%s',iS,input_fn)),'betas','label','time');
        % Compute the difference of Chosen - Unchosen at the beta level 
        if strcmp(beta_names(iBeta),'ChosVal-UnchVal')
            BETA{SubN}.avg    = squeeze(x.betas(1,:,:)) - squeeze(x.betas(2,:,:));
        elseif strcmp(beta_names(iBeta),'ChosenVal+UnchosenVal')
            BETA{SubN}.avg    = squeeze(x.betas(1,:,:)) + squeeze(x.betas(2,:,:));
        elseif strcmp(beta_names(iBeta),'ChosenVal')
            BETA{SubN}.avg    = squeeze(x.betas(1,:,:));
        elseif strcmp(beta_names(iBeta),'UnchosenVal')
            BETA{SubN}.avg    = squeeze(x.betas(2,:,:));
        % Otherwise is Choice beta vs. 0 
        elseif strcmp(beta_names(iBeta),'Choice')
            BETA{SubN}.avg    = squeeze(x.betas(3,:,:)); 
        elseif strcmp(beta_names(iBeta),'RT')
            BETA{SubN}.avg    = squeeze(x.betas(4,:,:)); 
        end
        BETA{SubN}.time     = x.time;
        BETA{SubN}.label    = x.label;
        BETA{SubN}.dimord   = 'chan_time';
        
        % TESTING AGAINST ZEROS
        ZEROS{SubN}.avg     = zeros(size(BETA{SubN}.avg));
        ZEROS{SubN}.time    = x.time;
        ZEROS{SubN}.label   = x.label;
        ZEROS{SubN}.dimord  = 'chan_time';
    end
    
    %% STATS
    
    % Prepare neighbours
    cfg = [];
    cfg.method                  = 'template'; % 'template';
    cfg.template                = template;   % 'neuromag306_neighb.mat' 'neuromag306planar_neighb.mat'
    cfg.layout                  = layout;     %'neuromag306mag_MAGonly.lay'; % check if correct way of using it
    cfg.feedback                = 'no';
    neighbours                  = ft_prepare_neighbours(cfg, BETA{1});
    
    for iA  = 1:length(alphaP)
        for iNbN = 1:length(nbNeigh)
            
            % PRINT SOME INFO
            fprintf('\n ##########################');
            fprintf('\n Computing stats for beta: %s',beta_names{iBeta});
            fprintf('\n 1st level alpha: %1.4f',alphaP(iA));
            fprintf('\n Nb Neighbours:   %1.4f',nbNeigh(iNbN));
            fprintf('\n ##########################');
            
            % CFG STATS 
            cfg_stats                   = [];
            cfg_stats.latency           = [-1 0];
            cfg_stats.clusteralpha      = alphaP(iA);
            cfg_stats.minnbchan         = nbNeigh(iNbN);
            % Methods
            cfg_stats.method            = 'montecarlo';
            cfg_stats.statistic         = 'ft_statfun_depsamplesT';
            cfg_stats.correctm          = 'cluster';
            cfg_stats.channel           = 'all';
            cfg_stats.clusterstatistic  = 'maxsum';
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
            design(2,1:subj)        = 1;
            design(2,subj+1:2*subj) = 2;
            cfg_stats.design            = design;
            cfg_stats.uvar              = 1;
            cfg_stats.ivar              = 2;
            
            cfg_stats.neighbours        = neighbours;
            
            % TESTING AGAINST ZEROS
            stat_sub                    = ft_timelockstatistics(cfg_stats, BETA{:}, ZEROS{:});
            
            %% GRANDAVERAGES
            if iA == 1
                cfg = [];
                cfg.parameter = 'avg';
                cfg.keepindividual = 'yes';
                GA_SUB = ft_timelockgrandaverage(cfg,BETA{:});
                
                % GAVG zero matrix
                GA_ZERO_SUB = ft_timelockgrandaverage(cfg,ZEROS{:});
                save(fullfile(output_fld,sprintf('BETA_%s_%s_%s_p%1.4f_nbchan%d_latency%1.1fto%1.1f_lpfreq%d_HER_AvgInTrl.mat',...
                    Task,which_channels,beta_names{iBeta},cfg_stats.clusteralpha,cfg_stats.minnbchan,...
                    cfg_stats.latency(1),cfg_stats.latency(2),lpfreq)),...
                    'stat_sub','GA_SUB','GA_ZERO_SUB');
                stat_sub  = [];
            end
        end
    end
end

%% CREATE CLUSTER MASK 
ERP_clusterMask = [];
x = zeros(size(stat_sub.negclusterslabelmat));
x(stat_sub.negclusterslabelmat==1) = 1;
ERP_clusterMask = x;
