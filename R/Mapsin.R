# Maps-In : Function
## Read in shp of roads, municiaplities, 
# and streets to create maps of Mex 
# assumes shapefiles in the same directory
# (I'll put this into a 
# bigger program later)

library(rgeos)
library(maptools)
library(ggplot2)
library(plyr)



# Read in shp of roads, municiaplities, 
# and streets to create maps of Mex 
# assumes shapefiles in the same directory 

# Map of Roads

map_roads <-readShapeSpatial("MEX_rds/MEX_roads.shp")

# Map of municipalities
map_muni <-readShapeSpatial("shapefiles/shps/national/national_municipal.shp")

map_st <- readShapeSpatial("shapefiles/shps/national/national_estatal.shp")
plot(map_st)