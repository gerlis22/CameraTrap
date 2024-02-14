# Load packages; install if needed along with dependencies
library(keras)
library(tensorflow)
library(data.table)
library(reticulate)
library(tidyverse)
library(caret) # Confusion Matrix
library(lubridate)
library(magrittr)

# Load Image quality model, Modified directory to include location of model file on your drive.
model.2 <- load_model_hdf5("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/model_resnet50_ImageQuality.h5")

# Image augmentation
testgen <- image_data_generator(rescale = 1/255)

##### yamal ####
# Generates batches of data from images in a directory. Modified directory to include location of images on your drive.
test_generator.yamal <- flow_images_from_directory(directory = "/Users/gerardocelis/Documents/Images_for_models/renamed_images/yamal/2022", 
                                                      generator = testgen,
                                                      target_size = c(224, 224), 
                                                      batch_size = 1, 
                                                      class_mode = "categorical", shuffle = FALSE)

# Run predictions
test_generator.yamal$reset()
predictions.yamal <- model.2 %>% 
  predict(test_generator.yamal,
          generator = test_generator.yamal,
          verbose = 1,
          steps = as.integer(test_generator.yamal$n)
  ) %>%
  #round(digits = 2) %>%
  data.table()

predictions.yamal$filepaths <- test_generator.yamal$filepaths
predictions.yamal$file <- test_generator.yamal$filenames

colnames(predictions.yamal) <- c("Bad", "Good", "filepaths", "file")

# Extract informaiton from file name
predictions.yamal[, v_image_name := sapply(strsplit(as.character(file), split="/"), tail, 1)]# Extracts last item in list

# create class predictions using Maximum by column
predictions.yamal[, class_id_model_step_2 := colnames(.SD)[max.col(.SD, ties.method = "first")], .SDcols = c("Bad", "Good")]

# create class predictions using asymmetric criteria
predictions.yamal[Bad >= 0.95, class_id_model_step_2 := "Bad"]
predictions.yamal[Bad < 0.95, class_id_model_step_2 := "Good"]

# Check if any images where not classified
predictions.yamal[is.na(class_id_model_step_2) == T, .N]

# Save predictions, Modified directory to include location where you want to save on your drive.
fwrite(predictions.yamal, "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2.csv")

