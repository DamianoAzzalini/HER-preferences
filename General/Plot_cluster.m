function Plot_cluster(cfg_func,stat,data1,data2)
% 
% Plot_cluster(cfg_func,stat,data1,data2)
% INPUTS 
% 
% - cfg_func structure with fields 
%                       parameter2plot
%                       posnegCluster
%                       ClusterNb
%                       layout
%                       LineColors 
%                       legendNames
% - stat            = structure for stats like the one you get from
%                   ft_timelockstatistics
% - data1 & data2: structure entered in the statistical analysis with the
%                  'individuals' field
% DA 2017/11/24: Added semi-transparent patch to timecourse plot to
%                highlight the time of the plotted cluster. 
% DA 2018/03/22: Added LineColors field in cfg file for colors of line in
%                the plot 
% Retrieve cfg_func fields
parameter2plot= cfg_func.parameter2plot;
posnegCluster = cfg_func.posnegCluster;
ClusterNb     = cfg_func.ClusterNb;
layout        = cfg_func.layout;
if isfield(cfg_func,'legendNames')
    legendNames   = cfg_func.legendNames; 
end

% Which sensors and timepoints are significant for cluster 1
if strcmp(posnegCluster,'positive')
    [c,t]               = find(stat.posclusterslabelmat==ClusterNb);
elseif strcmp(posnegCluster,'negative')
    [c,t]               = find(stat.negclusterslabelmat==ClusterNb);
end
cluster_latency        = [stat.time(min(t)) stat.time(max(t))];

% Define what you the user wants to plot 
if strcmp(parameter2plot,'difference')
    % Compute the difference data1 data2
    cfg             = [];
    cfg.operation   = '(x1-x2)';
    cfg.parameter   = 'individual';
    struct2plot     = ft_math(cfg,data1,data2);
    struct2plot.avg = squeeze(mean(struct2plot.individual,1));
elseif strcmp(parameter2plot,'tstat')
    struct2plot = stat;
end

figure('Name','Cluster Topography','Position',[1 1 1500 1000],'Color','w');
% Plot
cfg = [];
if strcmp(parameter2plot,'difference')
    cfg.parameter      = 'avg';
elseif strcmp(parameter2plot,'tstat')
    cfg.parameter      = 'stat';
end
cfg.channel            = 'all';
cfg.layout             = layout;
cfg.xlim               = cluster_latency; % samples of the significant cluster
cfg.markersymbol       = '.'; 
cfg.markersize         = 40; 
cfg.markerfontsize     = 10; 
cfg.highlightchannel   = unique(c);
cfg.highlight          = 'on';
cfg.highlightsymbol    = '.';
cfg.highlightcolor     = [1 1 1];
cfg.highlightsize      = 70;
cfg.colormap           = 'jet';%colormap(flipud(brewermap(64,'RdBu')));
cfg.style              = 'straight'; % 'both'
cfg.zlim               = 'maxabs';%[-3 3]; for paper [-10e-15 +10e-15]; when using difference; % [-0.04 0.04] for beta chosen in paper
cfg.shading            =  'interp' ;
cfg.gridscale          = 500; % This is for making the figure filled neatly with nice resolution (400 to paper-like definition)
% cfg.comment            = 'xlim';
cfg.comment            = 'no';
cfg.commentpos         = 'title';
cfg.colorbar           = 'SouthOutside' ;
ft_topoplotER(cfg,struct2plot);
set(findall(gcf,'-property','FontSize'),'FontSize',21);

% PLOT TIMECOURSE OF THE EFFECT
% figure('Name','Timecourse effect','Position',[1 1 1500 1000]);
% cfg                     = [];
% cfg.channel             = unique(c);
% cfg.layout              = layout;
% cfg.ylim                = 'maxabs';
% cfg.graphcolor          = 'rb';
% ft_singleplotER(cfg,data1,data2);

figure('Name','Timecourse effect','Position',[1 1 1500 1000],'Color','w');
cfg                 = []; 
cfg.channel         = unique(c);
cfg.LineColors      = cfg_func.LineColors; 
if iscell(legendNames)
    cfg.legendNames = legendNames;
end
plot_hdls   = plot_timecourse_channel(cfg,data1,data2);
hold on 
% Plot a rectangle highlighting the latency of the cluster 
ax = gca; 
p = patch([cluster_latency(1) cluster_latency(2) cluster_latency(2) cluster_latency(1)],...
    [min(ax.YLim) min(ax.YLim) max(ax.YLim) max(ax.YLim)],[0.7 0.7 0.7]); 
set(p,'FaceAlpha',0.25);
% set(p,'FaceAlpha',1);

% Plot lines on the significant cluster 
% plot(cluster_latency,repmat(0.02,1,2),'k','LineWidth',3);
set(findall(gcf,'-property','FontSize'),'FontSize',21);

end