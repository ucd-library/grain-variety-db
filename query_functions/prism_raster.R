#' PRISM weather data across CA output as a raster map
#' 
#' \code{prism_raster} returns a raster of cumulative weather data over the 
#' given date range
#'
#' This function is written to work with the Grain Cropping Systems database at 
#' UC Davis. You can connect as shown below:
#' 
#' con <- DBI::dbConnect(
#' RPostgres::Postgres(), 
#' dbname = "mldatadb",
#' host = "169.237.215.4", 
#' port = 5432,
#' user = Sys.getenv("userid"),
#' password = Sys.getenv("pwd"),
#' sslmode = 'require',
#' options="-c search_path=grain,public"
#' )
#' 
#' @import dbplyr, RPostgres, DBI
#' 
#' @param con A database connection
#' @param from_date The start date of interest as "YYYY-MM-DD" character format
#' (data not available before 2012 currently)
#' @param to_date The end date of interest as "YYYY-MM-DD" character format 
#' (data not available before 2012 currently)
#' @param type "ppt", want there to be "gdd"
#' 
#' @return raster object with cumulative sum of values over a given date range
#'
#'
#' @examples
#' prism_raster(con = con, from_date = "2019-11-22", to_date = "2020-03-15", type = 'ppt')

prism_raster <- function(con, from_date, to_date, type){
	
	info <- dbGetQuery(con, paste("SELECT st_xmax(st_envelope(rast)) as xmx, 
st_xmin(st_envelope(rast)) as xmn,
										 st_ymax(st_envelope(rast)) as ymx,
										 st_ymin(st_envelope(rast)) as ymn,
										 st_width(rast) as cols,
										 st_height(rast) as rows
										 from
										 (select st_union(rast, 'SUM') rast from prism WHERE date
										 BETWEEN CAST('", from_date, "' AS DATE) AND CAST('", to_date, "' AS DATE) AND measurement = 'ppt') as a;", sep = ""))

vals <- dbGetQuery(con, paste("SELECT unnest(st_dumpvalues(rast, 1)) as vals FROM (select st_union(rast, 'SUM') rast from
									 prism WHERE date
									  BETWEEN CAST('", from_date, "' AS DATE) AND CAST('", to_date, "' AS DATE) AND measurement = 'ppt') as a;", sep = ""))$vals


rout <- raster::raster(nrows = info$rows, ncols = info$cols, 
											 xmn = info$xmn, xmx = info$xmx, ymn = info$ymn, ymx = info$ymx,
											 crs = sp::CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"), val = vals)
return(rout)
	
}



