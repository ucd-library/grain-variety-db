#' PRISM weather data at a given point within California for a given date 
#' range
#' 
#' \code{prism_date_range} returns the daily values of the PRISM 
#' tiles that intersect with the given point over the given date range for the
#' given the data type.
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
#' @param con A database connection
#' @param lat The latitude of the point of interest as a number. Must be within CA.
#' @param long The longitue of the point of interest as a number. Must be within CA.
#' @param from_date The start date of interest as "YYYY-MM-DD" character format
#' (data not available before 2012 currently)
#' @param to_date The end date of interest as "YYYY-MM-DD" character format 
#' (data not available before 2012 currently)
#' @param type Either "ppt", "tmin", or "tmax" are available
#' 
#' @return a data.frame object with daily values for chosen variable 
#' for given date range 
#'
#'
#' @examples
#' prism_date_range(con = con, lat = 38.533867, long = -121.771598, from_date = "2019-10-01", to_date = "2019-12-01", type = "ppt")

prism_date_range <- function(con, lat, long, from_date, to_date, type){
	
	daily_data <- DBI::dbGetQuery(con, paste0(
		"SELECT date, 
		EXTRACT(MONTH FROM date) AS month, 
		EXTRACT(DAY FROM date) AS day,
		ST_Value(rast, ST_SetSRID(ST_Point(", long, ", ", lat, "), 4326)) AS amount
		FROM prism 
		WHERE measurement = '", type, "' 
		AND date BETWEEN CAST('", from_date, "' AS DATE) AND CAST('", to_date, "' AS DATE);"))
	
	return(daily_data)
	
}