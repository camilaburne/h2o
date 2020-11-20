# h2o
Projects addressed with h2o.ai. 
Requirements: h2o, ROCR, lubridate & ggplot2 libraries. 


## [iTree](https://github.com/camilaburne/h2o/tree/main/itree)
Anomaly detection with Isolation Forest (also referred as iTree in h2o documentation), using open [credit card data from Kaggle](https://www.kaggle.com/arjunbhasin2013/ccdata). The data containts usage behavior of about 9000 active credit card holders during the last 6 months. Most detected outliers include high amounts of payments and purchases. 

![alt text](https://github.com/camilaburne/h2o/blob/main/itree/itree_vs_logpayment.png  "Scatterplot of log payments vs predicted")

## [PCA](https://github.com/camilaburne/h2o/tree/main/PCA)
Purchase behaviour variable reduction with principal components analysis, using another [credit card data set from Kaggle](https://www.kaggle.com/kartik2112/fraud-detection) that was originally made for fraud detection. This data set includes purchases in categories such as restaurants, pets, gas stations, retail, miscellanea. With two components, about 72% of variance is explained. PCA in h2o follows same sintaxis as models, using model predict to score each PC. 

## [GBM Grid](https://github.com/camilaburne/h2o/tree/main/GBM)
Grid Search is an algorithm that adjusts thousands of models with different parameters, and chooses the best model by a metric (AUC in this case). Using the previous [credit card data set for fraud detection](https://www.kaggle.com/kartik2112/fraud-detection), a GBM quick grid with about 2K trees was adjusted to identify transactions. AUC obtained on the validation set is 94% (it's a simulated dataframe, never happens in real life). 


![alt text](https://github.com/camilaburne/h2o/blob/main/GBM/auc.png  "Insane AUC curve")
