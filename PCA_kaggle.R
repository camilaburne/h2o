library(h2o)
library(ggplot2)
library(lubridate)

options(scipen=999)

# Read file from Kaggle Open Data 
#   File desc: simulated info from CC transaction to detect fraud
#              which we're gonna use to explore transactions
#   https://www.kaggle.com/kartik2112/fraud-detection 

cc <- read.csv('fraudTrain.csv')

# Unique customers: 983 
length(unique(cc$cc_num))

# Quick look into customers and their purchases
user     <- cc[duplicated(cc$cc_num)==F, c("cc_num","gender","state","city_pop","job", "dob")]
user$age <- year(as.Date(Sys.Date())) - year(as.Date(user$dob))

# job variable into smaller categories ####
user$job <- tolower(user$job)
user$job2 = 0
user$job2[grep("transport", user$job)] = 1
user$job2[grep("assist", user$job)] = 1
user$job2[grep("retail", user$job)] = 1
user$job2[grep("restaurant", user$job)] = 1
user$job2[grep("industr", user$job)] = 1
user$job2[grep("technic", user$job)] = 1
user$job2[grep("prison", user$job)] = 2
user$job2[grep("commer", user$job)] = 2
user$job2[grep("sales", user$job)] = 2
user$job2[grep("bookseller", user$job)] = 2
user$job2[grep("dealer", user$job)] = 2
user$job2[grep("pilot", user$job)]  = 3
user$job2[grep("admini", user$job)] = 3
user$job2[grep("service", user$job)]= 3
user$job2[grep("manager", user$job)]= 3
user$job2[grep("editor", user$job)] = 4
user$job2[grep("editor", user$job)] = 4
user$job2[grep("producer", user$job)]= 4
user$job2[grep("educ", user$job)]   = 4
user$job2[grep("health", user$job)] = 4
user$job2[grep("writer", user$job)] = 4
user$job2[grep("teacher", user$job)] = 4
user$job2[grep("therap", user$job)] = 4
user$job2[grep("hospit", user$job)] = 4
user$job2[grep("nurse", user$job)] = 4
user$job2[grep("design", user$job)] = 4
user$job2[grep("analyst", user$job)] = 4
user$job2[grep("editor", user$job)] = 4
user$job2[grep("finan", user$job)]  = 5
user$job2[grep("officer", user$job)]  = 5
user$job2[grep("architect", user$job)]= 5
user$job2[grep("scientist", user$job)]= 5
user$job2[grep("law", user$job)]    = 5
user$job2[grep("IT", user$job)]     = 6
user$job2[grep("engineer", user$job)] = 6
user$job2[grep("developer", user$job)]= 6
user$job2[grep("chief", user$job)]  = 7 

# end job cats####


# Merge transactions & user data at user level 
# Create dummies 
dummies           <- as.data.frame(model.matrix(~cc$category))
dum               <- cbind(cc[, c("cc_num","amt","is_fraud")], dummies, dummies)
names(dum)[4]     <- 'total_cnt'
names(dum)[5:17]  <- paste0('cnt_',substring(names(dum)[5:17], 4, 25))
names(dum)[19:31] <- paste0('amt_',substring(names(dum)[19:31], 4, 25))

# Keep amounts in each category
dum[,c(19:31)]    <- dum[,c(19:31)]*df$amt
dum$`(Intercept)` <- NULL 

# Aggregate at user level & merge with user data
dfu <- aggregate(. ~ cc_num, data = dum, sum)
df  <- merge(user, dfu, by = "cc_num")

# Quant vars for PCA 
pca_vars <- names(df)[c(2,4,7:9, 11:37)]

# PCA with h2o ####
h2o.init()
h_df <- as.h2o(x = df[, pca_vars])

# Build and train the model:
# PCA Methods: "GramSVD", "Power", "Randomized", "GLRM"
# Transfor Methods: "NONE", "STANDARDIZE", "NORMALIZE", "DEMEAN", "DESCALE"
pca <- h2o.prcomp(training_frame = h_df, k = 3, use_all_factor_levels = TRUE,
                  pca_method = "GLRM", transform = "STANDARDIZE", impute_missing = FALSE)
# PC Importance 
pca@model$importance

# Eigenvectors 
eigen <- as.data.frame(pca@model$eigenvectors)

# PCA meaning by looking at eigenvectors:
# PC1 is about young families, big spenders, purchases with kids and pets. 
# PC2 is about single people, going out. 

# Keep PC values - similarly to model predictions on a validation set
pred   <- h2o.predict(pca, newdata = h_df)
df_pca <- cbind(df, as.data.frame(pred))

# Maybe check what's the relation between pcas and flags 
df_pca$is_fraud_flag = 0 
df_pca$is_fraud_flag[df_pca$is_fraud>0] = 1
df_pca$is_fraud_flag = as.factor(df_pca$is_fraud_flag)

ggplot(df_pca ) +
  geom_point(aes(x=PC1, y=PC2,  color=is_fraud_flag),size=1.5, alpha = 0.6)


