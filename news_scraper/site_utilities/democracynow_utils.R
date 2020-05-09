# This one's kinda weird. Democracy Now does have archives up to the day going back until 1996. Thing is they are all on one page. 
# This means the find link function doesn't have a purpose here, so really its getting skipped
# It does mean this is probably one of the easiest sites we could scrape
# However this doesn't filter for language, our scraper will need to do that

# Support functions that allow democracynow to be scraped. There should only be function definitions in this file, nothing that gets executed

# 1: Returns ~a list of links where we can find links~ to news articles for the last x months
## For this its https://www.democracynow.org/sitemap_blog.xml, and the links we want are at the tail end of that list of links
democracynow_sitemap  <- function(last_x_months){
  
  locs        <- GET("https://www.democracynow.org/sitemap_blog.xml") %>% read_html 
  
  f <- data.table(link       = {html_nodes(locs,"loc")        %>% html_text},
                  lastmod    = {html_nodes(locs,"lastmod")    %>% html_text %>% as.Date},
                  changefreq = {html_nodes(locs,"changefreq") %>% html_text},
                  priority   = {html_nodes(locs,"priority")   %>% html_text})
  
  f[, filed_under := "Not Applicable"]
  # Slightly gimmicky workaround, the main function is going to expect a list to be output.
  f <- list(f)
  return(f) 
  
}


# 2: Given the results of the last function, visit each sitemap link and get a list of article links
democracynow_find_links <- function(link){
  # Not necessary, every link on one page
  return(link)
}

# 3: Given the link to an article, visit it, collect data, return the data as a list or data.table
democracynow_article <- function(link){
  
  # Double check the right packages are loaded again for each worker when multi-threading
  suppressMessages(suppressWarnings({
    require(magrittr)
    require(dplyr)
    require(data.table)
    require(rvest)
    require(httr)
    require(stringr)
    require(lubridate)
    require(furrr)
  }))
  
  
  
  response <- GET(link) 
  
  
  # Use try() for more error catching (i.e. bad link, connection timeout, coding error, etc.)
  ## Create a list of results to return if collection fails
  results <- data.table(article_date     = NA,
                        article_headline = NA,
                        article_author   = NA,
                        article_source   = NA,
                        article_tag      = NA,
                        article_text     = NA,
                        http_status_code = response[["status_code"]])
  ## Attempt to collect data from the page, return results as a data.table with 1 row
  try({
    # Actual data collection
    article <- response %>% read_html()
    # filter out anything not in English
    if(html_attr(article,"lang") == "en"){
      
      results <- data.table(article_date     = {article %>% html_node(".date")  %>% html_text %>% str_trim  %>% str_c(collapse = "\n")},
                            article_headline = {article %>% html_node(".container-fluid > h1")    %>% html_text %>% str_trim %>% str_c(collapse = "\n") %>% first},
                            article_author   = {article %>% html_node(".story_summary > .text > p > strong")  %>% html_text   %>% str_trim  %>% str_c(collapse = "\n")},
                            article_source   = {"DemocracyNow"},
                            article_tag      = {article %>% html_nodes('a[data-ga-action="Story: Topic"]') %>% html_text %>% unique %>% str_trim %>% str_c(collapse = ", ")},
                            article_text     = {article %>% html_nodes(".story_summary > .text > p")  %>% .[-1] %>% html_text   %>% str_trim  %>% str_c(collapse = "\n")},
                            http_status_code = response[["status_code"]]) %>% .[1,]
      
      if(length(results$article_text) == 0){results$article_text   <- NA}
      
    }else{
      results <- data.table(article_date     = NA,
                            article_headline = NA,
                            article_author   = NA,
                            article_source   = NA,
                            article_tag      = NA,
                            article_text     = NA,
                            http_status_code = "NotEnglishLang")
    }
    

    
  },silent = TRUE)
  
  
  return(results)
  
}
