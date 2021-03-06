## Make naive predictions with benchmark model, and calculate error measures
## for consumer datasets
## Author: Michael Kostmann


# Clear global environment
rm(list=ls())

# Source user-defined functions
functions = c("FUN_getData.R",
              "FUN_getTargets.R",
              "FUN_calcErrorMeasure.R")
invisible(lapply(functions, source))

# Set path of directory containing datasets
path      = "../data/consumer/"

# Set index to number between 1 and 100 to select individual dataset
# If all consumer datasets should be used, set index to -26
files     = list.files(path, pattern = "*.csv")[-26]


# Generate vector of column names
col_ids   = paste0("c", substring(files, 15, 17), "_cons")

# Load data
input     = getData(path   = path,
                    data   = "all",
                    return = "consumption")

# Initialize progress bar
pb = txtProgressBar(min = 0, max = length(files), style = 3)

# Loop over all data sets specified in files
for(i in (1:length(files))){
    
    # Get naive prediction (benchmark model)
    temp = input %&gt;%
        filter_time("2017-10-01 00:03:00" ~ "2018-01-01") %&gt;%
        mutate(time_aggr = collapse_index(index      = time,
                                          period     = "15 minutely",
                                          side       = "end",
                                          start_date =
                                              as_datetime(min(time),
                                                          tz = "CET"))) %&gt;%
        group_by(time_aggr) %&gt;%
        summarise(prediction = sum(!!sym(col_ids[i]))) %&gt;%
        pull(prediction)
    
    # Correct last aggregation value
    temp[(length(temp)-1)] = temp[(length(temp)-1)] + temp[length(temp)]
    temp                   = temp[-length(temp)]
    
    # Shift by one period
    naive_predictions = c(NA, temp[-length(temp)])
    
    # Get true values
    targets = getTargets(path   = path,
                         id     = substring(files[i], 1, 17),
                         return = "consumption",
                         min    = "2017-10-01 00:03",
                         max    = "2018-01-01 00:00")
    
    # Write error measures of naive prediction into list
    if(!exists("error_measures")) {error_measures = list()}
    error_measures[[col_ids[i]]] =
        calcErrorMeasure(predictions = naive_predictions[-1],
                         targets     = targets[-1],
                         return      = "all")
    
    # Save predictions to dataframe
    if(!exists("naive_all_predictions")) {
        naive_all_predictions = matrix(NA,
                                       nrow = length(naive_predictions),
                                       ncol = length(files))
    }
    naive_all_predictions[, i] = naive_predictions
    
    # Progress
    setTxtProgressBar(pb, i)
}

# Save error measures
save(error_measures, file = "output/consumer/naive_error_measures.RData")

# Save predictions for all datasets to csv-file
write.csv(naive_all_predictions, "output/consumer/naive_predictions.csv")




###############################################################################




## Make naive predictions with benchmark model, and calculate error measures
## for prosumer datasets


# Clear global environment except for functions
rm(list = setdiff(ls(), lsf.str()))

# Set path to directory containing datasets
path      = "../data/prosumer/"

# Set index to number between 1 and 100 to select individual dataset
files     = list.files(path,
                       pattern = "*.csv")[c(19, 24, 26, 30, 31, 72,
                                            75, 83, 84, 85, 86, 89)]

# Generate vector of column names
col_ids   = paste0("p", substring(files, 15, 17), "_prod")

# Load data
input     = getData(path   = path,
                    data   = "all",
                    return = "production")[c( 1, 20, 25, 27, 31, 32, 73,
                                              76, 84, 85, 86, 87, 90)]

# Initialize progress bar
pb = txtProgressBar(min = 0, max = length(files), style = 3)

# Loop over all data sets specified in files
for(i in (1:length(files))){
    
    # Get naive prediction (benchmark model)
    temp = input %&gt;%
        filter_time("2017-10-01 00:03:00" ~ "2018-01-01") %&gt;%
        mutate(time_aggr = collapse_index(index      = time,
                                          period     = "15 minutely",
                                          side       = "end",
                                          start_date =
                                              as_datetime(min(time),
                                                          tz = "CET"))) %&gt;%
        group_by(time_aggr) %&gt;%
        summarise(prediction = sum(!!sym(col_ids[i]))) %&gt;%
        pull(prediction)
    
    # Correct last aggregation value
    temp[(length(temp)-1)] = temp[(length(temp)-1)] + temp[length(temp)]
    temp                   = temp[-length(temp)]
    
    # Shift by one period
    naive_predictions = c(NA, temp[-length(temp)])
    
    # Get true values
    targets = getTargets(path   = path,
                         id     = substring(files[i], 1, 17),
                         return = "production",
                         min    = "2017-10-01 00:03",
                         max    = "2018-01-01 00:00")
    
    # Write error measures of naive prediction into list
    if(!exists("error_measures")) {error_measures = list()}
    error_measures[[col_ids[i]]] =
        calcErrorMeasure(predictions = naive_predictions[-1],
                         targets     = targets[-1],
                         return      = "all")
    
    # Save predictions to dataframe
    if(!exists("naive_all_predictions")) {
        naive_all_predictions = matrix(NA,
                                       nrow = length(naive_predictions),
                                       ncol = length(files))
    }
    naive_all_predictions[, i] = naive_predictions
    
    # Progress
    setTxtProgressBar(pb, i)
}

# Save error measures
save(error_measures, file = "output/prosumer/naive_error_measures.RData")

# Save predictions for all datasets to csv-file
write.csv(naive_all_predictions, "output/prosumer/naive_predictions.csv")


## end of file ##
