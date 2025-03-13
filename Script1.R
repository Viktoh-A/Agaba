##Install the needed packages -----------------
install.packages("RSelenium")
install.packages("wdman")
install.packages("jsonlite")
install.packages("httr")
install.packages("rvest")
install.packages("dplyr")

##Laoding the Necessary packages -----------------
library(RSelenium)
library(wdman)
library(jsonlite)
library(httr)
library(rvest)
library(dplyr)

packageVersion("RSelenium")

# Define Firefox options (Capabilities)
browser_capabilities <- list(
  browserName = "firefox",
  "moz:firefoxOptions" = list(
    args = c('--headless')  # Run Firefox in headless mode (optional)
  )
)

# Start the Selenium Server
selenium_server <- rsDriver(
  browser = "firefox",
  geckover = "latest",
)


# get the driver client object
driver <- selenium_server$client
driver$open()

# navigate to the destination page
driver$navigate("https://www.autotrader.co.uk/car-search?postcode=BL36BA&advertising-location=at_cars&page=1")

Sys.sleep(5)  # Wait for the page to load


## Scroll through the page to ensure all listings are loaded
scroll_script <- "window.scrollTo(0, document.body.scrollHeight);"  # Scroll to the bottom of the page

page <- 1  # Start page count
last_count <- 0  # Track number of elements

repeat {
  print(paste("Scrolling page", page, "..."))
  
  # Scroll to the bottom
  driver$executeScript(scroll_script)
  Sys.sleep(10)  # Wait for content to load
  
  # Get all product links
  li_elements <- driver$findElements(using = "css selector", "li.at__sc-mddoqs-1.exqhQE a, li.at__sc-mddoqs-1.ieAGGj a")
  new_count <- length(li_elements)
  
  href_links <- lapply(li_elements, function(li) {
    # Get the href attribute
    href <- li$getElementAttribute("href")[[1]]
    
    # If href is NULL or empty, return NA or skip
    if (is.null(href) || href == "") {
      return(NA)
    } else {
      return(href)
    }
  })
  
  # Get the first unique link
  href_links <- unique(href_links)
  
  # Print the number of unique links
  print(paste("Page", page, "collected", length(href_links), "unique links"))
  
  # Stop if no new elements load
  if (new_count == last_count) {
    print("No more new products. Stopping scrolling.")
    break
  }
  
  last_count <- new_count  # Update element count
  page <- page + 1  # Increment page count
}


# Print the extracted links
print(href_links)

# Initialize an empty data frame to store car details
car_data <- data.frame(Name = character(), Description = character(), Year = character(), Price = character(), Mileage = character(), Fuel = character(), Engine = character(), Gear = character(), stringsAsFactors = FALSE)

# Loop through each car link


for (link in href_links) {
  # Navigate to the car details page
  driver$navigate(link)
  Sys.sleep(10)  # Wait for the page to load
  
  # Initialize variables to store extracted data, defaulting to NA
  product_name <- NA
  product_desc <- NA
  product_year <- NA
  product_price <- NA
  product_mileage <- NA
  product_fuel <- NA
  engine_type <- NA
  gear_type <- NA
  
  
  # Wait for the page to load completely (you may need to adjust this selector)
  tryCatch({
    # Explicit wait for product name
    # Explicit wait for product name
    product_name_element <- tryCatch({
      driver$findElement(using = "css selector", ".at__sc-1n64n0d-3")
    }, error = function(e) NULL)
    if (!is.null(product_name_element)) {
      product_name <- product_name_element$getElementText()[[1]]
    }
    
    
    # Explicit wait for product description
    product_desc_element <- tryCatch({
      driver$findElement(using = "xpath", "/html/body/div[3]/main/div/section/section[1]/section/section[2]/section/section[1]/p")
    }, error = function(e) NULL)
    if (!is.null(product_name_element)) {
      product_name <- product_name_element$getElementText()[[1]]
    }
    
    
    # Explicit wait for product Year
    product_year_element <- tryCatch({
      driver$findElement(using = "css selector", "dl.at__sc-6lr8b9-1:nth-child(1) > div:nth-child(2) > span:nth-child(2)")
    }, error = function(e) NULL)
    if (!is.null(product_year_element)) {
      product_year <- product_year_element$getElementText()[[1]]
    }
    
    # Explicit wait for product Price
    product_price_element <- tryCatch({
      driver$findElement(using = "css selector", ".at__sc-6sdn0z-2")
    }, error = function(e) NULL)
    if (!is.null(product_price_element)) {
      product_price <- product_price_element$getElementText()[[1]]
    }
    
    # Explicit wait for product Mileage
    product_mileage_element <- tryCatch({
      driver$findElement(using = "css selector", ".at__sc-efqqw2-2")
    }, error = function(e) NULL)
    if (!is.null(product_mileage_element)) {
      product_mileage <- product_mileage_element$getElementText()[[1]]
    }
    
    # Explicit wait for Fuel Type
    product_fuel_element <- tryCatch({
      driver$findElement(using = "css selector", "dl.at__sc-6lr8b9-1:nth-child(1) > div:nth-child(4) > span:nth-child(2)")
    }, error = function(e) NULL)
    if (!is.null(product_fuel_element)) {
      product_fuel <- product_fuel_element$getElementText()[[1]]
    }
    
    # Explicit wait for Engine Type
    engine_type_element <- tryCatch({
      driver$findElement(using = "xpath", "/html/body/div[3]/main/div/section/section[2]/section[2]/section/dl[1]/div[5]")
    }, error = function(e) NULL)
    if (!is.null(engine_type_element)) {
      engine_type <- engine_type_element$getElementText()[[1]]
    }
    
    # Explicit wait for Gearbox Type
    gear_type_element <- tryCatch({
      driver$findElement(using = "xpath", "/html/body/div[3]/main/div/section/section[2]/section[2]/section/dl[2]/div[1]")
    }, error = function(e) NULL)
    if (!is.null(gear_type_element)) {
      gear_type <- gear_type_element$getElementText()[[1]]
    }
    
    # Append the extracted data to the data frame
    car_data <- rbind(car_data, data.frame(
      Name = product_name,
      Description = product_desc,
      Year = product_year,
      Price = product_price,
      Mileage = product_mileage,
      Fuel = product_fuel,
      Engine = engine_type,
      Gear = gear_type,
      stringsAsFactors = FALSE
    ))
    
  }, error = function(e) {
    message("Error: ", e)
  })
  
  Sys.sleep(10)  # Wait for the page to reload after extracting data
}

# Print the final data frame
print(product_data)


# Print the final data frame
print(car_data)
View(car_data)
# Assuming car_data is your data frame
write.csv(car_data, "C:/Users/-/OneDrive - University of Bolton/Documents/selenium-r-demo/car_data.csv", row.names = FALSE, quote = TRUE)
# close the Selenium client and the server
driver$close()
selenium_server$server$stop()
