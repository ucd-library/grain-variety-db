#' historical PRISM data at a given point within California as a daily average of 
#' the 10 years previous to the current date starting at the date given and 
#' ending at June 30 (for wheat seasonality)
#' 
#' \code{prism_historical_season} returns the average daily values of the PRISM 
#' tiles that intersect with the given point over the previous 10 years starting
#' with the given month and day until June 30th given the data type.
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
#' @param type Either "ppt", "tmin", or "tmax" are available
#' 
#' @return a data.frame object with average historical daily values for the 
#' chosen variable from the given date to the June 30th output as month, day,
#' and amount
#'
#'
#' @examples
#' prism_historical_season(con = con, lat = 38.533867, long = -121.771598, type = "ppt")

prism_historical_season <- function(con, lat, long, type){
	
	historical <- DBI::dbGetQuery(con, paste0(
		"WITH point as (
	SELECT (ST_WorldToRasterCoord(rast,", long, ", ", lat, ")).* from prism limit 1
	)
		SELECT EXTRACT(MONTH FROM date) AS month,
		EXTRACT(DAY FROM date) AS day,
		AVG(ST_Value(rast, point.columnx, point.rowy)) AS amount
		FROM 
		prism, point 
		WHERE measurement = '", type, "' 
		AND date BETWEEN (CURRENT_DATE - INTERVAL '11 year') AND (CURRENT_DATE - INTERVAL '1 year')
		AND EXTRACT(MONTH FROM date) IN (10, 11, 12, 1, 2, 3, 4, 5, 6) 
		GROUP BY 
		month, day
		ORDER BY
		month, day;"))
	
	
	return(historical)
	
}
