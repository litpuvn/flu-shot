
# this code will convert classified tweets into transaction single format.
# each tweet is a transaction id and each important word in a transaction is an item.

set.seed(123)
library(tidytext)


#setwd("~/TTU-SOURCES/flu-shot")
setwd("~/Desktop/SOURCES/flue-shot")

tweets = read.csv("predicted-flu-shot.csv", stringsAsFactors = FALSE)

str(tweets)

cleanTweet = function(tweets) {
  replace_reg = "https://t.co/[A-Za-z\\d]+|http://[A-Za-z\\d]+|&amp;|&lt;|&gt;|RT|https"
  unnest_reg = "([^A-Za-z_\\d#@']|'(?![A-Za-z_\\d#@]))"
  
  tweets = tweets %>% 
    mutate(text = str_replace_all(tweet, replace_reg, ""))
  
  tweets$tweet = tweets$text
  tweets$text = NULL
  
  return(tweets)
}

tweets = cleanTweet(tweets)

library(reticulate)
use_python("/Users/longnguyen/anaconda/bin/python")
library(cleanNLP)
init_spaCy()

obj <- run_annotators(tweets$tweet, as_strings = TRUE)

names(obj)

get_document(obj)


transactions = get_token(obj)

stopWordList = c("flu", "shot", "shots", "feel", "like", "thank", "can", "may", "get", "got", "gotten", "think", "flushot", "be", "shoot", "-PRON-", stop_words$word)

meanfulUniversalPartOfSpeech = c("ADJ", "VERB")

transactions = transactions %>% 
  dplyr::filter(!lemma %in% stopWordList,
                str_detect(word, "[a-z]")) %>% 
  dplyr::filter(upos %in% meanfulUniversalPartOfSpeech,
                str_detect(word, "[a-z]"))

colnames(tweets)[1] = "id"
str(transactions)
str(tweets)

transactionData = inner_join(transactions, tweets, by="id")
transactionData <- transactionData[, c('id', 'lemma', 'predictedNegativeFlushot')]

colnames(transactionData) = c('transactionId', 'item', 'negativeFlushot')
additionalItems = unique(transactionData[c("transactionId", "negativeFlushot")])

str(transactionData)

# count word frequencies
count(transactionData, item, sort = TRUE )

additionalItems$item = additionalItems$negativeFlushot
additionalItems$item[additionalItems$negativeFlushot == 1] = "negative-flu-shot" 
additionalItems$item[additionalItems$negativeFlushot == 0] = "none-negative-flu-shot" 

str(additionalItems)

finalTransactionData <- rbind(transactionData, additionalItems)

str(finalTransactionData)

negativeFlushotData = finalTransactionData[finalTransactionData$negativeFlushot == 1,]
negativeFlushotData = negativeFlushotData[c('transactionId', 'item')]
write.csv(negativeFlushotData[c('transactionId', 'item')], file = "negative-tweet-transaction.csv", row.names=FALSE)

noneNegativeFlushotData = finalTransactionData[finalTransactionData$negativeFlushot == 0,]
noneNegativeFlushotData = noneNegativeFlushotData[c('transactionId', 'item')]
write.csv(noneNegativeFlushotData[c('transactionId', 'item')], file = "none-negative-tweet-transaction.csv", row.names=FALSE)

write.csv(transactionData, file = "tweet-word-transaction.csv", row.names=FALSE)

