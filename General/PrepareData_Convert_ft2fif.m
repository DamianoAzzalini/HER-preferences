function PrepareData_Convert_ft2fif(cfg_input)

%% Define variables for script
subj_dates = cfg_input.subj_dates;
subj_list = cfg_input.subj_list;
task_list = cfg_input.task_list;
marker_of_interest = cfg_input.marker_of_interest;
folder_input_data = cfg_input.folder_input_data;
conds = {'_Self', '_Othe'};
type_data = 'avg';

%% Deal with paths
path_Persima


%% Main loop for file conversion
for itask = length(task_list)
    
    if strcmp(task_list{itask}, 'per') == 1
        ntask = 3;
    elseif strcmp(task_list{itask}, 'ima') == 1
        ntask = 4;
    end
        
    for isubj = 1:length(subj_list)
        
        subj = subj_list(isubj);
        disp(['Running subject ' num2str(subj)]);
        
        if subj < 10
            str_subj = '0';
        else
            str_subj = '';
        end
        
        % Compute template .fif file with average (new file: template.fif)
        path_def = [path_persima '/Processed_Data/Avg/' folder_input_data '/'];
        fif_file =  'template.fif';
        system(['dataHandler -r -avg ' path_persima '/Raw/persima' str_subj num2str(subj) '_s' str_subj num2str(subj) '/' num2str(subj_dates(subj)) '/' task_list{itask} '01_trans_tsss.fif -sync ' marker_of_interest '_Self -time -0.1 0.5 -lpf 30 -hpf 0.5 ' path_def '/' fif_file ' -mag -grad']);
        
        
        for icond = 1:length(conds)
            
            % load fieldtrip structure with avg data
            load([path_def '/' task_list{itask} '_' marker_of_interest conds{icond} '_s' num2str(subj) '.mat']);
            new_name = [path_def '/' task_list{itask} '_' marker_of_interest conds{icond} '_s' str_subj num2str(subj) '.fif'];
            ft2fif(data_avg, path_def, fif_file, type_data, new_name)
            
            
        end
    end
    
    system(['rm -rf ' path_def '/' fif_file]);
    
    
end







