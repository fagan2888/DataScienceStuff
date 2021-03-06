# This R environment comes with all of CRAN preinstalled, as well as many other helpful packages
# The environment is defined by the kaggle/rstats docker image: https://github.com/kaggle/docker-rstats
# For example, here's several helpful packages to load in
library(ggplot2) # Data visualization
library(readr) # CSV file I/O, e.g. the read_csv function
library(Hmisc)
# Input data files are available in the "../input/" directory.
# For example, running this (by clicking run or pressing Shift+Enter) will list the files in the input directory
# system("ls ../input")
# Any results you write to the current directory are saved as output.
# ------------------------------------------------------------------
# R version of some Machine Learning Method starter code using H2O.
# Average of multiple H2O DNN models
# Fork from https://www.kaggle.com/kumareshd/allstate-claims-severity/performance-of-different-methods-in-r-using-h2o/discussion
# Example parameters https://github.com/h2oai/h2o-3/blob/0d3e52cdce9f699a8d693b5d3b11c8bd3e15ca02/h2o-r/h2o-package/R/deeplearning.R
# See: http://mlwave.com/kaggle-ensembling-guide/
# Load H2O
library(h2o)
kd_h2o<-h2o.init(nthreads = -1, max_mem_size = "7g")
# Installation of H2O-Ensemble, does not work on Kaggle cloud
# install.packages("https://h2o-release.s3.amazonaws.com/h2o-ensemble/R/h2oEnsemble_0.1.8.tar.gz", repos = NULL)
library(h2oEnsemble)
# Locally start jar and then use this line
# kd_h2o<-h2o.init(ip = "localhost", port = 54323 ,nthreads = -1, max_mem_size = "10g")
#Reading Data, old school read.csv. Using fread is faster.
set.seed(12345)
train<-read.csv('train.csv')
test<-read.csv('test.csv')
train.index <- train[,1]
test.index <- test[,1]
train.loss <- train[,ncol(train)]
bulk <- rbind(train[,-ncol(train)], test)
bulk$id <- NULL
##Converting categories to numeric
#this is done by first splitting the binary level, multi-level, and
#continuous variables
#colnames(all.train)
bin.train <- bulk[,1:72]
cat.train <- bulk[,73:116]
cont.train <- bulk[,117:130]
##Combine levels
#combining multiple levels using combine.levels
#minimum 5%
temp <- sapply(cat.train, combine.levels, minlev = 0.02)
temp <- as.data.frame(temp)
str(temp)
#cbind binary and reduced categorical levels
# comb.train <- cbind(bin.train, cat.train)
comb.train <- cbind(bin.train, temp)
##Dummify all factor variables
#dmy <- dummyVars(" ~ .", data = comb.train, fullRank=T)
#temp <- as.data.frame(predict(dmy, newdata = comb.train))
#dim(temp)
##Combine dummified with cont vars
bulk <- cbind(comb.train, cont.train)
dim(bulk)
#split dataset into new train and new test with combine
train.e = bulk[1:nrow(train),]
test.e = bulk[(nrow(train)+1):nrow(bulk),]
#re-attach index
train.e <- cbind(train.index, train.e)
test.e <- cbind(test.index, test.e)
#re-attach loss
train.e$loss <- train.loss
train <- train.e
test <- test.e
train<-train[,-1]
test_label<-test[,1]
test<-test[,-1]
index<-sample(1:(dim(train)[1]), 0.2*dim(train)[1], replace=FALSE)
train_frame<-train[-index,]
valid_frame<-train[index,]
valid_predict<-valid_frame[,-ncol(valid_frame)]
valid_loss<-valid_frame[,ncol(valid_frame)]
# # log transform
# shift <- 200
# train_frame[,ncol(train_frame)]<-log(train_frame[,ncol(train_frame)]) + shift
# valid_frame[,ncol(train_frame)]<-log(valid_frame[,ncol(valid_frame)]) + shift
# load H2o data frame // validate that H2O flow looses all continous data
train_frame.hex<-as.h2o(train_frame)
valid_frame.hex<-as.h2o(valid_frame)
valid_predict.hex<-as.h2o(valid_predict)
test.hex<-as.h2o(test)
#---------------
#creating custom learners
h2o.glm.1 <- function(..., alpha = 0.0, family = "gamma" )#, link = "log") 
  h2o.glm.wrapper(..., alpha = alpha, family = family )#, link = link)
