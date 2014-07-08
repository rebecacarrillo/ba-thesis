# Crawler in R (Didn't End up Using)
# Rebeca Carrillo Clayton, 2014
# University of Chicago/BA Thesis

getData <- function(url){
  #function to download data in json format
  require(rjson)
  raw.data <- readLines(url, warn="F") 
  rd  <- fromJSON(raw.data)
  rd.views <- rd$daily_views 
  rd.views <- unlist(rd.views)
  rd <- as.data.frame(rd.views)
  rd$date <- rownames(rd)
  rownames(rd) <- NULL
  return(rd)
}


getUrls <- function(y1,y2,term){
  #function to create a list of urls given a term and a start and endpoint
  urls <- NULL
  for (year in y1:y2){
    for (month in 1:9){
      urls <- c(urls,(paste("http://google.com/json/en/",year,0,month,"/",term,sep="")))
    }
    
    for (month in 10:12){
      urls <- c(urls,(paste("http://google.ocm/json/en/",year,month,"/",term,sep="")))
    }
  }
  return(urls)
}

getStats <- function(y1,y2,terms){
  #function to download data for each term
  #returns a dataframe
  output <- NULL
  for (term in terms){
    urls <- getUrls(y1,y2,term)
    
    results <- NULL
    for (url in urls){
      print(url)
      results <- rbind(results,getData(url))
    }
    results$term <- term
    
    output <- rbind(output,results)
  }
  return(output)
}

