

RemoveOddChars <- function(df) {
  # Remove odd characters in tweets
  
  source('utilities.R')
  df$text <- sapply(df$text, function(x) TrimOddChar(x))
  return(df)
}

ExtractUserInfo <- function(df) {
  # For each tweet, extract information related to users
  # such as to_user, rt_user...
  
  source('utilities.R')
  # extract to_user
  df$to <- sapply(df$text, function(tweet) 
    TrimHead(str_extract(tweet,"^((\\.)?(@[[:alnum:]_]*))")))
  # extract rt_user
  df$rt <- sapply(df$text, function(tweet) 
    TrimHead(str_extract(tweet,"^[RM]T (@[[:alnum:]_]*)")))
  
  return(df)
}

AnonymizeUsers <- function(df) {
  # Anonymize users, by creating random numbers for each user
  #
  # Args:
  #   df: data frame of tweets
  #
  # Returns:
  #   new data frame with a new column containing ids
  
  # find out how many random numbers we need
  n <- length(unique(df$screenName))
  # generate a vector of random number to replace the names
  # we'll get four digits just for convenience
  randuser <- round(runif(n, 1000, 9999),0)
  # match up a random number to a username
  screenName <- unique(df$screenName)
  screenName <- sapply(screenName, as.character)
  randuser <- cbind(randuser, screenName)
  # merge the random numbers with the rest of the Twitter data
  # and match up the correct random numbers with multiple instances of the usernames
  rand.df  <-  merge(randuser, df, by="screenName")
  
  return(rand.df)
}