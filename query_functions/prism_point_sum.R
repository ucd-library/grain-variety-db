#' Sum of PRISM weather data at a given point within California for a given date 
#' range
#' 
#' \code{prism_point_sum} returns the sum of the PRISM tiles that intersect with 
#' the given point over the given date range for the given the data type.
#'
#' This function is written to work with the Grain Cropping Systems database at 
#' UC Davis. A DBI connection to the database labeled "con" must be present in 
#' the Global Environment. Example below:
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
#'
#' @param lat The latitude of the point of interest as a number. Must be within CA.
#' @param long The longitue of the point of interest as a number. Must be within CA.
#' @param from_date The start date of interest as "YYYY-MM-DD" character format 
#' (data not available before 2012 currently)
#' @param to_date The end date of interest as "YYYY-MM-DD" character format
#' (data not available before 2012 currently)
#' @param type Either "ppt", "tmin", or "tmax" are available

#' @return a single numeric output of the sum. 
#'

#' @examples
#' prism_point_sum(lat = 38.533867, long = -121.771598, from_date = "2019-10-01", to_date = "2019-12-01", type = "ppt")

prism_point_sum <- function(lat, long, from_date, to_date, type){
	return(dbGetQuery(con, paste0("SELECT SUM(ST_Value(rast, ST_SetSRID(ST_Point(", long, ", ", lat, "), 4326))) FROM prism WHERE measurement = '", type, "'AND date BETWEEN CAST('", from_date, "' AS DATE) AND CAST('", to_date, "' AS DATE);"))$sum)
}