function plot_handles = plot_timecourse_channel(cfg,data1,data2)

% plot_timecourse_channel
% The function plots the timecourse of the two datasets
% for some specified channels and latency. 
% Predefined colors for the plot are red (data1) and blue (data2)

% INPUTS
%   cfg         = structure. Either empty (no selection on channel or 
%                 time will be performed) or with fields
%       - channel = Nx1 cell array of strings indicating the channels or
%                  indeces as for ft_selectdata
%       - latency = 2x1 vector indicating the latency to select (as in ft_selectdata)
%                   in seconds. 
%       - legendNames = 1x2 Cell array of strings indicating the legend for
%                       the 2 timecourses plotted. legendNames{1} corresponds at data1, legendNames{2} 
%                       corresponds to data2. If left empty 
%                       legendNames = {'data1','data2'}.
%       - Linecolors    = 2x1 cell with the letters identifying
%                    color in matlab plot or a 2x1 cell with a 3x1 vector
%                    defining color. 
% 
%   data1       = grandaverage structure with field 'individual' (script to adapt when individual field
%                 is not present). 
%   data2       = grandaverage structure with field 'individual' (script to adapt when individual field
%                 is not present). 

% DA 2017/06/27
% DA 2017/07/07 Added cfg.legendNames field to specify legend's names. 
% DA 2018/03/22 Added cfg.color to determine the color of the two curves.
%               cfg.color should be a 2x1 cell with the letters identifying
%               color in matlab plot or a 2x1 cell with a 3x1 vector
%               defining color. 
% Check that data1 and data2 contains the field individual. Otherwise throw
% an error
if ~all(any(strcmp('individual',fieldnames(data1))) && any(strcmp('individual',fieldnames(data2))))
    error('One of the two data input does not contain the field ''individual'' '); 
end

% Figure specs
LineWidth          = 1.5;
LineColors         = cfg.LineColors;
FontSize           = 16; 
if isfield(cfg,'legendNames')
    legendNames    = cfg.legendNames;
elseif ~isfield(cfg,'legendNames')
    legendNames    = {'data1','data2'}; 
end
cfg_select         = [];
% set default if cfg fields are not specified 
if ~any(strcmp('channel',fieldnames(cfg)))
    cfg_select.channel ='all'; 
else
    cfg_select.channel = cfg.channel;
end
if ~any(strcmp('latency',fieldnames(cfg)))
    cfg_select.latency ='all'; 
else
    cfg_select.latency = cfg.latency;
end


if ~isempty(cfg_select)
    data1sel = ft_selectdata(cfg_select,data1);
    data2sel = ft_selectdata(cfg_select,data2);
else 
    data1sel = data1;
    data2sel = data2;
end

% Average over selected channels
data1plot = squeeze(mean(data1sel.individual,2));
data2plot = squeeze(mean(data2sel.individual,2));

% Create plot if there is the field individual
h1 = shadedErrorBar(data1sel.time,mean(data1plot,1),std(data1plot,1)/sqrt(size(data1plot,1)),...
    {'Color',LineColors{1},'LineWidth',LineWidth},0);
hold on;
h2 = shadedErrorBar(data2sel.time,mean(data2plot,1),std(data2plot,1)/sqrt(size(data2plot,1)),...
    {'Color',LineColors{2},'LineWidth',LineWidth},0);
set(findall(gcf,'-property','FontSize'),'FontSize',FontSize);
legend([h1.patch, h2.patch], legendNames);
%set(gca,'XMinorTick','on')
plot_handles = {h1 h2}; 
set(findall(gcf,'-property','TickDir'),'TickDir','out');
set(gcf, 'renderer', 'painters');
set(findall(gcf,'-property','box'),'box','off');
end