################################################################################

################################################################################

# Author:       Felix Gutmann
# Programm:     Barcelona graduate school of economics - M.S. Data Science 
# Course:       14D007 Data Visualization
# Last update:  11.04.2016

# Decription:   This file computes 

################################################################################
### Preamble
################################################################################

### Clear workspace
rm(list = ls())

### Load data
setwd('/Users/felix/Documents/GSE/Term 2/14D007 Data Visualization/Project/Data-Visualisation-2015/Literature and data/raw_data/')
iot          <- read.csv( 'iot_clean.csv', sep = ';', header = FALSE )
sector       <- read.csv( 'product_groups_clean.csv', sep = ';', header = FALSE )
value.added  <- read.csv( 'value_added_clean.csv', sep = ';', header = FALSE )
employment   <- read.csv( 'labour_input_clean.csv',sep = ';',header=FALSE )
final.demand <- read.csv( 'final_demand_clean.csv',sep = ';',header=FALSE )
### Load Packages 

### Set options
options( useFancyQuotes = FALSE )

### Initialize auxilliary functions
setwd('/Users/felix/Documents/GSE/Term 2/14D007 Data Visualization/Project/Data-Visualisation-2015/Analysis/')
source('centrality_functions.R')

################################################################################
# Compute centrality meassures for IO-Graph
################################################################################

# Convert data frame to class matrix and delete column names
N   <- nrow( iot )

# Compute binary adjacency matrix and both in and outlist
adjacency.matrix <- ifelse( iot > 0 , 1 , 0 )
in.list          <- colSums(adjacency.matrix)
out.list         <- rowSums(adjacency.matrix)

# Find unconnected and absorbing nodes 
zero      <- which( out.list == 0 & in.list == 0 )
absorbing <- which( out.list  < 2 & in.list  > 0 )
drops     <- c( zero, absorbing )

# Clean IOT - Drop found sectors
all.sectors <- 1:N
keeps       <- setdiff( all.sectors , drops )
iot.clean   <- as.matrix( iot[ keeps , keeps ] )

# Compute centrality meassures
rwclose <- random.walk.closeness.centrality(iot.clean)
rwcount <- random.walk.counting.centrality(iot.clean)

# Adjust output - Assign zero for 
rw.closeness <- c( )
rw.counting  <- c( ) 
drop.counter <- drops
i <- 1
j <- 1
while ( i < ( N + 1)  ) {
  
  bool <- i == drop.counter
  
  if( any( bool ) ){
    pos <- which( bool == i )
    drop.counter <- setdiff( drop.counter, drop.counter[pos] )
    rw.closeness[i] <- 0
    rw.counting[i]  <- 0
  } else {
    rw.closeness[i] <- rwclose[j]
    rw.counting[i]  <- rwcount[j]
    j <- j + 1
  }
    i <- i+1
}

################################################################################
# Covert data to d3 format
################################################################################

# Initialize empty node list
node.list <- c( )

# Compute and format nodes
for( i in 1:N ){
  
node.list[i] <- ifelse( i < N, 
  paste0('{ name:',sQuote(sector[i,1]),',nor:',10,
         ',clo:',rw.closeness[i] * 1000 ,',cou:',rw.counting[i],
         ',em:',employment[1,i],',va:',value.added[1,i] ,',fd:', final.demand[1,i] , '},'),
  paste0('{ name:',sQuote(sector[i,1]),',nor:',10,
         ',clo:',rw.closeness[i] * 1000,',cou:',rw.counting[i],
         ',em:',employment[1,i],',va:',value.added[1,i] ,',fd:', final.demand[1,i] ,'}')
  )
  
}

# Remove quotes
node.list <- noquote(node.list)

# Initialize empty edge list
edge.list <- c(NA)

# Compute edge list for java script
for( i in 1:N){
    
  # Compute out list for node i
  temp.out.list <- adjacency.matrix[i,]
  
    # Loop over adjacent nodes j of node i
    for( j in 1:N ){
      
      # If there is an edge append to list
      if(  temp.out.list[j] != 0 ){
        
        edge <- paste0('{ source:',(i-1),', target:',(j-1),'},')
        current.index <- length(edge.list) + 1 
        edge.list[current.index] <- edge
        
        }
      
    }
  
  # Last iteration add no comma 
  if( i == N ){ 
    last.index <- current.index - 1
    edge.list[last.index] <- paste0('{ source:',(i-1),', target:',(j-1),'}') 
    edge.list <- edge.list[2:last.index]
    }
}

# Design final output
open   <- "var dataset = { nodes: ["
bridge <-  "],edges: ["
close  <- "]};"
graph  <- noquote( c( open , node.list , bridge , edge.list , close ) )

################################################################################

################################################################################

# Reset working directory for output
setwd( '/Users/felix/Documents/GSE/Term 2/14D007 Data Visualization/Project/Data-Visualisation-2015/Literature and data/web_data/' )

# Save data to HD
write( graph , 'graph_data.js' )

################################################################################

################################################################################