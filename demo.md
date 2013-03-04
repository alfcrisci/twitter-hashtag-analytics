Demo of Using twitter-hashtag-analytics to Analyze Tweets
========================================================

Building on [Ben Marwick](https://github.com/benmarwick/AAA2011-Tweets), [Martin Hawksey](http://mashe.hawksey.info/2012/01/tags-r/) and [Tony Hirst](http://blog.ouseful.info/2012/01/21/a-quick-view-over-a-mashe-google-spreadsheet-twitter-archive-of-ukgc2012-tweets/)'s work on analyzing tweets with R, I started an R project for tweet analysis, namely [twitter-hashtag-analytics](https://github.com/dirkchen/twitter-hashtag-analytics). This project is hosted on Github and welcomes anyone who's interested to contribute. It is my very first attempt to write a package in R, so I admit the capabilities of it is still limited and its structure may be not properly planned. Any advice will be highly appreciated.

This demo, drafted with [knitr](http://yihui.name/knitr/), aims to show the functionality of [twitter-hashtag-analytics](https://github.com/dirkchen/twitter-hashtag-analytics) and also available on Github. It will evlove along with this project

Data Preparation
-----------------------

Before starting to analyze tweets, we will first load a few source files (libraries) in this project.


```r
# check working directory
getwd()

# note that Knitr automatically sets wd to where the Rmd file is.  so if
# you wish to run code line-by-line, you should setwd mannually.
# setwd('/home/bodong/src/r/twitter-analytics/twitter-hashtag-analytics')

# load source files
source("get_tweets.R")
source("munge_tweets.R")
source("utilities.R")
```


Then we can retrieve a Twitter hashtag dataset by searching through Twitter API. Two other methods of retriving tweets implemented in this project so far include **retriving from Google Spreadsheet archives** (see [here](http://mashe.hawksey.info/2013/02/twitter-archive-tagsv5/)) and **reading directly from a CSV file**.


```r
# get tweets by search
# this function is defined in get_tweets.R
df <- GetTweetsBySearch('#LAK13')

# save or load data (so you can reuse data rather than search all the time)
save(df, file="./data/df.Rda")
# load("./data/df.Rda")
```


This dataset contains 101 tweets posted by 49 unique Twitter users between 2013-02-20 and 2013-02-26.

Because tweet information retrieved through twitteR is kind of limited (see its [reference manual](http://cran.r-project.org/web/packages/twitteR/index.html), p. 11), we need to extract user information, such as `reply_to_user` and `retweet_from_user`, mannually from each tweet. At the same time, the names of metadata in twitteR are quite different from those used in the official Twitter API, the following `PreprocessTweets` function in `munge_tweets.R` also renames some attributes of tweets. Moreover, the `PreprocessTweets` function also trims urls in tweets and put them in a new column named `links`.


```r
# preprocessing
df <- PreprocessTweets(df)

# structure of df
str(df)
```

```
## 'data.frame':	101 obs. of  14 variables:
##  $ text        : chr  "Professor in Learning Analytics - Milton Keynes - OPEN UNIVERSITY  #jobs Anyone interested from #LAK13" "RT @sbskmi: #LearningAnalytics tutorials + practicals in #lak13 open course: Tableau, R + Evidence Hub " "Demo of Using twitter-hashtag-analytics Package to Analyze Tweets from #LAK13 " "Introducing Drake, a kind of 'make for data' from @factual:  #lak13" ...
##  $ favorited   : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
##  $ replyToSN   : logi  NA NA NA NA NA NA ...
##  $ created_at  : POSIXct, format: "2013-02-26 20:32:29" "2013-02-26 20:22:12" ...
##  $ truncated   : logi  FALSE FALSE FALSE FALSE FALSE FALSE ...
##  $ replyToSID  : chr  NA NA NA NA ...
##  $ id          : chr  "306502014211354624" "306499425751162880" "306492081793282048" "306487793666891776" ...
##  $ replyToUID  : logi  NA NA NA NA NA NA ...
##  $ statusSource: chr  "&lt;a href=&quot;http://twitter.com/tweetbutton&quot;&gt;Tweet Button&lt;/a&gt;" "&lt;a href=&quot;http://www.tweetdeck.com&quot;&gt;TweetDeck&lt;/a&gt;" "&lt;a href=&quot;http://publicize.wp.com/&quot;&gt;WordPress.com&lt;/a&gt;" "&lt;a href=&quot;http://www.tweetdeck.com&quot;&gt;TweetDeck&lt;/a&gt;" ...
##  $ screen_name : chr  "EleniZazani" "sjgknight" "bodongchen" "cteplovs" ...
##  $ from_user   : chr  "EleniZazani" "sjgknight" "bodongchen" "cteplovs" ...
##  $ reply_to    : chr  NA NA NA NA ...
##  $ retweet_from: chr  NA "sbskmi" NA NA ...
##  $ links       : chr  "http://t.co/GfIVItBc74" "http://t.co/baQ8yNlZqV" "http://t.co/DObfNWwmcs" "http://t.co/H6kJET9w2t" ...
```


Start from Easy Stuff: Count Things
----------------------

### Count tweets, retweets (by), and replies (to) for each user

Regular statuses, retweets, and replies are three main types of tweets we analyze. The `GetTweetCountTable` function can easily count total tweets sent by a user, times of retweeting by other users, and number of replies a user has received.


```r
require(ggplot2)
require(reshape2)

# Count tables
countTweets <- GetTweetCountTable(df, "from_user")
countRetweets <- GetTweetCountTable(df, "retweet_from")
countReplies <- GetTweetCountTable(df, "reply_to")

# quickly check distribution of tweets per user
qplot(countTweets$count, binwidth = 1, xlab = "Number of Tweets")
```

![plot of chunk counttables](figure/counttables1.png) 

```r

# combine counts into one data frame
counts <- merge(countTweets, countRetweets, by = "user", all.x = TRUE)
counts <- merge(counts, countReplies, by = "user", all.x = TRUE)
colnames(counts) <- c("user", "tweets", "replied_to", "retweeted_by")
counts[is.na(counts)] <- 0

# melt data
counts.melt <- melt(counts, id.vars = c("user"))

# plot (Cleveland dot plot)
ggplot(counts.melt, aes(x = user, y = value, color = variable)) + geom_point() + 
    coord_flip() + ggtitle("Counts of tweets, retweets, and messages") + xlab("Counts") + 
    ylab("Users")
```

![plot of chunk counttables](figure/counttables2.png) 


### Ratio of retweets to tweets

To get a sense how received or valued one's tweets were within the community, we can further count the ratio of being retweeted by other users to sent tweets.


```r
# create new column 'ratio'
counts$ratio <- counts$retweeted_by/counts$tweets

# plot ratio for users who have at least one rt
ggplot(counts[counts$retweeted_by > 0, ], aes(x = reorder(user, ratio), y = ratio)) + 
    geom_point() + coord_flip() + ggtitle("Ratio of retweets to tweets") + xlab("Users") + 
    ylab("Retweets/Tweets ratio")
```

![plot of chunk ratio](figure/ratio.png) 


### Count URLs

URLs embedded in tweets are important because they usually link to important resources that are of interest to this community.


```r
# count links
countLinks <- GetTweetCountTable(df, "links")
names(countLinks)[1] <- "url"

# check top links
head(countLinks[with(countLinks, order(-count)), ])
```

```
##                       url count
## 1   https://t.co/1hj1FrD8    11
## 2   https://t.co/8Di8QcKz     7
## 3 https://t.co/EgtjcKoU6a     6
## 4 https://t.co/jscpxQpfNA     4
## 5 https://t.co/LnZsOCNFNs     3
## 6 https://t.co/rD8rtO05XV     3
```

```r

# plot to see distribution of links
ggplot(countLinks[countLinks$count > 1, ], aes(reorder(url, count), count)) + 
    geom_point() + coord_flip() + xlab("URL") + ylab("Number of messages containing the URL")
```

![plot of chunk counturls](figure/counturls.png) 



Social Network Analysis (SNA)
------------------------

### Visualize social networks

An archived tweet dataset contains `retweeting` and `replying` as two main type of links among users. Some studies looks into `following` relations, which require further queries to Twitter. So in this demo, we focus on `retweeting` and `replying` links.

The `CreateSNADataFrame` function in `social_analysis.R` provides an easy way to create a data frame containing all edges of the requested social network. With created edges, we can easily create an SNA graph and visualize it with packages like `igraph` and `sna`.


```r
# load source file first
source("social_analysis.R")

# create data frame
rt.df <- CreateSNADataFrame(df, from = "from_user", to = "retweet_from", linkNames = "rt")
rp.df <- CreateSNADataFrame(df, from = "from_user", to = "reply_to", linkNames = "rp")

# begin social network analysis plotting
require(igraph)
require(sna)
require(Matrix)
require(SparseM)

# create graph data frame (igraph)
g <- graph.data.frame(rt.df, directed = TRUE)

# plot with igraph (quick and dirty)
plot.igraph(g)
```

![plot of chunk sna](figure/sna1.png) 

```r

# plot with sna get adjacency matrix
mat <- get.adjacency(g)
# convert to csr matrix provided by SparseM ref:
# http://cos.name/cn/topic/108758
mat.csr <- as.matrix.csr(mat, ncol = ncol(mat))

# plot with sna
gplot(mat.csr)
```

![plot of chunk sna](figure/sna2.png) 


### Basic SNA measures

We can further compute some basic SNA measures. For instance, density of this network is 0.0312, reciprocity of users in the network is 0.9412, and degree centralization of this network is 0.2405. These measures are calculated as below.


```r
# density
gden(mat.csr)
```

```
## [1] 0.03119
```

```r

# reciprocity
grecip(mat.csr)
```

```
##    Mut 
## 0.9412
```

```r

# centralization
centralization(mat.csr, sna::degree)
```

```
## [1] 0.2405
```


### Community detection

A regular task in SNA is to identify communities in a network. We can do it through the `walktrap.community` function in `igraph` package.


```r
g.wc <- walktrap.community(g, steps = 1000, modularity = TRUE)

# number of communities
length(g.wc)
```

```
## [1] 4
```

```r
# sizes of communities
sizes(g.wc)
```

```
## Community sizes
##  1  2  3  4 
##  5 25  2  2
```

```r
# plot
plot(as.dendrogram(g.wc))
```

![plot of chunk detectcommunity](figure/detectcommunity.png) 


We have detected 4 communities in this network. The largest community contains 51.02% of all users in this dataset.

### Univariate Conditional Uniform Graph Tests

In network analysis, people do types of tests to check whether some aspects of a network are *unusual*. We can do such tests, namely *conditional uniform graph tests*, through the `cug.test` function in the `sna` package. Further information about these tests can be found [here](http://artax.karlin.mff.cuni.cz/r-help/library/sna/html/cug.test.html).


```r
# density
cug.gden <- cug.test(mat.csr, gden)
plot(cug.gden)
```

![plot of chunk cug](figure/cug1.png) 

```r
range(cug.gden$rep.stat)
```

```
## [1] 0.4510 0.5419
```

```r

# reciprocity
cug.recip <- cug.test(mat.csr, grecip)
plot(cug.recip)
```

![plot of chunk cug](figure/cug2.png) 

```r
range(cug.recip$rep.stat)
```

```
## [1] 0.4332 0.5615
```

```r

# transistivity
cug.gtrans <- cug.test(mat.csr, gtrans)
plot(cug.gtrans)
```

![plot of chunk cug](figure/cug3.png) 

```r
range(cug.gtrans$rep.stat)
```

```
## [1] 0.4485 0.5477
```

```r

# centralisation
cug.cent <- cug.test(mat.csr, centralization, FUN.arg = list(FUN = degree))
plot(cug.cent)
```

![plot of chunk cug](figure/cug4.png) 

```r
range(cug.cent$rep.stat)
```

```
## [1] 0.0625 0.2585
```



Semantic Analysis
------------------------

### Words

Firstly, make a word cloud.


```r
# load source file first
source("semantic_analysis.R")

# construct corpus, with regular preprocessing performed
corpus <- ConstructCorpus(df$text, removeTags = TRUE, removeUsers = TRUE)

# make a word cloud
MakeWordCloud(corpus)
```

![plot of chunk wordcloud](figure/wordcloud.png) 


This task first uses `ConstructCorpus` in `semantic_analysis.R` to create a text corpus, and then uses `MakeWordCloud` to make a word cloud. Please note that `ConstructCorpus` provides a number of options such as whether to remove hashtags (#tag) or users (@user) embedded in tweets.

Next we are going to create a term-document matrix for some quick similarity computation.


```r
# create a term document matrix only keep tokens longer than three
# characters
td.mat <- TermDocumentMatrix(corpus, control = list(minWordLength = 3))
# have a quick look
td.mat
```

```
## A term-document matrix (272 terms, 101 documents)
## 
## Non-/sparse entries: 704/26768
## Sparsity           : 97%
## Maximal term length: 23 
## Weighting          : term frequency (tf)
```

```r

# frequent words
findFreqTerms(td.mat, lowfreq = 10)
```

```
##  [1] "activity"   "analytics"  "analyzing"  "canvas"     "capturing" 
##  [6] "course"     "data"       "discussion" "evidence"   "feedback"  
## [11] "fritz"      "john"       "join"       "learning"   "min"       
## [16] "network"    "peer"       "recipes"    "scale"      "tools"     
## [21] "using"
```

```r

# find related words of a word
findAssocs(td.mat, "learning", 0.5)
```

```
##       min analytics  feedback     fritz      peer     scale      join 
##      0.78      0.73      0.64      0.64      0.64      0.64      0.60 
##     using 
##      0.54
```


For more advanced similarity computation among documents and terms, I am considering adding Latent Semantic Analysis (LSA) capability into this package in the future.

### Topic modelling with Latent Dirichlet Allocation (LDA)

With the sparse term-document matrix created above, we can use the `TrainLDAModel` function in `semantic_analysis.R` to train a LDA model. (Note: I don't understand all of steps in the code in `TrainLDAModel` refactored from [Ben Marwick's repo](https://github.com/benmarwick/AAA2011-Tweets). So please help to check it if you understand LDA.) This step may take a while depending on the size of the dataset.


```r
# timing start
ptm <- proc.time()

# generate a LDA model
lda <- TrainLDAModel(td.mat)

# time used
proc.time() - ptm
```

```
##    user  system elapsed 
## 122.000   0.012 122.561
```


ThiS LDA model contains 24 topics. We can check keywords in each topic, get relevant topics of each tweet, and compute similarity scores among tweets based on topics they are related to.


```r
# get keywords for each topic
lda_terms <- get_terms(lda, 5)
# look at the first 5 topics
lda_terms[, 1:5]
```

```
##      Topic 1        Topic 2     Topic 3     Topic 4      Topic 5    
## [1,] "contribution" "session"   "john"      "assignment" "data"     
## [2,] "dont"         "data"      "research"  "data"       "analysis" 
## [3,] "evidence"     "education" "session"   "expensive"  "pandas"   
## [4,] "maybe"        "matters"   "available" "human"      "using"    
## [5,] "meaningful"   "owns"      "python"    "mining"     "available"
```

```r

# gets topic numbers per document
lda_topics <- get_topics(lda, 5)
# look at the first 10 documents
lda_topics[, 1:10]
```

```
##       1  2  3  4 5  6  7  8  9 10
## [1,] 20 16 14 11 5  2 16 16 16  8
## [2,] 24  1  5 17 1 10  1  1  2  2
## [3,] 19  2  1 22 3  1  2  2  3  5
## [4,]  1  3  2  1 6  3  3  3  5  4
## [5,]  2  5  3  2 7  4  5  5  6  1
```

```r

# compute similarity between two documents
CosineSimilarity(lda_topics[, 1], lda_topics[, 10])
```

```
##        [,1]
## [1,] 0.8042
```

```r

# computer a similarity matrix of documents
sim.mat <- sapply(1:ncol(lda_topics), function(i) {
    sapply(1:ncol(lda_topics), function(j) CosineSimilarity(lda_topics[, i], 
        lda_topics[, j]))
})

# find most relevant tweets for a tweet
index <- 1
ids <- which(sim.mat[, index] > quantile(sim.mat[, index], 0.9))
sim.doc.df <- data.frame(id = ids, sim = sim.mat[, index][ids])
sim.doc.df <- sim.doc.df[with(sim.doc.df, order(-sim)), ]
# indices of most relevant tweets
head(sim.doc.df$id)
```

```
## [1]  1 63 73  4 50 58
```


### Sentiment Analysis

This project implements three methods (with one method that depends on *ViralHeat* not working) of analyzing sentiment of tweets. Let's try function `ScoreSentiment` in `sentiment_analysis.R` implemented based on [this post](http://jeffreybreen.wordpress.com/2011/07/04/twitter-text-mining-r-slides/).


```r
# compute sentiment scores for all tweets
scores <- ScoreSentiment(df$text, .progress = "text")

# plot scores
ggplot(scores, aes(x = score)) + geom_histogram(binwidth = 1) + xlab("Sentiment score") + 
    ylab("Frequency") + ggtitle("Sentiment Analysis of Tweets")
```

![plot of chunk sentiment](figure/sentiment1.png) 

```r

scores <- scores[with(scores, order(-score)), ]
# check happy tweets
as.character(head(scores$text, 3))
# check unhappy tweets
as.character(tail(scores$text, 3))

# check sentiment scores of tweets containing certain words create subset
# based on tweets with certain words, e.g., learning
scores.sub <- subset(scores, regexpr("learning", scores$text) > 0)
# plot histogram for this token
ggplot(scores.sub, aes(x = score)) + geom_histogram(binwidth = 1) + xlab("Sentiment score for the token 'learning'") + 
    ylab("Frequency")
```

![plot of chunk sentiment](figure/sentiment2.png) 


Sentiment analysis with the `sentiment`  package.


```r
scores2 <- ScoreSentiment2(df$text)

# plot scores. scale_x_log10 is used because the score is based on log
# likelihood
ggplot(scores2, aes(x = score)) + geom_histogram() + xlab("Sentiment score") + 
    ylab("Frequency") + ggtitle("Sentiment Analysis of Tweets") + scale_x_log10()
```

![plot of chunk sentiment2](figure/sentiment21.png) 

```r

# plot emotion
qplot(scores2$emotion)
```

![plot of chunk sentiment2](figure/sentiment22.png) 

```r

# plot most likely sentiment category
qplot(scores2$best_fit)
```

![plot of chunk sentiment2](figure/sentiment23.png) 


We can further check whether these two scores are correlated.


```r
# put them into one data frame
scores3 <- data.frame(score1 = scores$score, score2 = scores2$score)

# scatterplot with regression line
ggplot(scores3, aes(x = score1, y = score2)) + geom_point() + stat_smooth(method = "lm") + 
    xlab("Score by counting words") + ylab("Score from sentiment package")
```

![plot of chunk sentimentcompare](figure/sentimentcompare.png) 



Finally, this project is at its early stage. If you are interested, please fork [twitter-hashtag-analytics](https://github.com/dirkchen/twitter-hashtag-analytics) on Github.
