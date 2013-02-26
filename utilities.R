

TrimAt <- function(x) {
  # remove @ from text
  sub('@', '', x)
}

TrimHead <- function(x) {
  # remove starting @, .@, RT @, MT @, etc.
  
  sub('^(.*)?@', '', x)
}

TrimUsers <- function(x) {
  # remove users, i.e. "@user", in a tweet
  
  str_replace_all(x, '(@[[:alnum:]_]*)', '')
}

TrimHashtags <- function(x) {
  # remove hashtags, i.e. "#tag", in a tweet
  
  str_replace_all(x, '(#[[:alnum:]_]*)', '')
}

TrimUrls <- function(x) {
  # remove urls in a tweet
  
  str_replace_all(x, 'http[^[:blank:]]+', '')
}

TrimOddChar <- function(x) {
  # remove odd charactors
  iconv(x, to = 'UTF-8')
}

CosineSimilarity <- function(va, vb) {
  # Computer cosine similarity between two numeric vectors of the same length
  
  crossprod(va, vb) / sqrt(crossprod(va) * crossprod(vb))
}