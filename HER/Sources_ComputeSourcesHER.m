%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% SR3_ComputeSourcesHER.m
%%%
%%% Computes sources by multiplying MEG raw data (trial by trial) with the
%%% inversion matrix obtained with Brainstorm.
%%%
%%% DA 2019/07/24: Polished
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

%% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));

% SUBJECTS AND PATHS
% ss                  = [11:13 15:17 19:30 32:34];
BS_path             = fullfile(root_dir,'Brainstorm_db/PREFER/data');
% HER last HB
MEG_fld             = fullfile(root_dir,'Final_Results/HER_Cue/GAVG_src/');
invmat_fld          = fullfile(root_dir,'Final_Results/Sources/InversionMatrices');
% End names
MEG_end             = '_AvgInTrl_AvgTime_0.201to0.262.mat'; 
fn_inv_end          = '_mne_constr.mat'; % end of filename
% Task to project
Tasks               = {'SUB','OBJ'};
% GET THE SUBJECTS NUMBER FORM SLURM
strtaskID           = getenv('SLURM_ARRAY_TASK_ID');
iS                  = str2double(strtaskID);
% iS = 24;
fprintf('\n Computing sources SUBJ %02d HER ',iS);
% Load inversion matrix
load(fullfile(invmat_fld,sprintf('S%02d%s',iS,fn_inv_end)));

for iTask = 1:length(Tasks)
    % Load MEG trials only and the true number of trials
    MEG             = load(fullfile(MEG_fld,sprintf('S%02d_meg_%s%s',iS,Tasks{iTask},MEG_end)));
    % Filename in the correct BS folder
    fnBS            = dir(fullfile(BS_path,sprintf('S%02d/HER_Cue_%s_AvgInTrl_avgTime_0.201to0.262/results*',iS,Tasks{iTask}))); 
    % Load BS Structure
    BST             = load(fullfile(BS_path,sprintf('S%02d/HER_Cue_%s_AvgInTrl_avgTime_0.201to0.262/%s',iS,Tasks{iTask},fnBS.name)));
    % Check all the channels are present
    if size(MEG.avg,1)~=306 || isempty(strfind(BST.Comment,Tasks{iTask}))
        error(' You''re not projecting all the channels');
    end
    fprintf('\n Computing sources task %s ',Tasks{iTask});
    BST.ImageGridAmp     = [];
    % Multiply sensor data by inversion matrix
    BST.ImageGridAmp        = invmat * MEG.avg;
    % Change the time vector 
    BST.Time                = MEG.time; 
%     % Check that the time is the same
%     if any(round(BST.Time,3)~=round(MEG.time,3))
%         error(' Time vectors in Sources and Sensors data are different');
%     end
    
    % Save data in BST original folder
    save_fn    = fullfile(BS_path,sprintf('S%02d/HER_Cue_%s_AvgInTrl_avgTime_0.201to0.262/%s',iS,Tasks{iTask},fnBS.name));
    save(save_fn,'-struct','BST','-v7.3');
    
    % Clear the used vars
    MEG =[];
    fnBS = [];
    BST = [];
end

