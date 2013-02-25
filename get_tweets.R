# Methods of retrieving tweets

library(twitteR)

GetTweetsBySearch <- function(term, n = 1500) {
  # Get tweets by searching Twitter API
  # 
  # Args: 
  #   term: search term (e.g., #education)
  #
  # Returns:
  #   Data frame containing tweets
  
  results <- searchTwitter(term, n)
  df <- do.call("rbind", lapply(results, as.data.frame))
  return(df)
}

GetTweetsFromCSV <- function(file) {
  # Get tweets from a csv file
  # 
  # Args: 
  #   file: file name, with path
  #
  # Returns:
  #   Data frame containing tweets
  
  df <- read.csv(file, stringsAsFactors = FALSE)
  # may need addtional handling here
  return(df)
}

GetTweetsFromGoogleDrive <- function(key, gid = 82) {
  # Get tweets from Google Spreadsheet
  # For how to archive tweets in Google Spreadsheet, read:
  # http://mashe.hawksey.info/2013/02/twitter-archive-tagsv5/
  #
  # Args:
  #   key: file key
  #   gid: grid id of archive sheet
  #
  # Returns:
  #   Data frame containing tweets
  
  url <- paste(sep="", 'https://docs.google.com/spreadsheet/pub?key=', key, 
               '&single=true&gid=', gid, '&output=csv')
  conn <- textConnection(getURL(url))
  df <- read.csv(conn, stringsAsFactors = FALSE)
  close(conn)
  
  return(df)
}