# [h2o](http://docs.h2o.ai/h2o/latest-stable/h2o-docs/welcome.html)
H2O is an open source, in-memory, distributed, fast, and scalable machine learning and predictive analytics platform that allows you to build machine learning models on big data and provides easy productionalization of those models in an enterprise environment. H2o can be used with R and Python, here are some R examples of unsupervised & supervised data addressed with h2o.ai. On top of h2o, other requirements are: ROCR, lubridate & ggplot2 libraries. 

#### h2o install in R: 
The following two commands remove any previously installed H2O packages for R.

```
if ("package:h2o" %in% search()) { detach("package:h2o", unload=TRUE) }
if ("h2o" %in% rownames(installed.packages())) { remove.packages("h2o") }
```

Next, download packages that H2O depends on.
```p
kgs <- c("RCurl","jsonlite")
for (pkg in pkgs) {
   if (! (pkg %in% rownames(installed.packages()))) { install.packages(pkg) }
}
```

Download and install the H2O package for R.
```
install.packages("h2o", type="source", repos=(c("http://h2o-release.s3.amazonaws.com/h2o/latest_stable_R")))
```

Errors in installation usually are because of java older/newer version, for ex: you may need to [install java 8](https://stackoverflow.com/questions/60274066/error-while-using-h2o-init-in-r-java-related), or to [point to your java 8](http://docs.h2o.ai/h2o/latest-stable/h2o-docs/faq/java.html#i-keep-getting-a-message-that-i-need-to-install-java-i-have-a-supported-version-of-java-installed-but-i-am-still-getting-this-message-what-should-i-do) in ios.  

## Unsupervised examples

### [iTree](https://github.com/camilaburne/h2o/tree/main/itree)

Anomaly detection with Isolation Forest (also referred as iTree in h2o documentation), using open [credit card data from Kaggle](https://www.kaggle.com/arjunbhasin2013/ccdata). The data containts usage behavior of about 9000 active credit card holders during the last 6 months. Most detected outliers include high amounts of payments and purchases. 

![alt text](https://github.com/camilaburne/h2o/blob/main/itree/itree_vs_logpayment.png  "Scatterplot of log payments vs predicted")

### [PCA](https://github.com/camilaburne/h2o/tree/main/PCA)

Purchase behaviour variable reduction with principal components analysis, using another [credit card data set from Kaggle](https://www.kaggle.com/kartik2112/fraud-detection) that was originally made for fraud detection. This data set includes purchases in categories such as restaurants, pets, gas stations, retail, miscellanea. With two components, about 72% of variance is explained. PCA in h2o follows same sintaxis as models, using model predict to score each PC. 


## Supervised examples

### [GBM Grid](https://github.com/camilaburne/h2o/tree/main/GBM)

Grid Search is an algorithm that adjusts thousands of models with different parameters, and chooses the best model by a metric (AUC in this case). Using the previous [credit card data set for fraud detection](https://www.kaggle.com/kartik2112/fraud-detection), a GBM quick grid with about 2K trees was adjusted to identify transactions. AUC obtained on the validation set is 94% (it's a simulated dataframe, never happens in real life). 

![alt text](https://github.com/camilaburne/h2o/blob/main/GBM/auc.png  "Insane AUC curve")
