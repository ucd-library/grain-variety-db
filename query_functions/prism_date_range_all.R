#' PRISM weather data at a given point within California for a given date 
#' range
#' 
#' \code{prism_date_range_all} returns the daily values of the PRISM 
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
#' (data not available before 2009 currently)
#' @param to_date The end date of interest as "YYYY-MM-DD" character format 
#' (data not available before 2009 currently)
#' 
#' @return a data.frame object with daily values for the given date range 
#'
#'
#' @examples
#' prism_date_range_all(con = con, lat = 38.533867, long = -121.771598, from_date = "2019-10-01", to_date = "2019-12-01")

prism_date_range_all <- function(con, lat, long, from_date, to_date){
	
	source("C:/Users/LundyAdmin/Documents/grain-variety-db/query_functions/gdd_to_nuptake.R")
	daily_data <- DBI::dbGetQuery(con, paste0(
		"WITH point as (
			SELECT (ST_WorldToRasterCoord(rast,", long, ",", lat, ")).* from prism limit 1)
			SELECT date,
			EXTRACT(MONTH FROM date) AS month,
			EXTRACT(DAY FROM date) AS day,
			measurement,
			ST_Value(rast, point.columnx, point.rowy) AS amount
			FROM
			prism, point
			WHERE date BETWEEN CAST('", from_date, "' AS DATE) AND CAST('", to_date, "' AS DATE);"))
	
	daily_output <- daily_data %>% 
		spread(key = measurement, value = amount) %>% 
		arrange(date) %>% 
		mutate(tmax = (tmax* 9/5) + 32,
					 tmin = (tmin* 9/5) + 32,
					 gdd = ifelse(tmax<45, 0,
					 						 ifelse(tmin > 86, tmax - tmin,
					 						 			 ifelse(tmax<86,ifelse(tmin<45,
					 						 			 											(6*(tmax-45)^2)/
					 						 			 												(tmax-
					 						 			 												 	tmin)/12,
					 						 			 											((tmax+
					 						 			 													tmin-2*45)*6/12)),
					 						 			 			 ((6*(tmax+tmin-2*45)/12)-
					 						 			 			  	((6*(tmax-86)^2)/
					 						 			 			  	 	(tmax-tmin))/12)
					 						 			 ))),
					 gdd_cumsum = cumsum(gdd),
					 nuptake_perc = gdd_to_nuptake(gdd_cumsum))
	
	return(daily_output)
	
}






