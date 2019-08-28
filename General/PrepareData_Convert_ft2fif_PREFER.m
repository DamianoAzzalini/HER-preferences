%%%%%%%%%%%%%%
% 
% function PrepareData_Convert_ft2fif_PREFER(cfg_input)
% 
% This function allows to write .mat file used in fieltrip into .fif 
% files to be able to import them in BrainStorm. 
% The function has been modified from PrepareData_Convert_ft2fif.m 
% by Mariana Babo Rebelo. 
%
% DA 2018/02/22
% 
%%%%%%%%%%%%%% 

function PrepareData_Convert_ft2fif_PREFER(cfg_input)

%% Define variables for the functions

subj_list       = cfg_input.subj_list;
task_list       = cfg_input.task_list;
fif_path        = cfg_input.fif_path; 
avg_fif_mrk     = cfg_input.marker_of_interest;
ft_path         = cfg_input.ft_path; 
ft_fn_end       = cfg_input.ft_fn_end; 
output_path     = cfg_input.output_path;
type_data       = cfg_input.type_data;


%% Main loop for file conversion

        
    for iS = subj_list
        
        fprintf('\n Running subject %02d \n',iS);
        
        % Compute template .fif file with average based on marker avg_fif_mrk (new file: S%02d_template.fif)
        fif_input_fn    = fullfile(fif_path,sprintf('S%02d_Block1_hpf_05.fif',iS)); 
        fif_temp_fn     = sprintf('S%02d_template.fif',iS);
        
        % In case of a test on the visual ERP 
        if strcmp(task_list,'avgSTIM')
           fif_temp_fn     = sprintf('S%02d_template_%s.fif',iS,task_list{1});
           system(['dataHandler -r -avg ' fif_input_fn ' -sync ' avg_fif_mrk ' -time -0.2 0.801 -lpf 25 ' fullfile(fif_path,fif_temp_fn) ' -mag -grad']);
        % The true pipeline for HER
        else 
            system(['dataHandler -r -avg ' fif_input_fn ' -sync ' avg_fif_mrk ' -time -0.05 0.401 -lpf 25 ' fullfile(fif_path,fif_temp_fn) ' -mag -grad']);
        end
        
        for itask = 1:length(task_list)
            
            % load fieldtrip structure with avg data
            ft_fn       = fullfile(ft_path,sprintf('S%02d_%s%s.mat',iS,task_list{itask},ft_fn_end)); 
            data_ft_avg = load(ft_fn);
            new_name    = fullfile(output_path,sprintf('S%02d_%s%s.fif',iS,task_list{itask},ft_fn_end)); 
            ft2fif(data_ft_avg, fif_path, fif_temp_fn, type_data, new_name)
            
        end
    end
    
    system(['rm -rf ' fullfile(fif_path,fif_temp_fn)]);
    system(['rm -rf ' fullfile(fif_path,sprintf('S%02d_template.fif_SAVE',iS))]);
    
end







