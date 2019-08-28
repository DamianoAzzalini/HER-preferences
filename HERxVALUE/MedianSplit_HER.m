%%% MedianSplit_HER.m
%%%
%%% The script runs a regression - separately for HER- and HER+ trials - 
%%% on ROI identified from GLM1a or GLM1b. 
%%% 
%%%
%%% DA 2018/03/21
%%%
%%% DA 2018/02/23: Added selection of regressors depending on the task
%%%
%%% DA 2018/10/10: Modified to use the manually selected HER ROI as signal
%%%                upon which to compute the median split. 
%%% DA 2018/10/30: Added Bayes Factor for contrast HER- vs. HER+ 
%%%
%%% DA 2019/05/10: Added line-dots individual points on top of the bars or
%%%                spreadPlot. 
%%% DA 2019/07/25: It creates figure 3A and 3B. It is adapted for all median splits
%%%                run in the main text (i.e. preference & perceptual trials
%%%                with all possible combinations of HER ROIs and ROIs encoding some task
%%%                -relevant variable). Paths, Task ROI names, HER ROI names, predictors
%%%                should be changed accordingly. 
%%%                Renamed (original name was GLM_ValueSrc_HERSrc.m)

clear
clc
%close all
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
regressors_name             = {'ChosenSV'};
legend_label                = {'HER -','HER +'};
% PLOT COLORS
if strcmp(Task,'SUB')
    Color_HERlow                = [1 1 0];
    Color_HERhigh               = [1 .5 0];
elseif strcmp(Task,'OBJ')
    Color_HERlow                = [1  0 1];
    Color_HERhigh               = [.5 0 1];
end

% INITIALIZE
BetaLow                     = zeros(length(ss),length(regressors_name));
Beta                        = zeros(length(ss),length(regressors_name));
BetaHig                     = zeros(length(ss),length(regressors_name));
n                           = 0;
mL0                         = 0; 
mS0                         = 0; 

%% COMPUTE SUBJECT-WISE GLM 

for iS = ss
    
    n = n +1;
    
    fprintf('\n COMPUTING SUBJ %02d \n',iS);
    
    % LOAD HER cluster amplitude
    HER_clus = load(fullfile(HER_cluster_fld,sprintf('S%02d_HERamp_Task%s_R_vmPFC_avg0.201-0.262.mat',iS,Task)));
    % LOAD VALUE cluster amplitude
    ROI_clus = load(fullfile(VAL_cluster_fld,sprintf('S%02d_%s_ClusterAmp_scout_R_vmPFC_avgTime_-0.580to-0.197_ChosenVal_Smooth6.mat',iS,Task)));
    % LOAD REGRESSORS
    REG             = load(fullfile(REG_fld,sprintf('S%02d%s',iS,reg_fn_end))); % regressors
    
    % Check that the same trials are present
    if any(HER_clus.TrlsList~=ROI_clus.TrlsList)
        error(' HER and VAL clusters have not the same trials');
    end
    
    % PREPARE DATA for GLM
    VALamp                    = [];
    VALamp                    = ROI_clus.ClusterAmp(ROI_clus.TrlsList);
    VALamp                    = zscore(VALamp);
    
    HERamp                    = [];
    HERamp                    = HER_clus.HER(ROI_clus.TrlsList);
    HERmdn                    = NaN(size(HERamp));

    % Median split 
    HERmdn(HERamp<median(HERamp))   = 1;
    HERmdn(HERamp>=median(HERamp))  = 2;
    
    % Select regressors depending on the task
    if strcmp(Task,'SUB')
        regressors       = [zscore(REG.ChosenVal(ROI_clus.TrlsList))];
        
    elseif strcmp(Task,'OBJ')
        regressors       = [zscore(REG.ChosenLum(ROI_clus.TrlsList))];
    end
    
    % Check that all vectors and masks are the same length
    if any([size(VALamp,1) size(HERmdn,1) size(regressors,1)] ~= size(HERamp,1))
        error( 'Vectors and mask have not the same length');
    end
    
    % RUN GLM
    BetaLow(n,:)  = My_glm(VALamp(HERmdn==1),regressors(HERmdn==1,:),0);
    BetaHig(n,:)  = My_glm(VALamp(HERmdn==2),regressors(HERmdn==2,:),0);
    
    % GLM (not median-split) Just a check that we find value to be encoded there
    Beta(n,:)                   = My_glm(VALamp,regressors,0);
    if Frontex == 0
        if n == 1
            figure('Color','w');
        end
        subplot(5,5,n);
        % WHEN USING ONE REGRESSOR
        bar(1,BetaLow(n,:),'FaceColor',Color_HERlow); hold on
        bar(2,BetaHig(n,:),'FaceColor',Color_HERhigh);
        set(gca,'XLim',[0 size(BetaLow,2)+2]); set(gca,'XTickLabel',''); xlabel(regressors_name);
        title(sprintf('SUBJ %02d',iS));
        if n == 1
            legend(legend_label,'Location','NorthWest');
        end
    end
