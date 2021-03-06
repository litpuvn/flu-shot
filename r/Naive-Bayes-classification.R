# Load required libraries

library(tm)
library(RTextTools)
library(e1071)
library(dplyr)
library(caret)
# Library for parallel processing
library(doMC)
registerDoMC(cores=detectCores())  # Use all available cores



setwd("~/TTU-SOURCES/flu-shot")


# load the data
df<- read.csv("data/movie-pang02.csv", stringsAsFactors = FALSE)
glimpse(df)

# randomize the data set
set.seed(1)
df <- df[sample(nrow(df)), ]
df <- df[sample(nrow(df)), ]
glimpse(df)

# Convert the 'class' variable from character to factor.
df$class <- as.factor(df$class)


#tokenize
corpus <- Corpus(VectorSource(df$text))
# Inspect the corpus
corpus
## <<VCorpus>>
## Metadata:  corpus specific: 0, document level (indexed): 0
## Content:  documents: 2000
inspect(corpus[1:3])

# data clean up - common
corpus.clean <- corpus %>%
  tm_map(content_transformer(tolower)) %>% 
  tm_map(content_transformer(removePunctuation)) %>%
  tm_map(content_transformer(removeNumbers)) %>%
  tm_map(content_transformer(removeWords), stopwords(kind="en")) %>%
  tm_map(content_transformer(stripWhitespace))

inspect(corpus.clean[1:3])

# create Document Term Matrix
dtm <- DocumentTermMatrix(corpus.clean)
# Inspect the dtm
inspect(dtm[40:50, 10:15])


#  create 75:25 partitions of the dataframe, corpus and document term matrix for training and testing purposes.
df.train <- df[1:1500,]
df.test <- df[1501:2000,]

nrow(df.train)


dtm.train <- dtm[1:1500,]
dtm.test <- dtm[1501:2000,]
inspect(dtm.train[1:3, 1:10])
nrow(dtm.train)

corpus.clean.train <- corpus.clean[1:1500]
corpus.clean.test <- corpus.clean[1501:2000]
nrow(corpus.clean.train)
# feature selection
# We reduce the number of features by ignoring words which appear in less than five reviews.
dim(dtm.train)

fivefreq <- findFreqTerms(dtm.train, 5)
length((fivefreq))

# Use only 5 most frequent words (fivefreq) to build the DTM
dtm.train.nb <- DocumentTermMatrix(corpus.clean.train, control=list(dictionary = fivefreq))
dim(dtm.train.nb)

# create test DTM
dtm.test.nb <- DocumentTermMatrix(corpus.clean.test, control=list(dictionary = fivefreq))
dim(dtm.train.nb)

str(dtm.train.nb)

inspect(dtm.train.nb[1:5, 1:10])

# Function to convert the word frequencies to yes (presence) and no (absence) labels
convert_count <- function(x) {
  y <- ifelse(x > 0, 1,0)
  y <- factor(y, levels=c(0,1), labels=c("No", "Yes"))
  return (y)
}

# Apply the convert_count function to get final training and testing DTMs
# apply() allows us to work either with rows or columns of a matrix.
# MARGIN = 1 is for rows, and 2 for columns
trainNB <- apply(dtm.train.nb, 2, convert_count)
testNB <- apply(dtm.test.nb, 2, convert_count)
str(dtm.train.nb)
str(trainNB)
#inspect(trainNB[40:50, 10:15])

# Train the classifier
# Since Naive Bayes evaluates products of probabilities, we need some way of assigning non-zero probabilities 
# to words which do not occur in the sample. We use Laplace 1 smoothing to this end.
system.time( classifier <- naiveBayes(trainNB, df.train$class, laplace = 1) )

# Use the NB classifier we built to make predictions on the test set.
system.time( pred <- predict(classifier, newdata=testNB) )

# Create a truth table by tabulating the predicted class labels with the actual class labels 
table("Predictions"= pred,  "Actual" = df.test$class )

# Prepare the confusion matrix
conf.mat <- confusionMatrix(pred, df.test$class)
conf.mat

conf.mat$byClass

conf.mat$overall
conf.mat$overall['Accuracy']


