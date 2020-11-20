library(h2o)
library(ggplot2)
library(lubridate)

options(scipen=999)

# h2o.shutdown()
# Read file from Kaggle Open Data 
#   File desc: simulated info from CC transaction to detect fraud
#              which we're gonna use to explore transactions
#   https://www.kaggle.com/kartik2112/fraud-detection 

cc <- read.csv('fraudTrain.csv')
st <- read.csv('states.csv')


# Unique customers: 983 
length(unique(cc$cc_num))

# Quick look into customers and their purchases
user     <- cc[duplicated(cc$cc_num)==F, c("cc_num","gender","state","city_pop","job", "dob")]
user$age <- year(as.Date(Sys.Date())) - year(as.Date(user$dob))
# genderN 1=female, 2=male

user$genderN <- as.numeric(user$gender)
# job variable into smaller categories ####
user$job <- tolower(user$job)
user$job2 = 0
user$job2[grep("transport", user$job)] = 1
user$job2[grep("assist", user$job)] = 1
user$job2[grep("retail", user$job)] = 1
user$job2[grep("restaurant", user$job)] = 1
user$job2[grep("industr", user$job)] = 1
user$job2[grep("technic", user$job)] = 1
user$job2[grep("prison", user$job)] = 1
user$job2[grep("commer", user$job)] = 1
user$job2[grep("sales", user$job)] = 1
user$job2[grep("bookseller", user$job)] = 1
user$job2[grep("dealer", user$job)] = 1
user$job2[grep("pilot", user$job)]  = 2
user$job2[grep("admini", user$job)] = 2
user$job2[grep("service", user$job)]= 2
user$job2[grep("manager", user$job)]= 2
user$job2[grep("editor", user$job)] = 2
user$job2[grep("editor", user$job)] = 2
user$job2[grep("producer", user$job)]= 2
user$job2[grep("educ", user$job)]   = 2
user$job2[grep("health", user$job)] = 2
user$job2[grep("writer", user$job)] = 2
user$job2[grep("teacher", user$job)] = 2
user$job2[grep("therap", user$job)] = 2
user$job2[grep("hospit", user$job)] = 2
user$job2[grep("nurse", user$job)] = 2
user$job2[grep("design", user$job)] = 2
user$job2[grep("analyst", user$job)] = 2
user$job2[grep("editor", user$job)] = 2
user$job2[grep("finan", user$job)]  = 3
user$job2[grep("officer", user$job)]  = 3
user$job2[grep("architect", user$job)]= 3
user$job2[grep("scientist", user$job)]= 3
user$job2[grep("law", user$job)]    = 3
user$job2[grep("IT", user$job)]     = 3
user$job2[grep("engineer", user$job)] = 3
user$job2[grep("developer", user$job)]= 3
user$job2[grep("chief", user$job)]  = 3 

# end job cats####


# Merge transactions & user data at user level 
# Create dummies 
dummies           <- as.data.frame(model.matrix(~cc$category))
dum               <- cbind(cc[, c("cc_num","amt","is_fraud")], dummies, dummies)
names(dum)[4]     <- 'total_cnt'
names(dum)[5:17]  <- paste0('cnt_',substring(names(dum)[5:17], 4, 25))
names(dum)[19:31] <- paste0('amt_',substring(names(dum)[19:31], 4, 25))

# Keep amounts in each category
dum[,c(19:31)]    <- dum[c(19:31)]* dum$amt
dum$`(Intercept)` <- NULL 
head(dum,2)

# Aggregate at user level & merge with user data & state data
dfu <- aggregate(. ~ cc_num, data = dum, sum)
df  <- merge(user, dfu, by = "cc_num")
df  <- merge(df, st, by.x = 'state', by.y = 'State.Code', all.x = T)
head(df,2)

df$RegionN = 0
df$RegionN[df$Region=='Northeast'] =4
df$RegionN[df$Region=='West'] =3
df$RegionN[df$Region=='Midwest'] =2
df$RegionN[df$Region=='South'] =1


# Quant vars for PCA 
pca_vars <- names(df)[c(4,7:10, 12:38,42 )]
head( df[, pca_vars])

# PCA with h2o ####
h2o.init()
h_df <- as.h2o(x = df[, pca_vars])

# Build and train the model:
# PCA Methods: "GramSVD", "Power", "Randomized", "GLRM"
# Transfor Methods: "NONE", "STANDARDIZE", "NORMALIZE", "DEMEAN", "DESCALE"
pca <- h2o.prcomp(training_frame = h_df, k = 3, use_all_factor_levels = TRUE,
                  pca_method = "GLRM", transform = "DESCALE", impute_missing = FALSE)
# PC Importance 
pca@model$importance

# Eigenvectors 
eigen <- as.data.frame(pca@model$eigenvectors)

# PCA meaning by looking at eigenvectors: 
# Keep PC values - similarly to model predictions on a validation set
pred   <- h2o.predict(pca, newdata = h_df)
df_pca <- cbind(df, as.data.frame(pred))

# Check PCA agains vars 
df_pca$RegionF <- factor(df_pca$RegionN, levels = c("0", "1" , "2",   "3", "4"),
                         labels = c("Miss","South", "Midwest", "West", "Northeast")) 
ggplot(df_pca ) +
  geom_point(aes(x=PC1, y=PC2,  color=RegionF),size=1.5, alpha = 0.6)+
  xlab( 'PC1')+
  ylab( 'PC2' )+ggtitle('First 2 Components')
  
ggplot(df_pca ) +
  geom_point(aes(x=PC1, y=PC2,  color=gender),size=1.5, alpha = 0.6)+
  xlab( 'PC1')+
  ylab( 'PC2' )+ggtitle('First 2 Components')

ggplot(df_pca ) +
  geom_point(aes(x=PC1, y=PC2,  color=job2),size=1.5, alpha = 0.6)+
  xlab( 'PC1')+
  ylab( 'PC2' )+ggtitle('First 2 Components')

