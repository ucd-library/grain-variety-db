#' historical PRISM data at a given point within California as a daily average of 
#' the 10 years previous to the current date starting at the date given and 
#' ending at June 30 (for wheat seasonality)
#' 
#' \code{prism_historical_season_all} returns the average daily values of the PRISM 
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
#' 
#' @return a data.frame object with average historical daily values for the 
#' chosen variable from the given date to the June 30th output as month, day,
#' and amount
#'
#'
#' @examples
#' prism_historical_season_all(con = con, lat = 38.533867, long = -121.771598)

prism_historical_season_all <- function(con, lat, long){
	
	source("C:/Users/LundyAdmin/Documents/grain-variety-db/query_functions/gdd_to_nuptake.R")
	
	historical <- DBI::dbGetQuery(con, paste0(
		"WITH point as (
	SELECT (ST_WorldToRasterCoord(rast,", long, ", ", lat, ")).* from prism limit 1
	)
		SELECT EXTRACT(MONTH FROM date) AS month,
		EXTRACT(DAY FROM date) AS day,
		measurement,
		AVG(ST_Value(rast, point.columnx, point.rowy)) AS amount
		FROM 
		prism, point 
		WHERE date BETWEEN (CURRENT_DATE - INTERVAL '11 year') AND (CURRENT_DATE - INTERVAL '1 year')
		AND EXTRACT(MONTH FROM date) IN (10, 11, 12, 1, 2, 3, 4, 5, 6) 
		GROUP BY 
		measurement, month, day
		ORDER BY
		month, day, measurement;"))
	
	historical_output <- historical %>% 
		spread(key = measurement, value = amount) %>% 
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
					 pseudo_date = if_else(month > 9, 
					 											as.Date(paste("2018", month, day, sep = "-")), 
					 											as.Date(paste("2019", month, day, sep = "-")))) %>% 
		arrange(pseudo_date) %>% 
		mutate(gdd_cumsum = cumsum(gdd),
					 nuptake_perc = gdd_to_nuptake(gdd_cumsum)) %>% 
		select(-pseudo_date)
	
	return(historical_output)
	
}