end


set(findall(gcf,'-property','FontSize'),'FontSize',18);

%% CREATE AVERAGE FIGURES

% FIGURE BETA
figure('Color','w');   
bar(1,mean(BetaLow,1),'FaceColor',Color_HERlow,'BarWidth',0.4); hold on;
bar(2,mean(BetaHig,1),'FaceColor',Color_HERhigh,'BarWidth',0.4);
errorbar(1,mean(BetaLow,1),std(BetaLow,[],1)./sqrt(length(ss)),'LineStyle','none','Color', [0 0 0],'LineWidth',3);
errorbar(2,mean(BetaHig,1),std(BetaHig,[],1)./sqrt(length(ss)),'LineStyle','none','Color', [0 0 0],'LineWidth',3);

% DOT-LINES
plot(1,BetaLow,'ko','MarkerSize',10,'MarkerFaceColor',Color_HERlow); 
plot(2,BetaHig,'ko','MarkerSize',10,'MarkerFaceColor',Color_HERhigh); 
plot([1.01,1.99],[BetaLow BetaHig],'-','Color',[.4 .4 .4]); 

set(gca,'XTick',''); 
set(gca,'YLim',[-.4 .2]);
xlabel(regressors_name); set(gca,'XLim',[0.5 2.5]);
ylabel('Beta (a.u.)');
set(findall(gcf,'-property','FontSize'),'FontSize',21); set(gca,'TickDir','out'); 
box off; 
legend(legend_label);


% FIGURE BETA (not median-split), sanity check to find value encoding
figure('Color','w'); 
bar(1,mean(Beta,1),'FaceColor',[.7 .7 .7],'BarWidth',0.4); hold on;
errorbar(1,mean(Beta,1),std(Beta,[],1)./sqrt(length(ss)),'LineStyle','none','Color', [0 0 0],'LineWidth',3);
[~,pall,~,statall] = ttest(Beta);
title(sprintf('Beta (no median split) vs. 0 \n p = %1.3f t = %1.3f',pall,statall.tstat)); 
set(findall(gcf,'-property','FontSize'),'FontSize',18);


%% RUN STATS 

% STATS HER LOW
fprintf('\n\n ########## HER LOW ########## ');
for iB = 1:size(BetaLow,2)
    [~,p,~,stat] = ttest(BetaLow(:,iB));
    fprintf('\n \t %s - vs. 0',regressors_name{iB});
    fprintf('\n p = %1.4f \n',p);
    disp(stat);
end

% STATS HER HIGH
fprintf('\n\n ########## HER HIGH ########## ');
for iB = 1:size(BetaHig,2)
    [~,p,~,stat] = ttest(BetaHig(:,iB));
    fprintf('\n \t %s - vs. 0',regressors_name{iB});
    fprintf('\n p = %1.4f \n',p);
    disp(stat);
end

% STATS HER LOW vs. HIGH
fprintf('\n\n ########## HER LOW vs HIGH  ########## ');
for iB = 1:size(BetaHig,2)
    [~,p,~,stat] = ttest(BetaLow(:,iB),BetaHig(:,iB));
    fprintf('\n \t %s - Low vs. High',regressors_name{iB});
    fprintf('\n p = %1.4f \n',p);
    disp(stat);
end

%%  BAYES FACTOR
% Prior: corresponds to an effect differing from 0 with a p-value of 0.05
nobs = length(ss); % number of observations
xref = +0.4554; % reference effect size (should correspond to a significant effect)
tref = xref*sqrt(nobs); 
pref = 2*tcdf(-abs(tref),nobs-1); 
fprintf('\n\n #### BAYES FACTOR ### \n Reference effect significance p = %1.4f for N = %d ',pref,nobs); % check that pref < 0.05
[~, bf, res_Bayes] = run_ttest_bayes(BetaHig, BetaLow, xref);
fprintf('\n BETA HER- vs. HER+: BF = %1.4f \t %s \n\n',bf,res_Bayes); 
