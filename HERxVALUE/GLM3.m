% GLM3.m
%
% The script performs the control analysis for the specificity that
% interaction between encoding of subjective value and HER is specific to
% neural data locked to heartbeats. 
% GLM3 is similar to GLM2, but uses the averaged activity in anterior
% r-vmPFC to predict neural activity in posterior r-vmPFC (the one encoding
% subjective value). 
% 
% DA 2019/04/15: Added Bayes Factor for betas. 
% DA 2019/07/25: Polished and renamed 
%                (original name was GLM_Ctrl_ClusterHER_CueActivity.m)

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
% FOLDERS
CueFld       = fullfile(root_dir,'Final_Results/Sources/CUE/HER_Cluster/');
HerFld       = fullfile(root_dir,'Final_Results/Sources/HER_cue/HERamp_AvgInTrl_ManualScouts/');
ValFld       = fullfile(root_dir,'Final_Results/Sources/ERP_RESP/GLM_Hunt2013/avgTime_-0.580to-0.197/ChosenVal_ClusterAmp/');
RegFld       = fullfile(root_dir,'Final_Results/GLM_regressors/');
% INITIALIZE VARS
n       = 0;
betas_cue   = nan(length(ss),3);

for iS = ss
    n  = n+1;
    fprintf('\n Subj %02d \n',iS);
    
    % Load data
    CUE     = load(fullfile(CueFld,sprintf('S%02d_TaskSUB_ClusterHER_R_vmPFC_0.300to1.150_noBL.mat',iS)));
    HER     = load(fullfile(HerFld,sprintf('S%02d_HERamp_TaskSUB_R_vmPFC_avg0.201-0.262.mat',iS)));
    VAL     = load(fullfile(ValFld,sprintf('S%02d_SUB_ClusterAmp_scout_R_vmPFC_avgTime_-0.580to-0.197_ChosenVal_smooth6.mat',iS)));
    REG     = load(fullfile(RegFld,sprintf('S%02d_allTrials.mat',iS)));
    
    % Check that exact same trials are present everywhere 
    if any(CUE.TrlsList~=HER.TrlsList) || any(CUE.TrlsList~=VAL.TrlsList) || any(HER.TrlsList~=VAL.TrlsList)
        error('Something is wrong with trials selection');
    end
    
    % Run GLM with CUE mean amplitude
    regs_cue           = [zscore(REG.ChosenVal(CUE.TrlsList)) zscore(CUE.Amp) zscore(REG.ChosenVal(CUE.TrlsList)).*zscore(CUE.Amp)];
    betas_cue(n,:)     = My_glm(VAL.ClusterAmp(VAL.TrlsList),regs_cue,1);
    
    clear regs_cue 
end

%% PLOT

% FIG PARAMS
cueregsname = {'Chosen_S_V','BL vmPFC','BL vmPFC x Chosen_S_V'};

figure('Color','w');
% Plot Betas BL vmPFC
bar(1:3,mean(betas_cue,1),'FaceColor',[.8 .8 .8],'barwidth',.3); hold on;
%errorbar(1:3,mean(betas_cue,1),std(betas_cue,[],1)./sqrt(length(ss)),'LineStyle','none','Color','k','LineWidth',2);
dat = betas_cue(:); 
cat = [ones(length(ss),1);2*ones(length(ss),1); 3*ones(length(ss),1)];  
ah  = plotSpread(dat,'distributionIdx',cat,'distributionColors',[0 0 0]); 
set(findall(gcf,'type','line','color','k'),'markerSize',30,'color',[.5 .5 .5]) %Change marker size& color%
set(gca,'XTick',1:3); set(gca,'XTickLabel',cueregsname);
ylim([-0.2 0.2]); set(gca,'YTick',-.2:0.1:.2);

%ylim([-0.08 0.06]); set(gca,'YTick',-0.08:0.02:0.08);
box off; set(gca,'tickdir','out');

box off; set(gca,'tickdir','out');
set(findall(gcf,'-property','FontSize'),'FontSize',18);

%% STATS BL r-vmPFC 

% Prior: corresponds to an effect differing from 0 with a p-value of 0.05
nobs = length(ss); % number of observations
xref = +0.4554; % reference effect size (should correspond to a significant effect)
tref = xref*sqrt(nobs);
pref = 2*tcdf(-abs(tref),nobs-1);
fprintf('\n\n #### BAYES FACTOR ### \n Reference effect significance p = %1.4f for N = %d ',pref,nobs); % check that pref < 0.05

for iB = 1:length(cueregsname)
    [~,p,~,stat] = ttest(betas_cue(:,iB),0);
    fprintf('\n T-test vs. 0: Beta %s',cueregsname{iB});
    fprintf('\n p=%1.4f \t t=%1.4f',p,stat.tstat);
    
    % BAYES FACTOR against 0
    [~, bf, res_Bayes] = run_ttest_bayes(betas_cue(:,iB),zeros(size(betas_cue(:,iB))), xref);
    fprintf('\n BETA HER- vs. HER+: BF = %1.4f \t %s \n\n',bf,res_Bayes);
    
end

