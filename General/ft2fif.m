%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% function: ft2fif
%%% 
%%% This function transforms .mat data to .fif data.
%%% It uses the dataHandler command -rch to replace the data in a .fif file
%%% by the data from a matlab matrix. To minimize conversion risks, the
%%% .fif file and the matlab matrix should be as close as possible (same
%%% data, both an average...).
%%% This can be useful to convert data obtained with Fieldtrip to a format
%%% that can be read by other softwares (Brainstorm, Muse...). For
%%% instance, ICA corrected data is obtained with Fieldtrip, you can then
%%% transform it to a readable format for other programs.
%%%
%%% Inputs:
%%% - inp_file: name of the matlab structure containing the data to be
%%% converted (has to be loaded beforehand)
%%% - path_def: path for the .fif file, starting after SELFREST/ (example:
%%% 'Avg/s01/Cardio')
%%% - fif_file: name of the .fif file where the mat data will be inserted,
%%% (example: 'MAGGRAD_CardioT_2before_Clean_Sacc2degMax_NoWarnWoI400_Valid
%%% _Perspect_SupMedian_avg.fif')
%%% - type_data: specify the field to be considered in the matlab structure
%%% ('avg', or 'trial')
%%% - new_name: specify the name of the new fif file, with the complete
%%% path (example:
%%% ~/datalinks/SELFREST/GrandAvg/Cardio_ICA/<name_file>.fif)
%%%
%%% Output:
%%% the original .fif file will contain the data from the matlab structure
%%% and a new file (*.fif_SAVE) will be created containing the olf .fif
%%% data (but this is not a valid format, done automatically with 
%%% dataHandler).
%%%
%%% Tip: 
%%% after executing this function, you should modify the name of the .fif
%%% file, so you know the data in it is not the original one (ex: if you 
%%% replace the original data with ICA corrected data). 
%%%
%%% Mariana - May 2014
%%% 
%%% DA 2018/02/22: - added fullfile functions when copying and renaming; 
%%%%               - Added feedback on new created file
%%%%               - Commented lines 94 & 99
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ft2fif(inp_file, path_def, fif_file, type_data, new_name)

data_struct = inp_file;

% Select the .avg or .trial field as a matrix
if strcmp(type_data, 'avg') == 1
    data = data_struct.avg;
elseif strcmp(type_data, 'trial') == 1
    data = data_struct.trial;
    if iscell(data) == 1
        data = cell2mat(data);
    end
end

% Check if the extracted field is truly a matrix
if isnumeric(data) == 0
    error('Could not obtain a matrix from structure... Check selected field.');
end

% Check if we get the correct number of channels in the number of rows of the matrix
if size(data, 1) == 306 || size(data, 1) == 102
else
    error('The matrix does not have the correct number of mags or grads+mags.');
end

% Save temporary .mat file containing the matrix
save('data_tmp.mat', 'data');

% Define path of .fif file
%path_def = ['~/../datalinks/SELFREST/' path_def '/'];

% Copy the template fif file
system(['cp ' fullfile(path_def,fif_file) ' ' fullfile(path_def,sprintf('cp_%s',fif_file))]);

% Execute the -rch command to replace the original fif data with data matrix
system(['dataHandler -rch data_tmp.mat ' fullfile(path_def,fif_file)]);

% Rename the replaced fif file
system(['mv ' fullfile(path_def,fif_file) ' ' new_name]);

% Rename the copied file with the original name
system(['mv ' fullfile(path_def,sprintf('cp_%s',fif_file)) ' ' fullfile(path_def,fif_file)]);

% Feedback
disp(' ');
disp(' ');
disp('**************************');
disp(['Replaced channels in file: ' fif_file]);
disp(['New fif created : ' new_name]);
disp('Old file saved with extension _SAVE');
disp('**************************');

% Remove tmp files
system('rm -rf data_tmp.mat');
% system(['rm -rf ' path_def 'template.fif_SAVE']);

end



