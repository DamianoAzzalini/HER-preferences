%%% Create_BS_file.m
%%%
%%% This script copies an existing source file from brainstorm and moves it
%%% in a different folder from which its original  lies
%%%
%%% DA 2018/03/28

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
% 
% addpath('/Users/etudiant/Documents/PREFER/brainstorm3/');
% brainstorm

% File db folder 
db_folderName = 'BetaChosenVal_avgTime_-0.580to-0.197';  
%%%%%%%% ============= CREATE GLM FOLDER (ONLY ONCE)
% create new folder for the betas for all subjects (comment if already done)
db_add_condition('*', db_folderName, [], []);

ss              = [11:13 15:17 19:30 32:34];

Tag_names       = {'ChosenVal'};
which_fns       = 1;
BS_path         =  fullfile(root_dir,'/Brainstorm_db/PREFER/data');
fn_src_end      = 'results_MN_MEG_GRAD_MEG_MAG_KERNEL_180302'; % end of filename

for iS = ss
    
    for iFn = which_fns
        % Get filenames from GLM_Hunt folder (already copied file)
        fn_check          = [];
        fn_check          = dir(fullfile(BS_path,sprintf('S%02d/%s',iS,db_folderName),'results*'));
        
        if isempty(fn_check)
            
            n               = 0;
            sFiles          = [];
            % Get filenames from original files (from SUB HER)
            fn          = [];
            fn          = dir(fullfile(BS_path,sprintf('S%02d/HER_cue_SUB',iS),strcat(fn_src_end,'*')));
            if ~isempty(strfind(fn.name,'results_MN_MEG_GRAD_MEG_MAG_KERNEL'))
                n=n+1;
                orig_fn{1,n} = fullfile(sprintf('S%02d',iS),sprintf('HER_cue_SUB'),fn.name);
                
            end
            
            
            %%%% $$$$$$$$$ Only for first beta create and move BS file
            
            %%% ======= COPY FILE
            % Start a new report
            bst_report('Start', orig_fn);
            
            % Process: Duplicate data files: Add tag with corresponding beta
            sFiles_copy = bst_process('CallProcess', 'process_duplicate', orig_fn, [], ...
                'target', 1, ...  % Duplicate data files
                'tag',    Tag_names{iFn});
            
            % Save and display report
            bst_report('Save', sFiles_copy);
            
            %%% ======= Move the files into GLM folder
            % Input files
            sFiles = {sFiles_copy.FileName};
            SubjectNames = {sFiles_copy.SubjectName};
            
            % Start a new report
            bst_report('Start', sFiles);
            
            % Process: Move files: S12/GLM_Hunt
            sFiles_mv = bst_process('CallProcess', 'process_movefile', sFiles, [], ...
                'subjectname', SubjectNames{1}, ...
                'folder',      db_folderName);
            
            % Save and display report
            bst_report('Save', sFiles_mv);
            
            %%% ======== SET A SENSIBLE COMMENT
            % Input files
            sFiles = {sFiles_mv.FileName};
            
            % Start a new report
            bst_report('Start', sFiles);
            
            % Process: Set comment: Chos-Unch
            sFiles = bst_process('CallProcess', 'process_set_comment', sFiles, [], ...
                'tag',     Tag_names{iFn}, ...
                'isindex', 0);
            
            % Save and display report
            ReportFile = bst_report('Save', sFiles);
            
            %%%% $$$$$$$$$ For all other betas you can use duplicate the first file
        elseif size(fn_check,1) >=1
            
            % If you're at N iteration, use always the first file to be
            % copied
            if size(fn_check,1)>1
                orig_fn{1} = fullfile(sprintf('S%02d/%s',iS,db_folderName),fn_check(1).name);
            else
                orig_fn{1} = fullfile(sprintf('S%02d/%s',iS,db_folderName),fn_check.name);
            end
            %%% ======= COPY FILE
            % Start a new report
            bst_report('Start', orig_fn);
            
            % Process: Duplicate data files: Add tag with corresponding beta
            sFiles_copy = bst_process('CallProcess', 'process_duplicate', orig_fn, [], ...
                'target', 1, ...  % Duplicate data files
                'tag',    Tag_names{iFn});
            
            % Save and display report
            bst_report('Save', sFiles_copy);
            
            %%% ======== SET A SENSIBLE COMMENT
            % Input files
            sFiles = [];
            sFiles = {sFiles_copy.FileName};
            
            % Start a new report
            bst_report('Start', sFiles);
            
            % Process: Set comment: 
            sFiles = bst_process('CallProcess', 'process_set_comment', sFiles, [], ...
                'tag',     Tag_names{iFn}, ...
                'isindex', 0);
            
            % Save and display report
            ReportFile = bst_report('Save', sFiles);
        end
        
    end
    
end