h2o.glm.2 <- function(..., alpha = 0.5, family = "gamma" )#, link = "log") 
  h2o.glm.wrapper(..., alpha = alpha, family = family )#, link = link)
h2o.glm.3 <- function(..., alpha = 1.0, family = "gamma" )#, link = "log") 
  h2o.glm.wrapper(..., alpha = alpha, family = family )#, link = link)
h2o.gbm.1 <- function(..., ntrees = 500, seed = 1, distribution = "gamma") 
  h2o.gbm.wrapper(..., ntrees = ntrees, seed = seed, distribution = distribution)
h2o.gbm.3 <- function(..., ntrees = 300, max_depth = 10, seed = 1, distribution = "gamma") 
  h2o.gbm.wrapper(..., ntrees = ntrees, max_depth = max_depth, seed = seed, distribution = distribution)
h2o.gbm.4 <- function(..., ntrees = 300, col_sample_rate = 0.8, seed = 1, distribution = "gamma") 
  h2o.gbm.wrapper(..., ntrees = ntrees, col_sample_rate = col_sample_rate, seed = seed, distribution = distribution)
h2o.gbm.5 <- function(..., ntrees = 300, col_sample_rate = 0.7, seed = 1, distribution = "gamma") 
  h2o.gbm.wrapper(..., ntrees = ntrees, col_sample_rate = col_sample_rate, seed = seed, distribution = distribution)
h2o.gbm.6 <- function(..., ntrees = 300, col_sample_rate = 0.6, seed = 1, distribution = "gamma") 
  h2o.gbm.wrapper(..., ntrees = ntrees, col_sample_rate = col_sample_rate, seed = seed, distribution = distribution)
h2o.gbm.8 <- function(..., ntrees = 300, max_depth = 3, seed = 1, distribution = "gamma") 
  h2o.gbm.wrapper(..., ntrees = ntrees, max_depth = max_depth, seed = seed, distribution = distribution)
h2o.deeplearning.1 <- function(..., hidden = c(500,500), activation = "Rectifier", epochs = 50, seed = 1, distribution = "gamma") 
  h2o.deeplearning.wrapper(..., hidden = hidden, activation = activation, seed = seed, distribution = distribution)
h2o.deeplearning.2 <- function(..., hidden = c(200,100,50), activation = "Tanh", epochs = 50, seed = 1, distribution = "gamma") 
  h2o.deeplearning.wrapper(..., hidden = hidden, activation = activation, seed = seed, distribution = distribution)
h2o.deeplearning.3 <- function(..., hidden = c(500,500), activation = "RectifierWithDropout", epochs = 50, seed = 1, distribution = "gamma") 
  h2o.deeplearning.wrapper(..., hidden = hidden, activation = activation, seed = seed, distribution = distribution)
h2o.deeplearning.5 <- function(..., hidden = c(100,100,100), activation = "Rectifier", epochs = 50, seed = 1, distribution = "gamma") 
  h2o.deeplearning.wrapper(..., hidden = hidden, activation = activation, seed = seed, distribution = distribution)
h2o.deeplearning.6 <- function(..., hidden = c(50,50), activation = "Rectifier", epochs = 50, seed = 1, distribution = "gamma") 
  h2o.deeplearning.wrapper(..., hidden = hidden, activation = activation, seed = seed, distribution = distribution)
h2o.deeplearning.7 <- function(..., hidden = c(100,100), activation = "Rectifier", epochs = 50, seed = 1, distribution = "gamma") 
  h2o.deeplearning.wrapper(..., hidden = hidden, activation = activation, seed = seed, distribution = distribution)
