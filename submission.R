# This is an example script to generate the outcome variable given the input dataset.
# 
# This script should be modified to prepare your own submission that predicts 
# the outcome for the benchmark challenge by changing the clean_df and predict_outcomes function.
# 
# The predict_outcomes function takes a data frame. The return value must
# be a data frame with two columns: nomem_encr and outcome. The nomem_encr column
# should contain the nomem_encr column from the input data frame. The outcome
# column should contain the predicted outcome for each nomem_encr. The outcome
# should be 0 (no child) or 1 (having a child).
# 
# clean_df should be used to clean (preprocess) the data.
# 
# run.R can be used to test your submission.

# List your packages here. Don't forget to update packages.R!
library(dplyr) # as an example, not used here

clean_df <- function(df, background_df=NULL){
  # Preprocess the input dataframe to feed the model.
  ### If no cleaning is done (e.g. if all the cleaning is done in a pipeline) leave only the "return df" command
  
  # Parameters:
  # df (dataframe): The input dataframe containing the raw data (from PreFer_train_data.csv).
  # background (dataframe): Optional input dataframe containing background data (from PreFer_train_background_data.csv).
  
  # Returns:
  # data frame: The cleaned dataframe with only the necessary columns and processed variables.
  
  ## This script contains a bare minimum working example
  # Create new age variable
  df$age <- 2024 - df$birthyear_bg
  
  # Filter cases for whom outcome is not available
  df <- df[ !is.na(df$new_child), ]
  
  # Selecting variables for modelling
  keepcols = c('nomem_encr', # ID variable required for predictions,
               'age',        # newly created variable
               'new_child',
               'cv20l247',
               'cv09b016',
               'cv19k023',
               'cr18k079',
               'cf13f004',
               'ca16e087',
               'cs14g104',
               'cs14g124',
               "cf20m068"
               )  # outcome variable 
  
  
  
  ## Keeping data with variables selected
  df <- df[ , keepcols ]
  
  return(df)
}

predict_outcomes <- function(df, background_df = NULL, model_path = "./model.rds"){
  # Generate predictions using the saved model and the input dataframe.
    
  # The predict_outcomes function accepts a dataframe as an argument
  # and returns a new dataframe with two columns: nomem_encr and
  # prediction. The nomem_encr column in the new dataframe replicates the
  # corresponding column from the input dataframe The prediction
  # column contains predictions for each corresponding nomem_encr. Each
  # prediction is represented as a binary value: '0' indicates that the
  # individual did not have a child during 2021-2023, while '1' implies that
  # they did.
  
  # Parameters:
  # df (dataframe): The data dataframe for which predictions are to be made.
  # df (dataframe): The background data dataframe for which predictions are to be made.
  # model_path (str): The path to the saved model file (which is the output of training.R).

  # Returns:
  # dataframe: A dataframe containing the identifiers and their corresponding predictions.
  
  ## This script contains a bare minimum working example
  if( !("nomem_encr" %in% colnames(df)) ) {
    warning("The identifier variable 'nomem_encr' should be in the dataset")
  }

  # Load the model
  model <- readRDS(model_path)
    
  # Preprocess the fake / holdout data
  df <- clean_df(df, background_df)

  # IMPORTANT: the outcome `new_child` should NOT be in the data from this point onwards
  # get list of variables *without* the outcome:
  vars_without_outcome <- colnames(df)[colnames(df) != "new_child"]
  
  # Generate predictions from model, should be 0 (no child) or 1 (had child)
  predictions <- predict(model, 
                         subset(df, select = vars_without_outcome), 
                         type = "response") 
  # Transform probabilities into predicted classes
  predictions <- ifelse(predictions > 0.5, 1, 0)  
  
  # Output file should be data.frame with two columns, nomem_enc and predictions
  df_predict <- data.frame("nomem_encr" = df[ , "nomem_encr" ], "prediction" = predictions)
  # Force columnnames (overrides names that may be given by `predict`)
  names(df_predict) <- c("nomem_encr", "prediction") 
  
  # Return only dataset with predictions and identifier
  return( df_predict )
}
