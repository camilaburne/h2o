list.files()
library(h2o)
library(ggplot2)
library(lubridate)
library(ROCR)

options(scipen=999)

# h2o.shutdown()
# Import a sample binary outcome dataset into H2O
#   File desc: simulated info from CC transaction to detect fraud
#   https://www.kaggle.com/kartik2112/fraud-detection 

data <- read.csv('fraudTrain.csv', sep=',')
test <- read.csv('fraudTest.csv', sep=',')

# Keep age and gender as numeric fields, then ignore. 
data$age    <- year(as.Date(Sys.Date())) - year(as.Date(data$dob))
test$age    <- year(as.Date(Sys.Date())) - year(as.Date(test$dob))
data$gender <- as.numeric(data$gender)
test$gender <- as.numeric(test$gender)

# GBM with h2o 
h2o.init()

data <- as.h2o(x = data)
test <- as.h2o(x = test)

# Identify predictors (quant vars) and response (is fraud flag)
y <- "is_fraud"
x <- setdiff(names(data), c(y,"C1","trans_date_trans_time","street" , "cc_num","first","last","merchant", 
                            "dob","state", "unix_time","trans_num", "X", "zip", "city", "job"))
head(data[,x])

# For binary classification, response should be a factor
data[, y] <- as.factor(data[, y])
test[, y] <- as.factor(test[, y])

# Split data into train & validation
ss <- h2o.splitFrame(data, seed = 1)
train <- ss[[1]]
valid <- ss[[2]]

# GBM Grid parameters #####
minDepth <- 1
maxDepth <- 3

hyper_params = list(
  max_depth = seq(minDepth,maxDepth,1),                                      
  sample_rate = seq(0.2,1,0.01),                                             
  col_sample_rate = seq(0.2,1,0.01),                                         
  col_sample_rate_per_tree = seq(0.2,1,0.01),                                
  col_sample_rate_change_per_level = seq(0.8,1.1,0.01),                      
  min_rows = 2^seq(0,log2(nrow(data))-1,1),                                 
  nbins = 2^seq(4,10,1),                                                     
  nbins_cats = 2^seq(4,12,1),                                                
  min_split_improvement = c(0,1e-8,1e-6,1e-4),                               
  histogram_type = c("UniformAdaptive","QuantilesGlobal","RoundRobin")
)

search_criteria = list(
  strategy = "RandomDiscrete",      
  max_runtime_secs = 150,         
  max_models = 50,                  
  seed = 6680796,                        
  stopping_rounds = 5,                
  stopping_metric = "AUC",
  stopping_tolerance = 1e-4   # default is 1e-4, here use 1e-3 to accelerate speed
)
# End of GBM Grid parameters #####


# Train and validate a cartesian grid of GBMs
# Our train has +970K rows, and valid frame has 324K rows. 
gbm_grid1 <- h2o.grid("gbm", x = x, y = y,
                      grid_id = "gbm_grid1",
                      training_frame = train,
                      validation_frame = valid,
                      ntrees = 100,
                      seed = 1,
                      search_criteria = search_criteria,
                      hyper_params = hyper_params)

# Get the grid results, sorted by validation AUC
gbm_gridperf1 <- h2o.getGrid(grid_id = "gbm_grid1",
                             sort_by = "auc",
                             decreasing = TRUE)

# "Best" and "Worst" models from grid
print(gbm_gridperf1)
h2o.getModel(gbm_gridperf1@model_ids[[1]])
h2o.getModel(gbm_gridperf1@model_ids[[17]])

# Grab the top GBM model, chosen by validation AUC
best_gbm1 <- h2o.getModel(gbm_gridperf1@model_ids[[1]])

# Look at the hyperparameters for the best model
print(best_gbm1@model[["model_summary"]])

# Check variable importance
h2o.varimp(best_gbm1)

# Now let's evaluate the model performance on a test set
# so we get an honest estimate of top model performance
best_gbm1_perf  <- h2o.performance(model = best_gbm1, newdata = test)
h2o.auc(best_gbm1_perf)
# 0.94

# Insane AUC curve 
model1.pred = h2o.predict(best_gbm1, test)
pred <- prediction(as.vector(model1.pred$p1), as.vector(test[[y]]))
perf <- performance(pred,"tpr","fpr")
ks   <- max(attr(perf,'y.values')[[1]]-attr(perf,'x.values')[[1]])
auc  <- performance(pred, measure = "auc")@y.values[[1]]

plot(perf,col='grey75', lwd =3, 
     main=paste0('Insane AUC curve with KS=',round(ks*100,1),'% AUC=', round(auc*100,1), '%'))
lines(x = c(0,1),y=c(0,1), col='orange', lwd=3, lty=3)

