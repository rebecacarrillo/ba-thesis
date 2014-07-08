# gephicrawl

library(XML)
library(scales)
library(reshape)
library(gridExtra)
library(SPARQL)

# Create the query
qq <- 'SELECT * WHERE { ?p a <http://dbpedia.org/ontology/Philosopher> . ?p <http://dbpedia.org/ontology/influenced> ?influenced. }'

# Use it in SPARQL
data <- SPARQL(url='http://dbpedia.org/sparql',query=qq)

# Make it directed
orig <- unlist(data$results[[2]], use.names=F)
dest <- unlist(data$results[[1]], use.names=F)

# Turn URLs into handsome names
for (x in seq(1,length(orig))) {
  orig[x] <- gsub("^<+|>+$","", orig[x])
  orig[x] <- tail(strsplit(orig[x],'/')[[1]],1)
  orig[x] <- URLdecode(orig[x])
  orig[x] <- gsub("_"," ", orig[x])
}
for (x in seq(1,length(dest))) {
  dest[x] <- gsub("^<+|>+$","", dest[x])
  dest[x] <- tail(strsplit(dest[x],'/')[[1]],1)
  dest[x] <- URLdecode(dest[x])
  dest[x] <- gsub("_"," ", dest[x])
}

# Format it as an edge graph.
edges <- data.frame(cbind(as.matrix(orig),as.matrix(dest), rep(1,length(orig))), stringsAsFactors=F)

# Rename data fields to gephi-friendly things
names(edges) <- c('Source', 'Target', 'Weight')

# Clean up Aristotle: These names were on the "List of People Influenced by Aristotle" page
## You can cut out this Aristotle fixup section and it still works
I_by_Aristotle<- c("Francis Bacon",
                   "Franco Burgersdijck",
                   "Nicolaus Copernicus",
                   "René Descartes",
                   "Georg Wilhelm Friedrich Hegel",
                   "Thomas Hobbes",
                   "Immanuel Kant",
                   "Jean-Jacques Rousseau",
                   "Baruch Spinoza",
                   "Mortimer Adler",
                   "Hannah Arendt",
                   "Philippa Foot",
                   "Hans-Georg Gadamer",
                   "Martin Heidegger",
                   "Muhammad Iqbal",
                   "James Joyce",
                   "Alasdair MacIntyre",
                   "Jacques Maritain",
                   "Martha Nussbaum",
                   "Leo Strauss")
# If someone Aristotle influenced doesn't already have a node, drop them.
present <- unique(orig[(orig %in% I_by_Aristotle)])
I_by_Aristotle <- I_by_Aristotle[(I_by_Aristotle %in% present)]
for (i in seq(1,length(I_by_Aristotle))){
  edges <- data.frame(rbind(edges, c(I_by_Aristotle[i], 'Aristotle', 1)), stringsAsFactors=F)
}
## End of Aristotle fixup section

# Write the file
write.csv(edges,file="Edge_file.csv", row.names=F)