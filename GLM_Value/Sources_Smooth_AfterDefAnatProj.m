%%% S05_Smooth_AfterProject.m
%%%
%%% 
%%% The script smooths the original file projected on default anatomy 
%%% with the gaussian kernel FWHM. 
%%%
%%% DA 2018/04/09
%%% DA 2019/07/24: Note that this code is used to smooth all the betas of 
%%%				   interest at the source level, therefore BS_folder should 
%%%			 	   changed accordingly, as well as 'timewindow' and 'BetaName'. 

% Script generated by Brainstorm (20-Feb-2018)
clear
clc

% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 0;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
end

% addpath('/Users/etudiant/Documents/PREFER/brainstorm3/');
% brainstorm

%%%%%%%%%%%%%%%%%%%%%%% DEFINE PARAMETERS SMOOOTHING %%%%%%%%%%%%%%%%%%%%%%%
BS_folder       = 'BetaChosenLum_avgTime_-0.257to-0.025';
BS_path         =  fullfile(root_dir,'/Brainstorm_db/PREFER/data/Group_analysis');

BetaName        = 'ChosenLum';
timewindow      = [-0.257  -0.025];
KernelSize      = 6; 
ss              = [11:13 15:17 19:30 32:34]; 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%% ============= SMOOTHING ========== %%%%%%%%%%%%%%%%%%

fileList        = dir(fullfile(BS_path,BS_folder,'*.mat')); 

sFiles          = cell(length(ss),1); 
n               = 0 ; 

for iFiles = 1:size(fileList,1)
    if isempty(strfind(fileList(iFiles).name,'ssmooth')) && ~isempty(strfind(fileList(iFiles).name,'results')) %&& ~isempty(strfind(fileList(iFiles).name,BetaName))
        n       = n+1; 
        sFiles{n} = fullfile('Group_analysis',BS_folder,fileList(iFiles).name); 
    end
end

% Start a new report
bst_report('Start', sFiles);

% Process: Spatial smoothing (8.00)
sFiles = bst_process('CallProcess', 'process_ssmooth_surfstat', sFiles, [], ...
    'fwhm',       KernelSize, ...
    'overwrite',  0, ...
    'source_abs', 0);

%%%%%%%%%%%%%%%%%% ================================ %%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%% ============= T-TEST vs. 0 ========== %%%%%%%%%%%%%%%%%%

% % Process: t-test zero          H0:(X=0), H1:(X<>0)
% sFiles = bst_process('CallProcess', 'process_test_parametric1', sFiles, [], ...
%     'timewindow',    timewindow, ...
%     'scoutsel',      {}, ...
%     'scoutfunc',     1, ...  % Mean
%     'isnorm',        0, ...
%     'avgtime',       0, ...
%     'Comment',       sprintf('Ttest0_%s_Smoothing%dAfterDefAnatProj',BetaName,KerneSize), ...
%     'test_type',     'ttest_onesample', ...  % One-sample Student's t-test    X~N(m,s)t = mean(X) ./ std(X) .* sqrt(n)      df=n-1
%     'tail',          'two');  % Two-tailed
% 
% % Save and display report
% ReportFile = bst_report('Save', sFiles);
% bst_report('Open', ReportFile);
% % bst_report('Export', ReportFile, ExportDir);
%%%%%%%%%%%%%%%%%% ================================ %%%%%%%%%%%%%%%%%%
