# creates the graph on the final part of our presentation

pacman::p_load(tidyverse, lubridate, magrittr)

messages <- read_csv("data/messages.csv")
messages$date %<>% mdy() %>% as_date()

messages %>% 
	ggplot(aes(x=date, y=count, fill=from)) +
	geom_bar(position = "stack", stat="identity") +
	#scale_fill_manual(values=c("Red", "Blue", "Green")) +
	ggtitle("messages sent in our discord group")
