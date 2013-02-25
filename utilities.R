

TrimAt <- function(x) {
  # remove @ from text
  sub('@', '', x)
}

TrimHead <- function(x) {
  # remove starting @, .@, RT @, MT @, etc.
  
  sub('^(.*)?@', '', x)
}

TrimOddChar <- function(x) {
  # remove odd charactors
  iconv(x, to = 'UTF-8')
}