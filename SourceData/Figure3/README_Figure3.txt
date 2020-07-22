######################################## Figure3A_ChosenSV_RvmPFC ################################################

The file contains: 
- ChosenSV_HERhig = 21x1 array containing the parameter estimates resulting from the regression predicting posterior R vmPFC cluster activity with Chosen value for trials with large HER amplitude in anterior R vmPFC. 
- ChosenSV_HERlow = 21x1 array containing the parameter estimates resulting from the regression predicting posterior R vmPFC cluster activity with Chosen value for trials with small HER amplitude in anterior R vmPFC. 


######################################## Figure3A_ChosenSV_LvmPFC ################################################

The file contains: 
- ChosenSV_HERhig = 21x1 array containing the parameter estimates resulting from the regression predicting posterior R vmPFC cluster activity with Chosen value for trials with large HER amplitude in anterior L vmPFC. 
- ChosenSV_HERlow = 21x1 array containing the parameter estimates resulting from the regression predicting posterior R vmPFC cluster activity with Chosen value for trials with small HER amplitude in anterior L vmPFC.  


######################################## Figure3B_GLM2 ################################################

The file contains: 
- BetasGLM2: 21x3 matrix. Each row represent one subject, each column represents the estimates for the predictors used in GLM2. 
First column =  ChosenValue, Second column = HER (anterior R vmPFC), third column = interaction of Chosen Value * HER


######################################## Figure3C_InterIndividualEffect ##########################################

The file contains: 
- BetaHERVAL = 21x1 array containing the parameter estimates for the interaction term HER*Chosen Value predicting the activity in the R vmPFC cluster encoding the chosen value. 
- ChoiceConsistency = 21x1 array containing choice consistency for the 50% of most difficult trials. 


######################################## Figure3D_PsychometricFunctions ############################################

The file contains 8 arrays and 2 matrices

DataAcc_HERlow and DataAcc_HERhig represent the performance grandaverages across subjects for each VD bin (top-bottom) for trials with large HER and small HER, respectively. 

DataAccSEM_HERlow and DataAccSEM_HERhig represent the SEM of performance grandaverages across subjects for each VD bin (top-bottom) for trials with large HER and small HER, respectively. 

ModAcc_HERlow and ModAcc_HERhig represent the performance grandaverages across subjects for each VD bin (top-bottom) as predicted by the parameters of the psychometric function for trials with large HER and small HER, respectively. 

ModAccSEM_HERlow and ModAccSEM_HERhig represent the SEM of performance grandaverages across subjects for each VD bin (top-bottom) as predicted by the parameters of the psychometric function for trials with large HER and small HER, respectively.

Note that to obtain smoother curves, the performance predicted by the logistic function features smaller steps (40 VD bins, instead of 10). This is for visualisation purpose only and does not affect results, as parameters are estimated on the continuous data (i.e. VD are not binned).  

PsychFun_Params_HERlow & PsychFun_Params_HERhig are two matrices. Rows correspond to subjects, while columns represent parameter estimates: the first column is the criterion, while the second is the slope of the psychometric function. 

##############################################################################################################################
