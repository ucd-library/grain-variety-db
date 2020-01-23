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
#' @param from_date The start date of interest as "YYYY-MM-DD" character format
#'  (data not available before 2012 currently)
#' @param type Either "ppt", "tmin", or "tmax" are available
#' 
#' @return a data.frame object with average historical daily values for the 
#' chosen variable from the given date to the June 30th output as month, day,
#' and amount
#'
#'
#' @examples
#' prism_historical_season(con = con, lat = 38.533867, long = -121.771598, from_date = "2019-10-01", type = "ppt")

prism_historical_season <- function(con, lat, long, from_date, type){
	
	from_hist <- paste(lubridate::year(as.Date(Sys.Date())) - 10, lubridate::month(as.Date(from_date)), lubridate::day(as.Date(from_date)), sep = "-")
	to_hist <- paste(lubridate::year(as.Date(Sys.Date())) - 1, 6, 30, sep = "-")
	
	if(lubridate::month(as.Date(from_date)) > 9) {
		months <- lubridate::month(seq(as.Date(from_date), as.Date(paste(lubridate::year(as.Date(from_date)) +1, 6, 30, sep = "-")), by = "month"))
	} else {
		months <- lubridate::month(seq(as.Date(from_date), as.Date(paste(lubridate::year(as.Date(from_date)), 6, 30, sep = "-")), by = "month"))
	}
	
	months <- paste(months, collapse = ", ")
	
	historical <- DBI::dbGetQuery(con, paste0(
		"SELECT EXTRACT(MONTH FROM date) AS month, 
		EXTRACT(DAY FROM date) AS day,
		AVG(ST_Value(rast, ST_SetSRID(ST_Point(", long, ", ", lat, "), 4326))) AS amount
		FROM 
		prism 
		WHERE measurement = '", type, "' 
		AND date BETWEEN CAST('", from_hist, "' AS DATE) AND CAST('", to_hist, "' AS DATE) 
		AND EXTRACT(MONTH FROM date) IN (", months, ") 
		GROUP BY 
		month, day
		ORDER BY
		month, day;"))
	
	return(historical)
	
}
