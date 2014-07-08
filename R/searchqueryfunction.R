# Preparation of query list for crawler 
# (disamubiguation part 1- step 1 of 3)
# 
# 
# Rebeca Carrillo Clayton, Spring 2014
# BA Thesis Code

## Note: Script assumes actor list has already been imported 
## and named "actorlist"
## 
## Correct naming protocol is necessary
## for script functionality. Variables should be 
## limited to 2 and labeled "Var1" and "Var2" respectively.

## Upon completion, both "combolist" and "URLList" should
## be written to a .csv for back-up purposes.
## Files should be Titled with naming convention [groupname]_[listidentifier]
## ex: "zetas_combolist", "zetas_URLList"
 
## Next Step (2) : Crawling URLList and parsing results 
## Step 3: Converting Results to Edgelist for input into
## analysis program



# ================================== #



library(RCurl)
library(RJSONIO)

# Generate list of all possible combinations from given list of actors.
# Note: list needs to be updated to include aliases
combolist.generator <- function(actorlist) {
  
  combolist <-expand.grid(actorlist$Var1, 
                          actorlist$Var2)
  return(combolist)
}

# (Apply combolist.generator to actor list manually if neccessary)

# Create function to convert combo list items to accetable search term
querylist <- function(a,b) {
 
  a <- toString(a)
  b <- toString(b)
  c <- " AND "
  
   
    query <- paste(a, c ,b)
    return(query)

}
  
# apply function to dataset
searchlist <- mapply (querylist, combolist$Var1, combolist$Var2, 
                      USE.NAMES = TRUE)


# convert to URLs
MakeURL <- function(query){
  
  root <- "http://news.google.com/api/json?address="
  url <- paste(root, query, "&sensor = false", sep = "")
  
  return(URLencode(url))
}

# Create index
URLList <- lapply(searchlist, MakeURL)

