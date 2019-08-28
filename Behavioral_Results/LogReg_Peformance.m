% LogReg_Peformance.m
%
% The script (previously named GLM_Performance.m) runs a logistic 
% regression on choice data with task-relevant & -irrelevant parameters. 
% Home-made logistic function is used to 
% estimate parameters
%
% DA 2018/10/09
% DA 2019/05/10: Added spread for beta values
% DA 2019/07/24: Polished 

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

% REGRESSOR FOLDER
Reg_fld         = fullfile(root_dir,'Final_Results/GLM_regressors');
Msk_fld         = fullfile(root_dir,'Final_Results/TrialMask');
% SUBJECTS
ss              = [11:13 15:17 19:30 32:34];  % Subjects to include
link_fun        = 'logit'; 

% FIGURE PARAMETERS
regressors_name = {'ChosenSV','UnchosenSV','ChosenCtrs','UnchosenCtrs','Button Press'};
NbReg           = length(regressors_name); 
col_SUB         = [.65 .25 .65]; 
col_OBJ         = [.2 .2 .6]; 
% Keep time for computing
tstart      = tic;
% Initialize variables
SubN                = 0;
BregSub             = NaN(length(ss),NbReg); 
BregObj             = NaN(length(ss),NbReg); 

%% Extract RT & PERF PER SUBJS
for iS = ss
    SubN   = SubN+1;
    fprintf('\n Compute SUBJ %02d',iS);
    % LOAD
    REG    = load(fullfile(Reg_fld,sprintf('S%02d_allTrials.mat',iS)));         % Load the regressors matrix
    MSK    = load(fullfile(Msk_fld,sprintf('S%02d_HER_AvgInTrl.mat',iS)));      % Load mask
    for iTask = 1:2
        % Trials to analyze
        idx                         = [];
        idx                         = find(MSK.TrlMsk==1&REG.Task==iTask);
        % Extract regressors
        regressors                  = [];
        regressors                  = zscore([REG.ChosenVal(idx) REG.UnchosVal(idx) REG.ChosenLum(idx).*-1 REG.UnchosLum(idx).*-1 REG.CHOICE(idx)],[],1);
        b = []; 
        % GLM
        if iTask == 1
            BregSub(SubN,:)         = logreg(regressors,REG.PERF(idx),link_fun);
        elseif iTask == 2
            BregObj(SubN,:)         = logreg(regressors,REG.PERF(idx),link_fun);
        end
        
    end 

end

%% PLOT THE GRANDAVERAGES (BAR PLOTS with distribution spread)
figure('Color','w');
subplot(1,2,1)
Subdat  = BregSub(:); 
catId  = []; 
for iC = 1:size(BregSub,2)
    catId  = [catId; iC*ones(length(ss),1)]; 
end
bar(mean(BregSub,1),'FaceColor',[1 1 1],'BarWidth',0.4); hold on;
errorbar(mean(BregSub,1),std(BregSub,[],1)./sqrt(length(ss)),'LineStyle','none','Color', [0 0 0],'LineWidth',3);
plotSpread(Subdat,'distributionIdx',catId,'distributionColors',[0 0 0]); hold on; 
set(findall(gcf,'type','line','color','k'),'markerSize',30,'color',[.5 .5 .5]) %Change marker size& color%
ylabel('Parameter estimates (a.u.)'); set(gca,'XLim',[0 NbReg+1]);set(gca,'XTick',[1:NbReg]);set(gca,'XTickLabel',regressors_name);
set(gca,'XTickLabelRotation',45); box off; set(gca,'YLim',[-1.5 2]);set(gca,'YTick',[-1.5:.5:2]);

subplot(1,2,2)
Objdat  = BregObj(:); 
bar(mean(BregObj,1),'FaceColor',[1 1 1],'BarWidth',0.4); hold on;
errorbar(mean(BregObj,1),std(BregObj,[],1)./sqrt(length(ss)),'LineStyle','none','Color', [0 0 0],'LineWidth',3);set(gca,'XTick','');
plotSpread(Objdat,'distributionIdx',catId,'distributionColors',[0 0 0]); hold on; 
set(findall(gcf,'type','line','color','k'),'markerSize',30,'color',[.5 .5 .5]) %Change marker size& color%
ylabel('Parameter estimates (a.u.)'); set(gca,'XLim',[0 NbReg+1]);set(gca,'XTick',[1:NbReg]);set(gca,'XTickLabel',regressors_name);
set(gca,'XTickLabelRotation',45);box off; set(gca,'YLim',[-1.5 2]);set(gca,'YTick',[-1.5:.5:2]);
set(findall(gcf,'-property','FontSize'),'FontSize',18);
set(findall(gcf,'-property','TickDir'),'TickDir','out');

%% STATS
fprintf('\n\n PREFERENCE TASK');
for iBeta = 1:NbReg
    fprintf('\n #### T-Test vs. 0 BETA %s ####',regressors_name{iBeta});
    [~,p,~,stat] = ttest(BregSub(:,iBeta));
    fprintf('\n p = %.2e \n',p);
    disp(stat);
end

fprintf('\n ##################################');
fprintf('\n\n\n PERCEPTUAL TASK');
for iBeta = 1:NbReg
    fprintf('\n #### T-Test vs. 0 BETA %s ####',regressors_name{iBeta});
    [~,p,~,stat] = ttest(BregObj(:,iBeta));
     fprintf('\n p = %.2e \n',p);
    disp(stat);
end