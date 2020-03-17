#' historical PRISM weather data across CA output as a raster map
#' Takes a little over a min
#' 
#' \code{historical_raster} returns a average raster of cumulative weather data over the 
#' previous 10 years to date
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
#' @return raster object with an average of cumulative sum of values over a comparable historical date range
#'
#'
#' @examples
#' historical_raster(con = con, from_date = "2019-11-22", to_date = "2020-03-15", type = 'ppt')

historical_raster <- function(con = con, from_date, to_date, type){
	from_year <- as.numeric(paste0(lubridate::year(Sys.Date())-11))
	from_years <- seq(from_year, (from_year+9), by = 1)
	from_dates <- paste0(from_years, substring(from_date, 5, 10)) 
	
	date_diff <- ifelse(lubridate::year(as.Date(from_date)) == lubridate::year(as.Date(to_date)), 11, 10)
	
	to_year <- as.numeric(paste0(lubridate::year(Sys.Date())-date_diff))
	to_years <- seq(to_year, (to_year+9), by = 1)
	to_dates <- paste0(to_years, substring(to_date, 5, 10)) 
	
	dates_df <- data.frame(from_dates, to_dates)
	
	raster_list <- list()
	for (i in 1:nrow(dates_df)){
		raster_list[[i]] <- prism_raster(con = con, from_date = dates_df[i, 1], to_date = dates_df[i, 2], type = type)
	}
	
	raster_stack <- raster::stack(raster_list)
	return(raster::mean(raster_stack))
	
}
