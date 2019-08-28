# ANOVA_BEHAVIOR
# The scripts compute the ANOVA stats as they are reported in 
# PREFER manuscript 
# DA 2018/04/11 

# LOAD LIBRARIES
library(car)
library(ggplot2)
library(plyr)
library(dplyr)
srcFld  = "/Volumes/BACKUP_PREF/Final_Scripts/Behavior_Rscripts/"
data_fn = "/Volumes/BACKUP_PREF/Final_Results/Behavior/ANOVA/Behavior.csv"
data = read.csv(data_fn,header=TRUE)  # read text file 

# Make levels as factor (subjs, task and difficulty)
data$SUB = factor(data$SUB)
data$TASK = factor(data$TASK)
data$DQ_fact = factor(data$DQ_bin)
summary(data)

# Mean for each subject, task and DQ
dataM = ddply(data,c('SUB','TASK','DQ_fact'), summarize,RTm=mean(RT), PERFm=mean(PERF))
summary(dataM)

##############  ONE-WAY ANOVA ##############  
# Select SUBJ task 
subset = dataM[dataM$TASK=='1',]
summary(subset)
# Accuracy
aov_SubP <- aov(subset$PERFm ~ subset$DQ_fact + Error(subset$SUB/subset$DQ_fact));
summary(aov_SubP)

# RT
aov_SubRT <- aov(subset$RTm ~ subset$DQ_fact + Error(subset$SUB/subset$DQ_fact));
summary(aov_SubRT)


# Select OBJ task 
objset = dataM[dataM$TASK=='2',]
summary(objset)
# Accuracy
aov_ObjP <- aov(objset$PERFm ~ objset$DQ_fact + Error(objset$SUB/objset$DQ_fact));
summary(aov_ObjP)
# RT
aov_ObjRT <- aov(objset$RTm ~ objset$DQ_fact + Error(objset$SUB/objset$DQ_fact));
summary(aov_ObjRT)


##############  TWO-WAYS ANOVA (Task,difficulty) ##############  
# PERFORMANCE 
PERF_2Task <- aov(dataM$PERFm ~ dataM$TASK*dataM$DQ_fact + Error(dataM$SUB/(dataM$TASK*dataM$DQ_fact)))
summary(PERF_2Task)

# RT
RT_2Task <- aov(dataM$RTm ~ dataM$TASK*dataM$DQ_fact + Error(dataM$SUB/(dataM$TASK*dataM$DQ_fact)))
summary(RT_2Task)