#---------------------------------------
#----------------------------------------
learner <- c(
  "h2o.glm.wrapper",
  "h2o.glm.1",
  "h2o.glm.2",
  "h2o.glm.3",
  "h2o.gbm.3",
  "h2o.gbm.4",
  "h2o.gbm.6",
  "h2o.deeplearning.wrapper",
  "h2o.deeplearning.1",
  "h2o.deeplearning.2",
  "h2o.deeplearning.3"
)
metalearner <- "h2o.glm.wrapper"
# Passing the validation_frame to h2o.ensemble does not currently do anything.
# Right now, you must use the predict.h2o.ensemble function to generate predictions on a test set.
### Checkpoint
fit <- h2o.ensemble(x = 1:(ncol(train_frame.hex)-1), y = ncol(train_frame.hex),
                    train_frame.hex, validation_frame=valid_frame.hex,
                    family = "AUTO",
                    learner = learner,
                    metalearner = metalearner,
                    cvControl = list(V = 15))
pred <- predict(fit,valid_frame.hex)
# Save the fit ensemble to disk
# the model will be saved as "./folder_for_myDRF/myDRF"
h2o.save_ensemble(fit, path = "fit_gamma") # define your path here
# show stacked prediction and all 4 independent learners
# h2o.glm.wrapper h2o.randomForest.wrapper h2o.gbm.wrapper h2o.deeplearning.wrapper
head(pred)
# show combined only
head(pred[1])
# show h2o.glm.wrapper
head(pred$basepred[1])
pred_m1 <-as.matrix(pred$basepred[1])
score_m1=mean(abs(((pred_m1))-valid_loss))
cat("score_m1 (h2o.glm.wrapper) :",score_m1,"\n")
pred_m2 <-as.matrix(pred$basepred[2])
score_m2=mean(abs(((pred_m2))-valid_loss))
cat("score_m2 ( h2o.randomForest.2) :",score_m2,"\n")
pred_m3 <-as.matrix(pred$basepred[3])
score_m3=mean(abs(((pred_m3))-valid_loss))
cat("score_m3 (h2o.gbm.1 ):",score_m3,"\n")
pred_m4 <-as.matrix(pred$basepred[4])
score_m4=mean(abs(((pred_m4))-valid_loss))
cat("score_m4 (h2o.gbm.6):",score_m4,"\n")
pred_m5 <-as.matrix(pred$basepred[5])
score_m5=mean(abs(((pred_m5))-valid_loss))
cat("score_m5 (h2o.gbm.8):",score_m5,"\n")
pred_m6 <-as.matrix(pred$basepred[6])
score_m6=mean(abs(((pred_m6))-valid_loss))
cat("score_m6 (h2o.deeplearning.wrapper):",score_m6,"\n")
# Average everything
pred_average=(((pred_m1+pred_m2+pred_m3+pred_m4+pred_m5+pred_m6))/6)
colnames(pred_average) = "predict"
score_average=mean(abs((pred_average)-valid_loss))
cat("Ensemble score: (simple average) " ,score_average,"\n")
# get the H2O.ensemble score
pred_ensemble <-(as.matrix(pred[[1]]))
score_ensemble=mean(abs((pred_ensemble)-valid_loss))
cat("score_meta (h2o.ensemble):",score_ensemble,"\n")
# final predict the full test sets
pred_test <- as.matrix(predict(fit,test.hex))
# Write ensemble submissions
# local: submission = read.csv('./data/sample_submission.csv', colClasses = c("integer", "numeric"))
submission = read.csv('sample_submission.csv', colClasses = c("integer", "numeric"))
submission$loss = as.numeric(as.matrix(((pred_test[[1]]))))
write.csv(submission, 'h2_cd_gamma.csv', row.names=FALSE)
# score_m1 (h2o.glm.wrapper) : 1239.485
# score_m2 (h2o.randomForest.wrapper) : 1334.707
# score_m3 (h2o.gbm.wrapper ): 1195.514
# score_m4 (h2o.deeplearning.wrapper): 1142.196
# Ensemble score: (simple average) 1179.01
# score_meta (h2o.ensemble): 1139.925
# LB Score 1135.30449
# Save the fit ensemble to disk
# the model will be saved as "./folder_for_myDRF/myDRF"
h2o.save_ensemble(fit, path = "fit_deeplearn_metagbm") # define your path here