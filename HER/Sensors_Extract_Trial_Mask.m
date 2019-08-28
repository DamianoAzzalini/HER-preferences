% Extract_Trial_Mask.m
% 
% The script creates a logical mask for trials so that 
% the same trials are used in all analyses. 
% 
% DA 2018/05/01
% DA 2019/07/24 Polished
% FRONTEX
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
% USEFUL PATH
addpath(fullfile(root_dir,'Final_Scripts/General/'));
% INPUT FOLDER
input_fld                = fullfile(root_dir,'Final_Results/HER_Cue/SingleTrl');
fn_end                   = '_SingleTrl_T_CUE_300_350_TRinterval400_meg_lpfreq25_AvgInTrl.mat';
% SAVE FOLDER 
save_fld                 = fullfile(root_dir,'Final_Results/TrialMask');
if ~exist(save_fld,'dir'); mkdir(save_fld); end

% SUBJECT LIST 
ss                      = [11:13 15:17 19:30 32:34];
% TOT N of TRIALS
TotNTrials              = 512; 

for iS = ss
    % Feedback
    fprintf('\n Loading SUBJ %02d & computing trial mask',iS); 
    
    % Load HER single trials 
    HER                = load(fullfile(input_fld,sprintf('S%02d%s',iS,fn_end)),'TrialNb'); 
    
    % Check no trials > 512
    if max(HER.TrialNb)>TotNTrials
        error(' Problem with trials selecttion: TrialNb contains trials > %d',TotNTrials); 
    end
    
    % Create Mask
    TrlMsk              = zeros(TotNTrials,1); 
    TrlMsk(HER.TrialNb) = 1; 
    TrlMsk              = logical(TrlMsk); 
    
    % Save results
    save(fullfile(save_fld,sprintf('S%02d_HER_AvgInTrl.mat',iS)),'TrlMsk'); 
end