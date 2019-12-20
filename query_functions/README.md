# R Query Functions

This folder contains functions for common and confusing queries to the UC Davis Grain Cropping Systems Database through R. Simple queries such as selecting and filtering data are best done through the dbplyr package.

## Usage

Currently each function can be used by downloading the R file and sourcing the code into the Global Environment.

```{r}
source("prism_point_sum.R")
```

## Dependencies

These functions require you to have and active connection to the Grain Cropping Systems Database.

``` {r}
# read data base login information
readRenviron("C:/Users/UserName/Documents/.Renviron")

# establish a connection
# mustbe connected to the Plant Sciences network atm (can connect through VPN)
con <- DBI::dbConnect(
	RPostgres::Postgres(), 
	dbname = "mldatadb",
	host = "169.237.215.4", 
	port = 5432,
	user = Sys.getenv("userid"),
	password = Sys.getenv("pwd"),
	sslmode = 'require',
	options="-c search_path=grain, public" # connect to the grain schema within the database
)
```