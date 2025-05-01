# Target: Get data from 3rd graph in https://www.flightera.net/en/flight_stats
flights <- setNames(data.frame(matrix(ncol = 6, nrow = 0)),
                    c("code", "iso", "num", "location", "date", "flightCount"))

# Looking into the sites source, I realized flightera keeps all their data for
# the graphs in the same URL by querying the country code. For example:
# https://www.flightera.net/en/flight_stats?q=US
# has all the data from the United States. At 1st I thought I would acquire the
# country codes from the site itself either by scraping or manually creating a
# vector myself, but I noticed that if you try country codes not given in the
# dropdown menu such as AF for Afghanistan it works, so I might as well use a
# more complete country code list from another website & make sure we handle
# when flightera doesn't contain data for a country.

# get country codes from https://www.iban.com/country-codes
pacman::p_load(tidyverse, rvest, robotstxt, xml2)
paths_allowed("https://www.iban.com/country-codes")
page <- read_html("https://www.iban.com/country-codes")
page %>% xml2::xml_structure()
countryNames <- page %>% html_nodes("td:nth-child(1)") %>% html_text()
countryCodes <- page %>% html_nodes("td:nth-child(2)") %>% html_text()
countryISOs <- page %>% html_nodes("td:nth-child(3)") %>% html_text()
countryNums <- page %>% html_nodes("td:nth-child(4)") %>% html_text()


# get flight data for each country we can
paths_allowed("https://www.flightera.net/en/flight_stats")


for (i in 1:length(countryCodes)) {
	print(sprintf("current index: %d, country: %s", i, countryNames[i]))
	tryCatch( # inside a try catch block to handle countries w/ no data
		expr = {
			data <- readLines(paste0(
				"https://www.flightera.net/en/flight_stats?q=",
				countryCodes[i], sep=""))
			# remove everything before 2020 & split into respective years to
			# extract numbers
			data <- gsub('.*label":"2020","data":\\[', "", data)
			data2020 <- str_extract(gsub('label":"2021.*', "", data), "[^]]*")
			data2021 <- str_extract(
				gsub('.*label":"2021","data":\\[', "", data), "[^]]*")
			data2020 <- strsplit(data2020, ",")[[1]]
			data2021 <- strsplit(data2021, ",")[[1]]
			flightCount <- c(data2020, data2021)
			# get dates for date column
			date <- seq(as.Date("2020-01-01"), as.Date("2021-12-31"), by="days")
			date <- date[1:length(flightCount)]
			# make country code column
			code <- rep(countryCodes[i], length(flightCount))
			# make iso codes
			iso <- rep(countryISOs[i], length(flightCount))
			# make numeric codes
			num <- rep(countryNums[i], length(flightCount))
			# make names
			location <- rep(countryNames[i], length(flightCount))
			# add to dataframe
			flights <- rbind(flights, data.frame(
				code, iso, num, location, date, flightCount))
		},
		error = function(e) {
			#print(e)
			message(sprintf("data for %s doesn't exist", countryNames[i]))
		}
	)
}

write_csv(flights, "data/flights.csv")
