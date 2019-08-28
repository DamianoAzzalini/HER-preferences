% Real_HER_vs_Surrogate.m
% 
% The script plots the histogram of T-sum computed on 
% surrogated HER statistics and the real T-sum. 
% It prints on the screen the number of times surrogate clusters
% are >= the real one and their proportion given the number of 
% permutations
% 
% DA 2017/10/17

%% FRONTEX OR LOCAL
%%%%%%%%%%%%%%%%%%%
Frontex = 0;
%%%%%%%%%%%%%%%%%%%
if Frontex == 1 % On frontex
    root_dir = '/shared/projects/project_prefer';
elseif Frontex == 0 % On local machine
    root_dir = '/Volumes/PREFER';
end

input_fld = fullfile(root_dir,'Final_Results/HER_Cue/Stats_SurrogateHER_allBlocks500');

nPermutations = 500; 
all_T_Sum     = NaN(nPermutations,1); 
for iPerm = 1:nPermutations
    load(fullfile(input_fld,sprintf('MaxSumT_Perm%d.mat',iPerm))); 
    all_T_Sum(iPerm) = maxSumT; 
end

%% PLOT THE DITRIBUTION HISTOGRAM

all_T_Sum(all_T_Sum<0) = -500; % Assign large negative values to permutation w/ no candidate clusters
real_SumT = 1789;   % real sumT

nbins = 200; 
figure('Color','w'); 
histogram(all_T_Sum,nbins); 
set(gca,'XTick',[-500 0:500:3500]);hold on; 
vline(real_SumT,'r'); 
xlabel('Sum T'); 
ylabel('Occurrencies');
set(findall(gcf,'-property','FontSize'),'FontSize',30);
%% PRINT INFO ON THE SCREEN 
fprintf('\n\n SumT Surrogate HER > Real HER \t %d times (=%1.3f%%)',sum(all_T_Sum>real_SumT),sum(all_T_Sum>real_SumT)/nPermutations); 