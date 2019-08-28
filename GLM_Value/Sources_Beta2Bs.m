%%% S03_Beta2Bs.m
%%%
%%% This script create a single brainstorm file for each beta and subject
%%% in a new folder in the BS database
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


ss              = [11:13 15:17 19:30 32:34];                 % Subjects list
time_src        = [-0.580 -0.197];                          % The whole time of the GLM
Task            = 'SUB';
time_def        = 'avgTime';
% Paths
BS_path         = fullfile(root_dir,'/Brainstorm_db/PREFER/data');
BS_GLM_fld      = sprintf('BetaChosenVal_%s_%1.3fto%1.3f',time_def,time_src);
GLM_src         = fullfile(root_dir,sprintf('Final_Results/Sources/ERP_RESP/GLM_Hunt2013/%s_%1.3fto%1.3f/Data',time_def,time_src));
which_beta      = 1;
Beta_names      = {'ChosenVal'};

for iS = ss
    
    % Load GLM sources
    Beta        = [];
    fn2load     = sprintf('S%02d_%s%1.3fto%1.3f_Task%s_IndivAnat.mat',iS,time_def,time_src,Task);
%     fn2load     = sprintf('S%02d_avgsrc.mat',iS);
    load(fullfile(GLM_src,fn2load));
    
    % Print info
    fprintf('\n %s',fn2load);
    
    % Get filenames from GLM_Hunt folder (already copied file)
    fn          = [];
    fn          = dir(fullfile(BS_path,sprintf('S%02d/%s',iS,BS_GLM_fld),'results*'));
    % Create new file for each Beta
    for ibeta = which_beta
        
        BS      = [];
        
                % % Select appropriate BS file for current beta
                % if strcmp(Beta_names{ibeta},'Chos-Unch')
                %     for ifiles = 1:size(fn,1)
                %         if isempty(strfind(fn(ifiles).name,'Choice')) && isempty(strfind(fn(ifiles).name,'Chosen')) && isempty(strfind(fn(ifiles).name,'Unchosen'))
                %             BS = load(fullfile(BS_path,sprintf('S%02d/%s',iS,BS_GLM_fld),fn(ifiles).name));
                %             break
                %         end
                %     end
                % else
                %     for ifiles = 1:size(fn,1)
                %         if ~isempty(strfind(fn(ifiles).name,Beta_names{ibeta}))
                %             BS = load(fullfile(BS_path,sprintf('S%02d/%s',iS,BS_GLM_fld),fn(ifiles).name));
                %             break
                %         end
                %     end
                % end
        
        % ONLY CHOSEN BETA, THEREFORE 1 FILE ONLY IN THE FOLDER NO NEED FOR IF
        % STATEMENT
        BS = load(fullfile(BS_path,sprintf('S%02d/%s',iS,BS_GLM_fld),fn.name));
        
        % Feedback on the screen when you're sustituting multiple files
        %         fprintf('\n Remplacing BS data %s with beta %s',fn(ifiles).name,Beta_names{ibeta});
        
        % Feedback on the screen when you're sustituting 1 file only
        fprintf('\n Remplacing BS data %s with beta %s',fn.name,Beta_names{ibeta});
        
        % Replace data with beta
        BS.ImageGridAmp = [];
        
        % When you have one timepoint only
        if strcmp(Beta_names{ibeta},'Chos-Unch')
            BS.ImageGridAmp = squeeze(Beta(1,:,:) - Beta(2,:,:))';
        elseif strcmp(Beta_names{ibeta},'ChosenVal')
%             fprintf('\n');
%             warning(' This is an ad-hoc modification. Check if still valid. \n Size of the Beta matrix is %d %d; you''re using all of it',size(Beta)); 
%             BS.ImageGridAmp = Beta;
             BS.ImageGridAmp = squeeze(Beta(1,:,:))';
        elseif strcmp(Beta_names{ibeta},'UnchosenVal')
            BS.ImageGridAmp = squeeze(Beta(2,:,:))';
        elseif strcmp(Beta_names{ibeta},'Choice')
            BS.ImageGridAmp = squeeze(Beta(3,:,:))';
        end

        %This was for checking if is the same activity for the 2 GLMS
%         BS.ImageGridAmp = src_mat;
        
        % Modify time according to GLM
        if strcmp(time_def,'fullTime')
            BS.Time         = time_src(1):0.001:time_src(2);
        elseif strcmp(time_def,'avgTime')
            BS.Time         = mean(time_src);
        end
        
        % Save the modified file when you're sustituting multiple files
        %         save(fullfile(BS_path,sprintf('S%02d/%s',iS,BS_GLM_fld),fn(ifiles).name),'-struct','BS','-v7.3');
        
        % Save the modified file when you're sustituting 1 single file
        save(fullfile(BS_path,sprintf('S%02d/%s',iS,BS_GLM_fld),fn.name),'-struct','BS','-v7.3');
        
    end
end