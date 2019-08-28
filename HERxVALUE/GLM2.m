%%% GLM2.m
%%%
%%% The script computes the GLM on vmpfc chosen value activity ~ ChosenVal + HER + ChosenVal*HER
%%% THis should allow us to test whether vmpfc activity also depends on HER
%%% amplitude, or the only thing modulated by HER is the encoding of the
%%% chosen option.
%%%
%%% DA 2018/08/02
%%%
%%% DA 2019/05/15: Added plotSpread
%%% DA 2019/07/25: Polished and renamed (original name: GLM_Ctrl_HERencoding.m)

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

 addpath(fullfile(root_dir,'Final_Scripts/General/'));

% SUBJECTS
ss                          = [11:13 15:17 19:30 32:34];
Task                        = 'SUB';
% HER SOURCE CLUSTER
HER_cluster_fld             = fullfile(root_dir,'Final_Results/Sources/HER_cue/HERamp_AvgInTrl_ManualScouts');
% VALUE SOURCE CLUSTER
VAL_cluster_fld             = fullfile(root_dir,'Final_Results/Sources/ERP_RESP/GLM_Hunt2013/avgTime_-0.580to-0.197/ChosenVal_ClusterAmp');
% REGRESSORS
REG_fld                     = fullfile(root_dir,'Final_Results/GLM_regressors');
reg_fn_end                  = '_allTrials.mat';
% FIGURE PARAMETERS
regressors_name             = {'Chosen_S_V','HER','HER x Chosen_S_V'};

% INITIALIZE
b                     = zeros(length(ss),length(regressors_name));
n                     = 0;

%% COMPUTE SUBJECT-WISE GLM 

for iS = ss
    
    n = n +1;
    
    fprintf('\n COMPUTING SUBJ %02d \n',iS);
    
    % LOAD HER cluster amplitude
    HER_clus = load(fullfile(HER_cluster_fld,sprintf('S%02d_HERamp_Task%s_R_vmPFC_avg0.201-0.262.mat',iS,Task)));
    % LOAD VALUE cluster amplitude
    VAL_clus = load(fullfile(VAL_cluster_fld,sprintf('S%02d_%s_ClusterAmp_scout_R_vmPFC_avgTime_-0.580to-0.197_ChosenVal_smooth6.mat',iS,Task)));
    % LOAD REGRESSORS
    REG             = load(fullfile(REG_fld,sprintf('S%02d%s',iS,reg_fn_end))); % regressors
    % Check that the same trials are present
    if any(HER_clus.TrlsList~=VAL_clus.TrlsList)
        error(' HER and VAL clusters have not the same trials');
    end
    
    % PREPARE DATA for GLM
    VALamp     = [];
    VALamp     = zscore(VAL_clus.ClusterAmp(VAL_clus.TrlsList));
    
    HERamp     = [];
    HERamp     = HER_clus.HER(VAL_clus.TrlsList);
      
    regressors = [zscore(REG.ChosenVal(VAL_clus.TrlsList)) zscore(HERamp) zscore(REG.ChosenVal(VAL_clus.TrlsList)).*zscore(HERamp)];
    
    % Check that all vectors and masks are the same length
    if size(VALamp,1) ~=  size(regressors,1)
        error( 'Vectors and mask have not the same length');
    end
    
    % RUN GLM2 
    b(n,:)  = My_glm(VALamp,regressors,0);
end

%% CREATE AVERAGE FIGURES
% Bar colors per regressor
BarCol = [.8 .8 .8; 1 .7 0; 1 0 0];
figure('Color','w');
% Plot regressors means
for ii = 1:length(regressors_name)
    h = bar(ii,mean(b(:,ii),1),'FaceColor','w'); hold on; 
    set(h,'FaceColor',BarCol(ii,:));
end
% Plot individual betas with spread plot
dat = b(:); 
cat = [ones(length(ss),1);2*ones(length(ss),1); 3*ones(length(ss),1)];  
ah  = plotSpread(dat,'distributionIdx',cat,'distributionColors',[0 0 0]); 
set(findall(gcf,'type','line','color','k'),'markerSize',30,'color',[.5 .5 .5]) %Change marker size& color
ylabel('Beta (a.u.)'); 
set(gca,'XTick',1:length(regressors_name)); set(gca,'XTickLabel',regressors_name); 
set(gca,'tickdir','out'); set(gca,'box','off');
set(findall(gcf,'-property','FontSize'),'FontSize',21);
%% Print mean beta values 
fprintf('\n Mean +- SEM Beta values: ChosenSV = %1.2f +- %1.2f \t HER = %1.2f +- %1.2f \t Interaction = %1.2f +- %1.2f',...
    mean(b(:,1),1),std(b(:,1))/sqrt(length(ss)),   mean(b(:,2),1),std(b(:,2))/sqrt(length(ss)),    mean(b(:,3),1),std(b(:,3))/sqrt(length(ss))  ); 
%% COMPUTE STATS
fprintf('\n\n T-test Betas vs. 0'); 
for ir = 1:length(regressors_name)
    [~,p,~,stat] = ttest(b(:,ir));
    fprintf('\n Beta %s: t = %1.4f, p = %1.4f',regressors_name{ir},stat.tstat,p); 
end
fprintf('\n')
