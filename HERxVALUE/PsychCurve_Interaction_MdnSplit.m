% PsychCurve_Interaction_MdnSplit.m
% 
% Computes the psychometric functions computed on trials median-split on
% the interacion between HERxVALUE, but also the controls on HER and VALUES
% only. 
%
% It is used to create figures 3C, 3D, 3E 
% 
% DA 2019/07/09
% DA 2019/17/07: Added saving of psychometric parameters in Final_Results/Behavior/PsychCurve/
% DA 2019/07/25: Polished (original script's name: PsychCurve_glmfit_Interaction_MdnSplit_def.m)

clear
clc
close all
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
% SAVE FLD
behavior_fld                = fullfile(root_dir,'Behavior');
blocks                      = 1:8;

% PSYCHCURVE PARAMS
nbin        = 10;     % (only used to plot data)
npsystep    = nbin*4; % How many times finer than the actual data you want the psycurve to be
binsteps    = linspace(1,nbin,nbin); %[min(psysteps):1 1:max(psysteps)];

% FIGURE PARAMETERS
legend_label    = {'HER -','HER +'};
lowrgb          = [0.85 0.44 0.57];
higrgb          = [1 0 0];
    
% INITIALIZE
Betas  = zeros(length(ss),1);
ResLow = zeros(length(ss),1);
ResHig = zeros(length(ss),1);
breglow = zeros(length(ss),2);
breghig = zeros(length(ss),2);
pobslow = nan(length(ss),nbin);
pfitlow = nan(length(ss),npsystep);
semlow  = nan(length(ss),nbin);
ntrllow = nan(length(ss),nbin);
pobshig = nan(length(ss),nbin);
pfithig = nan(length(ss),npsystep);
semhig  = nan(length(ss),nbin);
ntrlhig = nan(length(ss),nbin);
pLow    = nan(length(ss),1); 
pHig    = nan(length(ss),1); 
betas   = nan(length(ss),2); 
bHERhig = nan(length(ss),1); 
bHERlow = nan(length(ss),1); 
bHER    = nan(length(ss),3); 
ovAcc   = nan(length(ss),1); 
AccDiff = nan(length(ss),1); 
n                           = 0;

for iS = ss
    n = n+1;
    fprintf('\n Computing SUB %02d', iS);
    
    % LOAD HER cluster amplitude
    HER_clus = load(fullfile(HER_cluster_fld,sprintf('S%02d_HERamp_Task%s_R_vmPFC_avg0.201-0.262.mat',iS,Task)));
    % LOAD VALUE cluster amplitude
    VAL_clus = load(fullfile(VAL_cluster_fld,sprintf('S%02d_%s_ClusterAmp_scout_R_vmPFC_avgTime_-0.580to-0.197_ChosenVal_Smooth6.mat',iS,Task)));
    % LOAD REGRESSORS
    REG             = load(fullfile(REG_fld,sprintf('S%02d%s',iS,reg_fn_end))); % regressors
    % Check that the same trials are present
    if any(HER_clus.TrlsList~=VAL_clus.TrlsList)
        error(' HER and VAL clusters have not the same trials');
    end
    
    % LOAD BEHAVIOR
    block_behavior = cell(max(blocks),1);
    for iB = blocks
        load(fullfile(behavior_fld,sprintf('S%02d_Block%d.mat',iS,iB))); % single trials mat
        block_behavior{iB}   = Combine_BehavioralMat(stim_matrix,response_matrix);
        stim_matrix = []; response_matrix =[];
    end
    all_behavior = append_behavior_data(block_behavior);
    
    % Arrange Qval to be top 1st column bottom 2nd column
    top_bot_Qval = nan(length(all_behavior.Pairs),2);
    for iP = 1:length(all_behavior.Pairs)
        top_bot_Qval(iP,:) = all_behavior.RawRatings(iP,all_behavior.ScreenPosition(iP,:));
    end
    VD_topbot  = top_bot_Qval(:,1)-top_bot_Qval(:,2);
    resp       = (all_behavior.Response-2)*-1; % Transform so that up is 1 and -1 is down 
    % Arrange behavior
    perf    = resp(HER_clus.TrlsList);
    VD      = zscore(VD_topbot(HER_clus.TrlsList));
    VDbin   = bin_data(VD,nbin);                      
    
    % Choice difficulty
    Q       = REG.VD(HER_clus.TrlsList); 
    
    % Arrange HER
    HERamp  = HER_clus.HER(HER_clus.TrlsList);
    % Arrange vmPFC VAL
    ValAmp  = VAL_clus.ClusterAmp(VAL_clus.TrlsList);
    
    
    %%%%%%%%%%%%%% COMPUTE BETAS FOR HER+ and HER- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Split trials based on HER amplitude
    hermdn  = nan(size(HERamp)); 
    hermdn(HERamp<median(HERamp)) = 1; 
    hermdn(HERamp>=median(HERamp))= 2; 
    % Extract SV
    SV      = zscore(REG.ChosenVal(HER_clus.TrlsList));  
    % Compute GLM separately for HER+ and HER-
    bHERhig(n,1) = My_glm(ValAmp(hermdn==2),SV(hermdn==2),1); 
    bHERlow(n,1) = My_glm(ValAmp(hermdn==1),SV(hermdn==1),1); 
    bHER(n,:)    = My_glm(ValAmp,[SV,zscore(HERamp),SV.*zscore(HERamp)],1); % This is our GLM2
        
    % This will be thing upon which trials are split
    interac = zscore(HERamp.*ValAmp);
    
    % Commented lines are for the other controls run in the paper
    %interac = HERamp;
    %interac  = VALamp; 
    
    % Median split trials
    MDN     = nan(size(interac)); 
    MDN(interac<median(interac))  = 1; 
    MDN(interac>=median(interac)) = 2; 
    
    % Clear
    SV = []; 
    % This is the psychometric curve. Computed separately for each trial
    % type
    for mdn = 1:2
        
        x       = VD(MDN==mdn);
        xplot   = VDbin(MDN==mdn);
        y       = perf(MDN==mdn);
        xmod    = [ones(size(x)),x];
        [b,pf]  = logreg(xmod,y,'logit');
        
        % Fit behavior with logreg (matlab). It gives the same result
        %bmat    = glmfit(xmod,y,'binomial','link','logit','constant','off');
        
        % store parameter estimates
        % 1/ decision criterion (intercept)
        % 2/ decision sensitivity (gain)
        if mdn == 1
            breglow(n,:) = b';
            % group behavior into bins (only for plotting)
            for ibin = 1:nbin
                ifilt = xplot == ibin;
                pobslow(n,ibin) = mean(y(ifilt));
                semlow(n,ibin)  = std(y(ifilt),[],1)./sqrt(sum(ifilt));                
                ntrllow(n,ibin)   = sum(ifilt);
                ifilt = [];
            end
            ps           = linspace(min(x),max(x),npsystep)'; 
            pfitlow(n,:) = 1./(1+exp(-([ones(size(ps)) ps]*breglow(n,:)'))); % Smoother version of psychcurve
            
        elseif mdn==2
            breghig(n,:) = b';
            % group behavior into bins
            for ibin = 1:nbin
                ifilt = xplot == ibin;
                pobshig(n,ibin) = mean(y(ifilt));
                semhig(n,ibin)  = std(y(ifilt),[],1)./sqrt(sum(ifilt));
                ntrlhig(n,ibin)   = sum(ifilt);
                ifilt = [];
            end
            ps           = linspace(min(x),max(x),npsystep)'; 
            pfithig(n,:) = 1./(1+exp(-([ones(size(ps)) ps]*breghig(n,:)'))); % Smoother version of psychcurve
        end
        
        
        clear x y pf b xmod xplot ps
    end
    
    % Plot psychometric curve for each subject to look that everything is
    % good
    if n == 1 || n == 10 || n == 19
        fx = figure('Color','w');
        sp = 0;
    end
    figure(fx);
    sp = sp+1;
    subplot(3,3,sp);
    
    % Smooth Version psychometric curve
    plot(linspace(1,nbin,npsystep),pfitlow(n,:),'Color',lowrgb,'LineWidth',1.5); hold on
    plot(linspace(1,nbin,npsystep),pfithig(n,:),'Color',higrgb,'LineWidth',1.5);
    errorbar(binsteps,pobslow(n,:),semlow(n,:),'LineStyle','none','Marker','o','MarkerSize',4,'Color',lowrgb); 
    errorbar(binsteps,pobshig(n,:),semhig(n,:),'LineStyle','none','Marker','o','MarkerSize',4,'Color',higrgb);
    set(gca,'YLim',[-.2 1.2]);
    title(sprintf('SUBJ %02d',iS));
    set(gca,'tickdir','out'); box off;
    
    % Retrieve accuracy
    acc          = REG.PERF(HER_clus.TrlsList);
    AccDiff(n,1) = mean(acc(Q<median(Q))); 
    
    clear MDN interac VALamp HERamp VD VDbin perf resp VD_topbot all_behavior Q acc
end

%% SAVE THE PARAMETER ESTIMATES 
% save_fn = fullfile(root_dir,'Final_Results/Behavior/PsychCurve/PsychCurve_Parameters_glmfit_Interaction_MdnSplit_def.mat');
% save(save_fn,'breglow','breghig'); 
%% AVG PERFORMANCE + PSYCH CURVE 
figure('Color','w');
subplot(121);

% BEHAVIOR
% 1/  observed
loobavg = mean(pobslow,1);
hiobavg = mean(pobshig,1);
looberr = std(pobslow,[],1)./sqrt(length(ss));
hioberr = std(pobshig,[],1)./sqrt(length(ss));

% 2/  predicted 
lopdavg = mean(pfitlow,1);
hipdavg = mean(pfithig,1);
lopderr = std(pfitlow,[],1)./sqrt(length(ss));
hipderr = std(pfithig,[],1)./sqrt(length(ss));

hold on
xlim([min(binsteps)-.5 max(binsteps)+.5]);
ylim([0,1]);

% Plot fit
plot(linspace(1,nbin,npsystep),lopdavg,'-','Color',lowrgb);
plot(linspace(1,nbin,npsystep),hipdavg,'-','Color',higrgb);

% Plot data SEM
for ibin = 1:nbin
    p1 = plot(binsteps(ibin)*[1,1],loobavg(ibin)+looberr(ibin)*[-1,+1],'Color',lowrgb);
    p2 = plot(binsteps(ibin)*[1,1],hiobavg(ibin)+hioberr(ibin)*[-1,+1],'Color',higrgb);
end
% Plot data mean 
plot(binsteps,loobavg,'ko','MarkerSize',10,'MarkerFaceColor',lowrgb);
plot(binsteps,hiobavg,'ko','MarkerSize',10,'MarkerFaceColor',higrgb);
plot(xlim,[0.5,0.5],'k:');
plot([mean(binsteps) mean(binsteps)],ylim,'k:');
set(gca,'XTick',binsteps); 
set(gca,'XTickLabel',binsteps);
set(gca,'YTick',[0:.2:1]);
box off; 
hold off
set(gca,'Layer','top','TickDir','out');
xlabel('top-bottom');
ylabel('p(top)');
title('');


%%%%%%%%%%%% Parameters estimates %%%%%%%%%%%%
reg_names = {'criterion','slope'};
subplot(122);
bar(1:2:4,mean(breglow),'FaceColor',[.7 .7 .7],'barwidth',.3); hold on;
bar(2:2:4,mean(breghig),'FaceColor',[.7 .7 .7],'barwidth',.3);
errorbar(1:2:4,mean(breglow),std(breglow,[],1)./sqrt(length(ss)),'LineStyle','none','Color','k','LineWidth',1.5);
errorbar(2:2:4,mean(breghig),std(breghig,[],1)./sqrt(length(ss)),'LineStyle','none','Color','k','LineWidth',1.5);

% Plot paired individuals value 
plot([1,3],breglow,'ko','MarkerSize',10,'MarkerFaceColor',lowrgb); 
plot([2,4],breghig,'ko','MarkerSize',10,'MarkerFaceColor',higrgb); 
plot([1.01,1.99],[breglow(:,1) breghig(:,1)],'-','Color',[.4 .4 .4]); 
plot([3.01,3.99],[breglow(:,2) breghig(:,2)],'-','Color',[.4 .4 .4]); 

ylabel('Parameters estimates (a.u.)'); set(gca,'XTick',[1.5 3.5]);
set(gca,'XTickLabel',reg_names); box off; set(gca,'tickdir','out');
suplabel('Median Split based on HER(r-vmPFC) x Chosen_S_V', 't');
legend([p1(1) p2(1)],'Low','High','Location','NW');
set(findall(gcf,'-property','FontSize'),'FontSize',18); 

%% Print stats on screen 
[~,pcrit,~,statcrit] = ttest(breglow(:,1),breghig(:,1)); 
[~,pslop,~,statslop] = ttest(breglow(:,2),breghig(:,2)); 

fprintf('\n\n T-test CRITERION, Median Low vs. Median High,\t p=%1.3f, t=%1.3f, df=%d',pcrit,statcrit.tstat,statcrit.df); 
fprintf('\n T-test SLOPE, Median Low vs. Median High,\t p=%1.3f, t=%1.3f, df=%d \n\n',pslop,statslop.tstat,statslop.df); 

% Bayes factor for criterion & slope
nobs = length(ss); % number of observations
xref = +0.4554; % reference effect size (should correspond to a significant effect)
tref = xref*sqrt(nobs); 
pref = 2*tcdf(-abs(tref),nobs-1); 
fprintf('\n\n #### BAYES FACTOR ### \n Reference effect significance p = %1.4f for N = %d ',pref,nobs); % check that pref < 0.05
[~, bf, res_Bayes] = run_ttest_bayes(breglow(:,1),breghig(:,1), xref);
fprintf('\n CRITERION Median Low vs. Median High: BF = %1.4f \t %s \n\n',bf,res_Bayes); 
[~, bf, res_Bayes] = run_ttest_bayes(breglow(:,2),breghig(:,2), xref);
fprintf('\n SLOPE Median Low vs. Median High: BF = %1.4f \t %s \n\n',bf,res_Bayes); 


%% Correlation Beta interaction with accuracy 
figure('Color','w'); 
% Correl Beta Interaction Accuracy ~ (HERxSV) 
[rIA,sIA] = robustfit(bHER(:,3),AccDiff); % 50% most diff trials to avoid veiling effects
r2IA      = r2Robustfit(bHER(:,3),rIA,sIA); % Estimate R2

scatter(bHER(:,3),AccDiff,10^3,[.6 .6 .6],'.'); hold on; 
plot(bHER(:,3),rIA(1)+rIA(2)*bHER(:,3),'Color','m','LineWidth',2); 
vline(0,':k'); 
xlabel('Interaction (HER x ChosenSV)'); ylabel('Accuracy (most diff)'); 
title(sprintf('Accuracy (most diff) ~ Interaction (HER x ChosenSV) \n p=%1.2f r2=%1.2f',sIA.p(2),r2IA)); 
box off; set(findall(gcf,'-property','tickdir'),'tickdir','out'); 
set(findall(gcf,'-property','FontSize'),'FontSize',18); 

%% Control regression Accuracy ~ Beta HER (from GLM2) 
figure('Color','w'); 

[rHA,sHA] = robustfit(bHER(:,2),AccDiff); % most diff trials only
r2HA      = r2Robustfit(bHER(:,2),rHA,sHA); 

scatter(bHER(:,2),AccDiff,10^3,[.6 .6 .6],'.'); hold on; 
plot(bHER(:,2),rHA(1)+rHA(2)*bHER(:,2),'Color','m','LineWidth',2); 
vline(0,':k'); 
xlabel('Beta HER'); ylabel('Accuracy (most diff)'); 
title(sprintf('Accuracy (most diff) ~ Beta HER \n p=%1.2f r2=%1.2f',sHA.p(2),r2HA)); 
box off; set(findall(gcf,'-property','tickdir'),'tickdir','out'); 
set(findall(gcf,'-property','FontSize'),'FontSize',18); 


%% Control Beta Accuracy ~ Beta ChosenSV (from GLM2) 

figure('Color','w'); 

[rCA,sCA] = robustfit(bHER(:,1),AccDiff); % most diff trials only
r2CA      = r2Robustfit(bHER(:,1),rCA,sCA); 

scatter(bHER(:,1),AccDiff,10^3,[.6 .6 .6],'.'); hold on; 
plot(bHER(:,1),rCA(1)+rCA(2)*bHER(:,1),'Color','m','LineWidth',2); 
vline(0,':k'); 
xlabel('Beta ChosenSV'); ylabel('Accuracy (most diff)'); 
title(sprintf('Accuracy (most diff) ~ Beta ChosenSV \n p=%1.2f r2=%1.2f',sCA.p(2),r2CA)); 
box off; set(findall(gcf,'-property','tickdir'),'tickdir','out'); 
set(findall(gcf,'-property','FontSize'),'FontSize',18); 
