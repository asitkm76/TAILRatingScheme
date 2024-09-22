# Preamble ----------------------------------------------------------------
# list and load required packages
package.list <- (c(
  "ggplot2", "ggpubr", "tidyr", 
  "dplyr", "readxl", "tibble", 
  "xlsx", "reshape2", "multcomp", "car", 
  "tidyverse", "caret", "plyr", "GGally",
  "corrgram", "gridExtra", "RColorBrewer", 
  "ggthemes", "corrplot", "ggcorrplot",
  "lubridate", "ggformula", "ggalt", 
  "see", "gghalves", "ggpol", "ggforce"))

# load packages
lapply(package.list, require, character.only = TRUE)

# set the working directory
# change this as per your system directory
setwd("C:/Users/akumis/Downloads")

# define the TAIL analysis function------

perform_TAILanalysis <- function(building_df) {
  # Extract building name from the dataframe
  building_name <- unique(building_df$Building)
  
  # Ensure there's only one building name in the dataframe
  if (length(building_name) != 1) {
    stop("Dataframe contains multiple buildings. 
	Please ensure each dataframe contains only one building.")
  }
  
  # Ensure Date_Time is in the correct format
  # you may need to change "format" based on your data
  building_df$Date_Time <- as.POSIXct(building_df$Date_Time,
                                      format = "%d/%m/%Y %H:%M")
  
  # Filter out weekends and times outside occupancy hours 
  # in this case, for the sample office space
  # occupied hours are taken to be 9 am to 4 pm
  # change this depending on your building use
  building_df <- building_df %>%
    dplyr::filter(!weekdays(Date_Time) %in% c("Saturday", "Sunday")) %>%
    dplyr::filter(format(Date_Time, "%H") >= "09" & format(Date_Time, "%H") <= "16")
  
  # Summarize FloorArea and Occupancy of all rooms monitored
  building_summary <- building_df %>%
    distinct(Room, .keep_all = TRUE) %>%
    dplyr::summarise(
      TotalFloorArea = sum(FloorArea, na.rm = TRUE),
      TotalOccupancy = sum(Occupancy, na.rm = TRUE)
    )
  
  # Calculate ventilation limits using the floor area and occupancy
  # of space monitored in the whole building
  # Summing up the total FloorArea and Occupancy
  TotalFloorArea <- sum(building_summary$TotalFloorArea)
  TotalOccupancy <- sum(building_summary$TotalOccupancy)
  VentilationGreen <- 10 * TotalOccupancy + 2 * TotalFloorArea
  VentilationYellow <- 7 * TotalOccupancy + 1.4 * TotalFloorArea
  VentilationOrange <- 4 * TotalOccupancy + 0.8 * TotalFloorArea
  
  # Process each TAIL parameter
  # identify the unique parameters in this dataset
  unique_parameters <- unique(building_df$Variable)
  
  results <- list()
  
  for (parameter in unique_parameters) {
    clean_name <- make.names(parameter)
    
    parameter_df <- building_df %>%
      dplyr::filter(Variable == parameter)
    
    # for more information on categorization of the parameters
    # check https://www.sciencedirect.com/science/article/pii/S0378778821003133
    
    # Data processing based on parameter
    # for temperature, heating season is set based on 
    # the month during which measurement was done
    # then, based on heating or non-heating season, temperature is 
    # categorized
    if (parameter == "temperature") {
      parameter_df <- parameter_df %>% 
        mutate(Value = round(Value, 1)) %>%
        mutate(Season = ifelse(month(Date_Time) %in% c(10, 11, 12, 1,
                                                       2, 3, 4, 5), "Heating",
                               "Non-heating")) %>%
        mutate(category = case_when(
          Season == "Heating" & Value >= 21 & Value <= 23 ~ "Green",
          Season == "Heating" & (Value >= 20 & Value < 21 | Value > 23 &
                                   Value <= 24) ~ "Yellow",
          Season == "Heating" & (Value >= 19 & Value < 20 | Value > 24 &
                                   Value <= 25) ~ "Orange",
          Season == "Heating" & (Value < 19 | Value > 25) ~ "Red",
          Season == "Non-heating" & Value >= 23.5 & Value <= 25.5 ~ "Green",
          Season == "Non-heating" & (Value >= 23 & Value < 23.5 | Value > 25.5 &
                                       Value <= 26) ~ "Yellow",
          Season == "Non-heating" & (Value >= 22 & Value < 23 | Value > 26 &
                                       Value <= 27) ~ "Orange",
          Season == "Non-heating" & (Value < 22 | Value > 27) ~ "Red",
          TRUE ~ NA_character_  # Default case
        ))
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
   
    # for RH, add labels based on building type and values
    if (parameter == "RH") {
      parameter_df <- parameter_df %>% mutate(Value = ifelse(Value < 1, 
                                                             1, Value)) %>%
        mutate(Value = ifelse(Value > 100, 95, Value)) %>%
        mutate(Value = round(Value, 0))%>%
        mutate(category = case_when(
          BuildingType == "Office" & Value >= 30 & Value <= 50 ~ "Green",
          BuildingType == "Office" & (Value >= 25 & Value < 30 | Value > 50 & 
                                        Value <= 60) ~ "Yellow",
          BuildingType == "Office" & (Value >= 20 & Value < 25 | Value > 60 & 
                                        Value <= 70) ~ "Orange",
          BuildingType == "Office" & (Value < 20 | Value > 70) ~ "Red",
          BuildingType == "Hotel" & Value >= 30 & Value <= 50 ~ "Green",
          BuildingType == "Hotel" & (Value >= 25 & Value < 30 | Value > 50 & 
                                       Value <= 60) ~ "Yellow",
          BuildingType == "Hotel" & (Value >= 20 & Value < 25) ~ "Orange",
          BuildingType == "Hotel" & (Value < 20 | Value > 60) ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # for PM2.5, add labels based on WHO limits
    if (parameter == "pm25") {
      parameter_df <- parameter_df %>%
        mutate(Value = ifelse(Value < 0, NA, Value)) %>%  # Convert negative values to NA
        mutate(Value = ifelse(Value < 1, 0, Value)) %>%  # Set values under 1 to 0
        mutate(Value = round(Value, 0)) %>%  # Round to 0 decimal places
        mutate(category = case_when(
          Value < 10 ~ "Green",
          Value >= 10 & Value < 25 ~ "Yellow",
          Value >= 25 ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # for CO2, add labels based on EN16798 limits
    # the 95th percentile of the CO2 data is used for categorization
    if (parameter == "co2") {
      # co2 cannot be less that outdoor values
      # outdoor CO2 assumed to be at 420 ppm
      # adjust as required
      parameter_df <- parameter_df %>%
        mutate(Value = ifelse(Value < 420, 420, Value))
      
      # Calculate the 95th percentile for each room
      percentiles <- parameter_df %>%
        dplyr::summarise(co2_95th = quantile(Value, 0.95, na.rm = TRUE))
      
      # Add the 95th percentile value to the original dataframe
      parameter_df <- parameter_df %>%
        mutate(co2_95th = percentiles$co2_95th) %>%
        mutate(category = case_when(
          co2_95th <= 970 ~ "Green",
          co2_95th > 970 & co2_95th <= 1220 ~ "Yellow",
          co2_95th > 1220 & co2_95th <= 1770 ~ "Orange",
          co2_95th > 1770 ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)    
    }
    
    # for formalydehyde, add labels based on WHO limits
    if (parameter == "formaldehyde") {
      parameter_df <- parameter_df %>% 
        # mutate(Value = ifelse(Unit == "ppm", Value * 1228, Value)) %>%
        mutate(Value = ifelse(Value < 0, NA, Value)) %>%
        mutate(Value = ifelse(Value < 1, 0, Value)) %>%
        mutate(Value = round(Value, 0)) %>%
        mutate(category = case_when(
          Value < 30 ~ "Green",
          Value >= 30 & Value < 100 ~ "Yellow",
          Value >= 100 ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # for benzene, add labels based on WHO limits
    if (parameter == "benzene") {
      parameter_df <- parameter_df %>% 
        mutate(Value = ifelse(Value < 0, NA, Value)) %>%
        mutate(Value = ifelse(Value < 1, 0, Value)) %>%
        mutate(Value = round(Value, 0)) %>%
        mutate(category = case_when(
          Value < 2 ~ "Green",
          Value >= 2 & Value < 5 ~ "Yellow",
          Value >= 5 ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # for radon, add labels based on WHO limits
    if (parameter == "radon") {
      parameter_df <- parameter_df %>% 
        mutate(Value = ifelse(Value < 0, NA, Value)) %>%
        mutate(Value = ifelse(Value < 1, 0, Value)) %>%
        mutate(Value = round(Value, 0)) %>%
        mutate(category = case_when(
          Value < 100 ~ "Green",
          Value >= 100 & Value < 300 ~ "Yellow",
          Value >= 300 ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # for ventilation, add labels based on standard recommendation
    if (parameter == "ventilation") {
      # Round the Value and categorize based on the ventilation limits
      parameter_df <- parameter_df %>%
        mutate(Value = round(Value, 1)) %>%
        mutate(Value = ifelse(Value < 0, NA, Value)) %>%
        mutate(category = case_when(
          Value >= VentilationGreen ~ "Green",
          Value < VentilationGreen & Value >= VentilationYellow ~ "Yellow",
          Value < VentilationYellow & Value >= VentilationOrange ~ "Orange",
          Value < VentilationOrange ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # for mold, assign labels based on the observations from a 
    # manual inspection
    if (parameter == "mold") {
      parameter_df <- parameter_df %>%
        mutate(category = case_when(
          Value == "No visible mold" ~ "Green",
          Value == "Small areas visible mold, <400 cm2" ~ "Yellow",
          Value == "Slightly larger areas visible mold, <  2500 cm2" ~ "Orange",
          Value == "Large areas visible mold, > 2500 cm2" ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # noise labels are assigned based on the 5th percentile of the data
    # this is to avoid spikes of noise
    # labels depend on space type and building type
    if (parameter == "noise") {
      # noise cannot be less that lower limit of detection
      parameter_df <- parameter_df %>% mutate(Value = round(Value, 0))%>%
        mutate(Value = ifelse(Value < 30, 30, Value))
      
      # Calculate the 5th percentile for each room
      percentiles <- parameter_df %>%
        dplyr::summarise(noise_5th = quantile(Value, 0.05, na.rm = TRUE))
      
      # Join the percentiles back to the original dataframe
      parameter_df <- parameter_df %>%
        mutate(noise_5th = percentiles$noise_5th) %>%
        mutate(category = case_when(
          RoomType == "Small office" & noise_5th <= 30 ~ "Green",
          RoomType == "Small office" & (noise_5th > 30 & noise_5th <= 35) ~ "Yellow",
          RoomType == "Small office" & (noise_5th > 35 & noise_5th <= 40) ~ "Orange",
          RoomType == "Small office" & (noise_5th > 40) ~ "Red",
          RoomType == "Open office" & noise_5th <= 35 ~ "Green",
          RoomType == "Open office" & (noise_5th > 35 & noise_5th <= 40) ~ "Yellow",
          RoomType == "Open office" & (noise_5th > 40 & noise_5th <= 45) ~ "Orange",
          RoomType == "Open office" & (noise_5th > 45) ~ "Red",
          RoomType == "Hotel" &  noise_5th <= 25 ~ "Green",
          RoomType == "Hotel" & (noise_5th > 25 & noise_5th <= 30) ~ "Yellow",
          RoomType == "Hotel" & (noise_5th > 30 & noise_5th < 35) ~ "Orange",
          RoomType == "Hotel" & (noise_5th > 35) ~ "Red",
          TRUE ~ NA_character_  # Default case, if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)    
    }
    
    # illuminance labels are assigned based on fraction of time
    # levels are within specified limits
    if (parameter == "illuminance") {
      parameter_df <- parameter_df %>% mutate(Value = ifelse(Value < 30, 30, Value))
      
      # Calculate the total number of records
      total_records <- nrow(parameter_df)
      
      # Calculate percentages based on conditions for different BuildingTypes
      parameter_df <- parameter_df %>%
        mutate(category = case_when(
          # For Office
          BuildingType == "Office" & (sum(Value >= 300 & Value <= 500) / total_records * 100) > 60 ~ "Green",
          BuildingType == "Office" & (sum(Value >= 300 & Value <= 500) / total_records * 100) >= 40 &
            (sum(Value >= 300 & Value <= 500) / total_records * 100) <= 60 ~ "Yellow",
          BuildingType == "Office" & (sum(Value >= 300 & Value <= 500) / total_records * 100) >= 10 &
            (sum(Value >= 300 & Value <= 500) / total_records * 100) < 40 ~ "Orange",
          BuildingType == "Office" & (sum(Value >= 300 & Value <= 500) / total_records * 100) < 10 ~ "Red",
          
          # For Hotel
          BuildingType == "Hotel" & (sum(Value >= 100) / total_records * 100) == 0 ~ "Green",
          BuildingType == "Hotel" & (sum(Value >= 100) / total_records * 100) > 0 &
            (sum(Value >= 100) / total_records * 100) <= 50 ~ "Yellow",
          BuildingType == "Hotel" & (sum(Value >= 100) / total_records * 100) > 50 &
            (sum(Value >= 100) / total_records * 100) <= 90 ~ "Orange",
          BuildingType == "Hotel" & (sum(Value >= 100) / total_records * 100) > 90 ~ "Red",
          
          TRUE ~ NA_character_  # Default case if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # daylight factor comes from simulated data
    # it can be added to the overall dataframe, following
    # the format, for ease of calculations
    if (parameter == "daylightFactor") {
      # Assign categories
      parameter_df <- parameter_df %>%
        mutate(category = case_when(
          Value >= 5.0 ~ "Green",
          Value >= 3.3 & Value < 5.0 ~ "Yellow",
          Value >= 2.0 & Value < 3.3 ~ "Orange",
          Value < 2.0 ~ "Red",
          TRUE ~ NA_character_  # Default case if no conditions match
        ))
      # Assign the updated dataframe back to the appropriate variable
      assign(clean_name, parameter_df, envir = .GlobalEnv)
    }
    
    # Store results (e.g., labels) for later use
    results[[clean_name]] <- parameter_df
  }
  

  ## Perform label calculations (Temperature, Accoustics, IAQ, Lighting)---- 
  
  
  ### label calculation for thermal----
  
  #### label calculation for temperature----
  # Calculate frequencies of each category
  if (exists("temperature")) {
    category_freq <- temperature %>%
      dplyr::group_by(category) %>%
      dplyr::summarize(Freq = n() / nrow(temperature))
    
    # Assign TemperatureLabel based on frequencies
    temperatureLabel <- case_when(
      sum(category_freq$Freq[category_freq$category == "Green"]) >= 0.94 &
        sum(category_freq$Freq[category_freq$category == "Orange"]) <= 0.01 &
        sum(category_freq$Freq[category_freq$category == "Red"]) == 0 ~ 1,
      
      sum(category_freq$Freq[category_freq$category == "Yellow"]) > 0.05 &
        sum(category_freq$Freq[category_freq$category == "Orange"]) <= 0.05 &
        sum(category_freq$Freq[category_freq$category == "Red"]) <= 0.01 ~ 2,
      
      sum(category_freq$Freq[category_freq$category == "Orange"]) > 0.05 &
        sum(category_freq$Freq[category_freq$category == "Red"]) <= 0.05 ~ 3,
      TRUE ~ 4  # Default case
    )
  } else {
    temperatureLabel <- NA_real_  # default value, if no data
  }
  
  # Print the calculated TemperatureLabel
  # uncomment if you need to print the label on console
  # print(temperatureLabel) 
  
  # thermal label
  ThermalLabel <- temperatureLabel
  
  # Print the calculated ThermalLabel
  # uncomment if you need to print the label on console
  # print(ThermalLabel)
  
  ### label calculation for IAQ----
  
  #### label calculation for co2----
  if (exists("co2")) {
    # Assign category from the co2 dataframe
    co2_category <- unique(co2$category)
    
    # Assign final CO2 label (numeric) based on the category
    co2Label <- case_when(
      co2_category == "Green" ~ 1,
      co2_category == "Yellow" ~ 2,
      co2_category == "Orange" ~ 3,
      co2_category == "Red" ~ 4,
      TRUE ~ NA_real_  # Use NA_real_ for numeric results
    )
  } else {
    co2Label <- NA_real_  
  }
  # Display the final CO2 label
  # uncomment if you need to print the label on console
  # print(co2Label)
  
  #### label calculation for ventilation----
  if (exists("ventilation")) {
    # Assign category from the ventilation dataframe
    vent_category <- unique(ventilation$category)
    
    # Assign final ventilation label (numeric) based on the category
    ventilationLabel <- case_when(
      vent_category == "Green" ~ 1,
      vent_category == "Yellow" ~ 2,
      vent_category == "Orange" ~ 3,
      vent_category == "Red" ~ 4,
      TRUE ~ NA_real_  # Use NA_real_ for numeric results
    )
  } else {
    ventilationLabel <- NA_real_  
  }
  
  # Display the final ventilation label
  # uncomment if you need to print the label on console
  # print(ventilationLabel)
  
  #### label calculation for mold----
  if (exists("mold")) {
    if (any(mold$category == "Red")) {
      moldLabel <- 4
    } else if (any(mold$category == "Orange")) {
      moldLabel <- 3  
    } else if (any(mold$category == "Yellow")) {
      moldLabel <- 2
    } else if (all(mold$category == "Green")) {
      moldLabel <- 1
    } else {
      moldLabel <- NA_real_   # Default case if no specific conditions are met
    }
  } else {
    moldLabel <- NA_real_  # if a mold assessment was not done
  }
  
  # Display the final mold label
  # uncomment if you need to print the label on console
  # print(moldLabel)
  
  #### label calculation for RH----
  if (exists("RH")) {
    # Calculate frequencies of each category
    category_freq <- RH %>%
      dplyr::group_by(category) %>%
      dplyr::summarize(Freq = n() / nrow(RH))
    
    # Assign RHLabel based on frequencies
    RHLabel <- case_when(
      sum(category_freq$Freq[category_freq$category == "Green"]) >= 0.94 &
        sum(category_freq$Freq[category_freq$category == "Orange"]) <= 0.01 &
        sum(category_freq$Freq[category_freq$category == "Red"]) == 0 ~ 1,
      
      sum(category_freq$Freq[category_freq$category == "Yellow"]) > 0.05 &
        sum(category_freq$Freq[category_freq$category == "Orange"]) <= 0.05 &
        sum(category_freq$Freq[category_freq$category == "Red"]) <= 0.01 ~ 2,
      
      sum(category_freq$Freq[category_freq$category == "Orange"]) > 0.05 &
        sum(category_freq$Freq[category_freq$category == "Red"]) <= 0.05 ~ 3,
      
      TRUE ~ 4  # Default case
    )
  } else {
    RHLabel <- NA_real_  
  }
  # Print the calculated RHLabel
  # uncomment if you need to print the label on console
  # print(RHLabel)
  
  #### label calculation for benzene----
  if (exists("benzene")) {
    if (any(benzene$category == "Red")) {
      benzeneLabel <- 4
    } else if (any(benzene$category == "Yellow")) {
      benzeneLabel <- 2
    } else if (all(benzene$category == "Green")) {
      benzeneLabel <- 1
    } else {
      benzeneLabel <- NA_real_   # Default case if no specific conditions are met
    }
  } else {
    benzeneLabel <- NA_real_  # Assign NA if 'benzene' dataframe does not exist
  }
  # Print the calculated BenzeneLabel
  # uncomment if you need to print the label on console
  # print(benzeneLabel)
  
  #### label calculation for formaldehyde----
  if (exists("formaldehyde")) {
    if (any(formaldehyde$category == "Red")) {
      formaldehydeLabel <- 4
    } else if (any(formaldehyde$category == "Yellow")) {
      formaldehydeLabel <- 2
    } else if (all(formaldehyde$category == "Green")) {
      formaldehydeLabel <- 1
    } else {
      formaldehydeLabel <- NA_real_  # Default case if no specific conditions are met
    }
  } else {
    formaldehydeLabel <- NA_real_   
  }
  # Print the calculated FormaldehydeLabel
  # uncomment if you need to print the label on console
  # print(formaldehydeLabel)
  
  #### label calculation for pm25----
  if (exists("pm25")) {
    if (any(pm25$category == "Red")) {
      pmLabel <- 4
    } else if (any(pm25$category == "Yellow")) {
      pmLabel <- 2
    } else if (all(pm25$category == "Green")) {
      pmLabel <- 1
    } else {
      pmLabel <- NA_real_   # Default case if no specific conditions are met
    }
  } else {
    pmLabel <- NA_real_   
  }  
  
  # Print the calculated pmLabel
  # uncomment if you need to print the label on console
  # print(pmLabel)
  
  #### label calculation for radon----
  if (exists("radon")) {
    if (any(radon$category == "Red")) {
      radonLabel <- 4
    } else if (any(radon$category == "Yellow")) {
      radonLabel <- 2
    } else if (all(radon$category == "Green")) {
      radonLabel <- 1
    } else {
      radonLabel <- NA_real_   # Default case if no specific conditions are met
    }
  } else {
    radonLabel <- NA_real_   
  }  
  
  # Print the calculated RadonLabel
  # uncomment if you need to print the label on console
  # print(radonLabel)
  
  #### Indoor Air quality label-----
  # Indoor air label is the worst of the indidvidual parameter labels
  IndoorAirLabel <- max(co2Label, RHLabel, benzeneLabel, formaldehydeLabel,  
                        pmLabel, radonLabel, ventilationLabel, moldLabel,
                        na.rm = TRUE)
  
  # If all values are NA, set IndoorAirLabel to NA (no IAQ parameter measured)
  if (is.infinite(IndoorAirLabel)) {
    IndoorAirLabel <- NA_real_
  }
  
  # Print the calculated IndoorAirLabel
  # uncomment if you need to print the label on console
  # print(IndoorAirLabel)
  
  ### label calculation for acoustics----
  
  #### label calculation for noise----
  if (exists("noise")) {
    # Assign category from the noise dataframe
    noise_category <- unique(noise$category)
    
    # Assign final noise label (numeric) based on the category
    noiseLabel <- case_when(
      noise_category == "Green" ~ 1,
      noise_category == "Yellow" ~ 2,
      noise_category == "Orange" ~ 3,
      noise_category == "Red" ~ 4,
      TRUE ~ NA_real_  # Use NA_real_ for numeric results
    )
  } else {
    noiseLabel <- NA_real_   # use NA if noise has not been measured
  }   
  
  # Display the final noise label
  # uncomment if you need to print the label on console
  # print(noiseLabel)
  
  AcousticLabel <- noiseLabel
  
  # Display the final acoustic label
  # uncomment if you need to print the label on console
  # print(AcousticLabel)
  
  ### label calculation for Lighting----
  
  #### label calculation for illuminance----
  if (exists("illuminance")) {
    # Assign category from the illuminance dataframe
    illuminance_category <- unique(illuminance$category)
    
    # Assign final illuminance label (numeric) based on the category
    illuminanceLabel <- case_when(
      illuminance_category == "Green" ~ 1,
      illuminance_category == "Yellow" ~ 2,
      illuminance_category == "Orange" ~ 3,
      illuminance_category == "Red" ~ 4,
      TRUE ~ NA_real_  # Use NA_real_ for numeric results
    )
  } else {
    illuminanceLabel <- NA_real_   # use NA if illuminance has not been measured
  }    
  
  # Display the final illuminance label
  # uncomment if you need to print the label on console
  # print(illuminanceLabel)
  
  #### label calculation for daylightfactor----
  if (exists("daylightFactor")) {
    # Assign category from the illuminance dataframe
    daylightFactor_category <- unique(daylightFactor$category)
    
    # Assign final illuminance label (numeric) based on the category
    daylightFactorLabel <- case_when(
      daylightFactor_category == "Green" ~ 1,
      daylightFactor_category == "Yellow" ~ 2,
      daylightFactor_category == "Orange" ~ 3,
      daylightFactor_category == "Red" ~ 4,
      TRUE ~ NA_real_  # Use NA_real_ for numeric results
    )
  } else {
    daylightFactorLabel <- NA_real_   # use NA if daylightFactor has not been measured
  }   
  # Display the final daylightFactor label
  # uncomment if you need to print the label on console
  # print(daylightFactorLabel)
  
  # Lighting label is the worst of the indidvidual parameter labels
  LightingLabel <- max(illuminanceLabel, daylightFactorLabel, na.rm = TRUE)
  
  # If all values are NA, set LightingLabel to NA
  if (is.infinite(LightingLabel)) {
    LightingLabel <- NA_real_
  }
  
  # Display the final lighting label
  # uncomment if you need to print the label on console
  # print(LightingLabel)
  
  # Final TAIL label is the worst of the indidvidual parameter labels
  TAILLabel <- max(LightingLabel, AcousticLabel, IndoorAirLabel, ThermalLabel,
                   na.rm = TRUE)
  
  # Covert the numericla value to colour
  TAIL <- switch(TAILLabel,
                 "1" = "Green",
                 "2" = "Yellow",
                 "3" = "Orange",
                 "4" = "Red",
                 NA  # Default case
  )
  
  # Convert numerical value to Roman numeral
  Tail_label <- dplyr::case_when(
    TAILLabel == 1  ~ "I",
    TAILLabel == 2  ~ "II",
    TAILLabel == 3  ~ "III",
    TAILLabel == 4  ~ "IV",
    TRUE                ~ "IV"  # Default case
  )
  
  # Create the plot
  # the plot is saved as a png file with the building name
  # file is saved to current working directory
  level <- c(rep(1, 1), rep(2, 4), rep(3, 12))
  # numbers for labels
  part <- c(TAILLabel, AcousticLabel, LightingLabel, IndoorAirLabel, ThermalLabel,
            noiseLabel, daylightFactorLabel, illuminanceLabel,
            co2Label, RHLabel, benzeneLabel, formaldehydeLabel,  
            pmLabel, radonLabel, ventilationLabel, moldLabel, temperatureLabel)
  # labels for each segment
  label <- c(Tail_label, "A", "T", "I", "L", "Noise", "Temperature", "Mold", "Vent", 
             "Radon", "PM2.5", "CH2O", "Benzene", "RH", "CO2",
             "Lux", "DF")
  
  # specify angles
  start <- c(0, 0, 90, 180, 270, 0, 90, 135,
             seq(180, 258.75, by = 11.25), 270)
  end <- c(360, 90, 180, 270, 360, 90, 135, 180, 
           seq(191.25, 270, by = 11.25), 360)
  pseudoStart <- c(0, 0, 90, 180, 270, 0, 90, 
                   seq(180, 258.75, by = 11.25), 270, 315)
  pseudoEnd <- c(360, 90, 180, 270, 360, 90, 180, 
                 seq(191.25, 270, by = 11.25), 315, 360)
  
  # create dataframe from labels, values, angles
  data <- data.frame(level = level, part = part, start = start, end = end, 
                     label = label, pseudoStart = pseudoStart, 
                     pseudoEnd = pseudoEnd)
  data$part <- factor(data$part, levels = c(1, 2, 3, 4))
  
  # create plot
  plot <- ggplot(data) + 
    geom_arc_bar(aes(x0 = 0, y0 = 0, r0 = level - 1, r = level,
                     start = start * pi/180, end = end * pi/180,
                     fill = part),
                 color = "black") +
    geom_text(aes(
      x = (level - 0.5) * cos((pseudoStart + pseudoEnd) / 2 * pi/180),  # Calculate x position
      y = (level - 0.5) * sin((pseudoStart + pseudoEnd) / 2 * pi/180),  # Calculate y position
      label = label
    ), size = ifelse(level == 1, 6, ifelse(level == 2, 4, 3)), color = "black") +
    coord_fixed() +
    theme_void() +
    theme(legend.position = "none") +
    scale_fill_manual(values = c(
      "1" = "#77dd77",   # Color for value = 1
      "2" = "#ffdd75",   # Color for value = 2
      "3" = "#ffb347",   # Color for value = 3
      "4" = "#ff6961"    # Color for value = 4
    ), na.value = "#d9d9d9") # Handle NA values
  
  # Save the plot as a JPG file in the current working directory
  plot_filename <- paste0(building_name, "_TAIL_plot.png")
  ggsave(plot_filename, plot = plot, width = 3.5, height = 3.5, dpi = 300)
  
  # Return the final results, including TAIL label
  return(list(TAIL = TAIL, TAILLabel = TAILLabel, 
              TempLabel = temperatureLabel, DFLabel = daylightFactorLabel,
              LuxLabel = illuminanceLabel, CO2Label =  co2Label, 
              RHLabel = RHLabel, BenzeneLabel = benzeneLabel, 
              FormaldehydeLabel = formaldehydeLabel, PM2.5Label = pmLabel,
              RadonLabel = radonLabel, VentilationLabel = ventilationLabel,
              MoldLabel = moldLabel, NoiseLabel= noiseLabel, results = results))
}

## read data and pre process if required----
rawData <- read.csv(file = "TAILSampleData.csv")

# Create a list of unique building names
unique_buildings <- unique(rawData$Building)

# Initialize a list to store results for all buildings
all_building_results <- list()

# Loop through each unique building and perform the analysis
for (building in unique_buildings) {
  # Subset the dataframe for the current building
  building_df <- rawData %>% dplyr::filter(Building == building)
  
  # Perform the analysis
  analysis_results <- perform_TAILanalysis(building_df)
  
  # Store the results in the list
  all_building_results[[building]] <- analysis_results
}

# Initialize a dataframe to store the results
results_df <- data.frame(Building = character(),
                         TAIL = character(),
                         TAILLabel = numeric(),
                         TempLabel = numeric(),
                         DFLabel = numeric(),
                         LuxLabel = numeric(),
                         CO2Label =  numeric(), 
                         RHLabel = numeric(),
                         BenzeneLabel = numeric(),
                         FormaldehydeLabel = numeric(), 
                         PM2.5Label = numeric(),
                         RadonLabel = numeric(),
                         VentilationLabel = numeric(),
                         MoldLabel = numeric(), 
                         NoiseLabel= numeric(),
                         stringsAsFactors = FALSE)

# Loop through all_building_results and extract TAIL and TAILLabel
for (building in names(all_building_results)) {
  TAIL <- all_building_results[[building]]$TAIL
  TAILLabel <- all_building_results[[building]]$TAILLabel
  TempLabel <- all_building_results[[building]]$TempLabel
  DFLabel <- all_building_results[[building]]$DFLabel
  LuxLabel <- all_building_results[[building]]$LuxLabel 
  CO2Label <- all_building_results[[building]]$CO2Label
  RHLabel <- all_building_results[[building]]$RHLabel
  BenzeneLabel <- all_building_results[[building]]$BenzeneLabel 
  FormaldehydeLabel <- all_building_results[[building]]$FormaldehydeLabel 
  PM2.5Label <- all_building_results[[building]]$PM2.5Label
  RadonLabel <- all_building_results[[building]]$RadonLabel
  VentilationLabel <- all_building_results[[building]]$VentilationLabel
  MoldLabel <- all_building_results[[building]]$MoldLabel 
  NoiseLabel <- all_building_results[[building]]$NoiseLabel
  
  # Append to the results dataframe
  results_df <- rbind(results_df, data.frame(Building = building,
                                             TAIL = TAIL,
                                             TAILLabel = TAILLabel,
                                             TempLabel = TempLabel,
                                             DFLabel = DFLabel,
                                             LuxLabel = LuxLabel, 
                                             CO2Label =   CO2Label, 
                                             RHLabel =  RHLabel,
                                             BenzeneLabel = BenzeneLabel, 
                                             FormaldehydeLabel = FormaldehydeLabel, 
                                             PM2.5Label = PM2.5Label,
                                             RadonLabel = RadonLabel,
                                             VentilationLabel = VentilationLabel,
                                             MoldLabel = MoldLabel, 
                                             NoiseLabel= NoiseLabel,
                                             stringsAsFactors = FALSE))
}

# Write the results (labels) dataframe to a CSV file
# file is saved to current working directory
# if a file of same name exists, you will have to confirm to overwrite it

# Define the file path
file_path <- "TAIL_Results.csv"

# Check if the file already exists
if (file.exists(file_path)) {
  # Ask for user confirmation
  overwrite <- readline(prompt = "File already exists. Do you want to overwrite it? (yes/no): ")
  
  # Check the user's response
  if (tolower(overwrite) == "yes") {
    # If user agrees, write the CSV file
    write.csv(results_df, file = file_path, row.names = FALSE)
    cat("File has been overwritten.\n")
  } else {
    cat("File was not overwritten.\n")
  }
} else {
  # If file does not exist, write the CSV file directly
  write.csv(results_df, file = file_path, row.names = FALSE)
  cat("File has been created.\n")
}


