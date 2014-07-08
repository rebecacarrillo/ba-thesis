# Target is to generate a graph file in gexf format (http://gexf.net/format) for Gephi

#-----------------------------------------------------
# STEP 1
# Generate nodes and edgelist from each email log file
#-----------------------------------------------------



# use sqldf for operations suited for db http://code.google.com/p/sqldf/
library(sqldf)

# define utility functions
object.sizes <- function(obs=ls(envir=.GlobalEnv)){return(rev(sort(sapply(obs, function (object.name) object.size(get(object.name))))))}

# Create an empty data frame from a header list
empty.df<- function(header){
  df<-data.frame(matrix(matrix(rep(1,length(header)),1),1))
  colnames(df)<-header
  return(df[NULL,])
}

# break down large data problem into smaller ones
max_rows<-200000

filelist<-c("zetascombolist.csv")
# data format in the email logs is as below
# date  from_address	from_name	to_address	to_name
# 12-12-2009	john_doe@gmail.com	John Doe	jane_smith@hotmail.com	Jane Smith

for(k in 1:length(filelist)){
  system.time(zetas<-read.csv(filelist[k],sep="\t",header=T,strip.white=TRUE))
  
  
  # filenames for collecting nodes and edges
  node_file<-paste("nodes",k,"-",filelist[k],sep="")
  edge_file<-paste("edges",k,"-",filelist[k],sep="")
  
  # get to_nodes in "node_id, node_label" format
  to_nodes<-zetas[c(-1,-2)]
  # get from_nodes in "node_id, node_label" format
  from_nodes<-zetas[c(-1,-2)]
  # get edgelist in "from_node_id, to_node_id" format
  edgelist<-zetas[c(-1,-3)]
  
  # change column names for rbind
  colnames(to_nodes)<-c("id","name") 
  colnames(from_nodes)<-c("id","name") 
  
  all_nodes<-rbind(to_nodes,from_nodes) 
  
  # convert all nodes and edgelist to lowercase... using SQL
  system.time(all_nodes_lowercase<-sqldf('SELECT LOWER(id) uid, LOWER(name) label FROM all_nodes'))
  system.time(edgelist_lowercase<-sqldf('SELECT LOWER(Originator) originator, LOWER(Recipient) recipient FROM edgelist'))
  
  unique_nodes<-unique(all_nodes_lowercase)
  sorted_unique_nodes<- unique_nodes[order(unique_nodes[,1]),]
  
  write.csv(sorted_unique_nodes, file = node_file, row.names=FALSE, quote = FALSE)
  
  num_blocks<-ceiling(nrow(edgelist_lowercase)/max_rows)
  start_row<-0
  
  edgecount <- empty.df(c("originator","recipient","count(1)"))
  
  for(i in 1:num_blocks){ 
    sql_statement<-paste('select originator, recipient, count(1) FROM (select originator, recipient FROM edgelist_lowercase LIMIT ', start_row, ',', max_rows, ') group by originator, recipient order by originator, recipient') 
    print(system.time(counts<-sqldf(sql_statement)))
    
    edgecount<- rbind(edgecount, counts)
    start_row<-start_row + max_rows
  } 
  
  system.time(sqldf("create index edgecount1 on edgecount (originator, recipient)"))
  system.time(final_edgecount <- sqldf("select originator, recipient, sum(count_1_) FROM edgecount group by originator, recipient order by originator, recipient"))
  
  write.csv(final_edgecount, file = edge_file, row.names=FALSE, quote = FALSE)
}


#----------------------------------------------------------------------
# STEP 2
# Combine node and edgelist files into one large node and edgelist file
#----------------------------------------------------------------------

all_file_nodes <- empty.df(c("id","label"))
all_file_edges <- empty.df(c("originator","recipient", "sum.count_1_."))

for(k in 1:length(filelist)){
  node_file<-paste("nodes",k,"-",filelist[k],sep="")
  edge_file<-paste("edges",k,"-",filelist[k],sep="")
  
  # read each node file and rbind with all_file_nodes
  system.time(nodes<-read.csv(node_file,sep=",",header=T,strip.white=TRUE))
  all_file_nodes <- rbind(all_file_nodes, nodes)
  
  # read each edge file and rbind with all_file_edges
  system.time(edges<-read.csv(edge_file,sep=",",header=T,strip.white=TRUE))
  all_file_edges <- rbind(all_file_edges, edges)
}

unique_all_file_nodes<-unique(all_file_nodes)
sorted_unique_all_file_nodes<- unique_all_file_nodes[order(unique_all_file_nodes[,1]),]

# write nodes in this form --- <node id="0" label="Hello" />
nodexml<-paste("<node id=\"", sorted_unique_all_file_nodes[,1], "\"", " label=\"", sorted_unique_all_file_nodes[,2],"\""," />", sep="")
write.csv(as.data.frame(nodexml, optional=TRUE), file = "All Nodes.txt", quote = FALSE, row.names = FALSE)

# edge operations
# use pragma table_info to see the table attributes to use in sum sql below
# sqldf("pragma table_info(all_file_edges)")
unique_all_file_edges<-sqldf('select originator, recipient, sum(sum_count_1__) FROM all_file_edges group by originator, recipient order by sum(sum_count_1__)') 
nrow(unique_all_file_edges)

# filter out edges with wt 0 to 2
thicker_edges<-unique_all_file_edges[unique_all_file_edges[,3]>3,]

# write edges in this form --- <edge id="0" source="0" target="1" type="directed" weight="2.4" /> 
edgelistxml<-paste("<edge id=\"", rownames(thicker_edges), "\" ", "source=\"", thicker_edges[,1], "\" target=\"", thicker_edges[,2], "\" weight=\"", thicker_edges[,3], "\"/>", sep="") 

# write edges for gexf file. Convert to data.frame to prevent printing the column name 
write.csv(as.data.frame(edgelistxml, optional=TRUE), file = "All Edges.txt", quote = FALSE, row.names = FALSE)