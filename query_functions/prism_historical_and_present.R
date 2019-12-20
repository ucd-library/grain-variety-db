#' Sum of PRISM weather data at a given point within California for a given date 
#' range
#' 
#' \code{prism_historical_and_present} returns the daily values of the PRISM 
#' tiles that intersect with the given point over the given date range for the
#' given the data type as well as the average historical 
#' (past 10 years from current year) value, and the cumulative sum of over both 
#' the present and historical date range.
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
#' @param to_date The end date of interest as "YYYY-MM-DD" character format
#' @param type Either "ppt", "tmin", or "tmax" are available

#' @return a data.frame object with daily values (present) for chosen variable 
#' for given date range (date, month, day), the average daily value for the 10
#'  years previous to the current date (historical), and the cumulative sum of 
#'  both the present (present_cumsum) and historical data (historical_cumsum).
#'

#' @examples
#' prism_historical_and_present(lat = 38.533867, long = -121.771598, from_date = "2019-10-01", to_date = "2019-12-01", type = "ppt")

prism_historical_and_present <- function(lat, long, from_date, to_date, type){
	
	from_hist <- paste(lubridate::year(as.Date(Sys.Date())) - 10, lubridate::month(as.Date(from_date)), lubridate::day(as.Date(from_date)), sep = "-")
	to_hist <- paste(lubridate::year(as.Date(Sys.Date())) - 1, lubridate::month(as.Date(to_date)), lubridate::day(as.Date(to_date)), sep = "-")
	
	present <- DBI::dbGetQuery(con, paste0(
		"SELECT date, 
		EXTRACT(MONTH FROM date) AS month, 
		EXTRACT(DAY FROM date) AS day,
		ST_Value(rast, ST_SetSRID(ST_Point(", long, ", ", lat, "), 4326)) AS present
		FROM prism 
		WHERE measurement = '", type, "' 
		AND date BETWEEN CAST('", from_date, "' AS DATE) AND CAST('", to_date, "' AS DATE);"))
	
	historical <- DBI::dbGetQuery(con, paste0(
		"SELECT EXTRACT(MONTH FROM date) AS month, 
		EXTRACT(DAY FROM date) AS day,
		AVG(ST_Value(rast, ST_SetSRID(ST_Point(", long, ", ", lat, "), 4326))) AS historical
		FROM 
		prism 
		WHERE measurement = '", type, "' 
		AND date BETWEEN CAST('", from_hist, "' AS DATE) AND CAST('", to_hist, "' AS DATE) 
		AND EXTRACT(MONTH FROM date) BETWEEN ", lubridate::month(from_date), " AND ", lubridate::month(to_date),
		" GROUP BY 
		month, day
		ORDER BY
		month, day;"))
	
	df <- inner_join(present, historical) %>% 
		mutate(present_cumsum = cumsum(present),
					 historical_cumsum = cumsum(historical))
	
	return(df)
	
}