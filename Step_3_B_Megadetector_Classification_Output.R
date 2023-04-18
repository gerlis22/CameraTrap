# Load packages; install if needed along with dependencies
library(jsonlite)
library(dplyr)
library(data.table)
library(tidyr)
library(ggplot2)
library(caret)
library(tidyverse)


#####################
##### Varanger ######

# Import JSON data created by MegaDetector classification. Modified directory to include location of json file on your drive.
json_data <- read_json(path='/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_MegaDetector_md_v5b_output.json', simplifyVector = TRUE)

# Create dataframe
dat <- as.data.frame(json_data)

d_unlist <- unnest(dat, images.detections, names_sep = ".")
d_unlist <- data.table(d_unlist)

d_no_detection <- data.table(dat)
d_no_detection <- d_no_detection[images.max_detection_conf == 0]

d_all <- rbind(d_unlist, d_no_detection, fill = TRUE)

d_all <- data.table(d_all)

length(unique(d_all$images.file))

# Symmetric threshold
#d_all[images.detections.category == "1" & images.detections.conf >= 0.4, class_id_model_step_3 := "Animal"]
#d_all[images.detections.category == "2" & images.detections.conf >= 0.4, class_id_model_step_3 := "Human"]
#d_all[images.detections.category == "3" & images.detections.conf >= 0.4, class_id_model_step_3 := "Vehicle"]
#d_all[images.detections.conf < 0.4 | is.na(class_id_model_step_3) == T, class_id_model_step_3 := "Empty"]

# Asymmetric threshold
d_all[images.detections.category == "1" & images.detections.conf >= 0.1, class_id_model_step_3 := "Animal"]
d_all[images.detections.category == "2" & images.detections.conf >= 0.2, class_id_model_step_3 := "Human"]
d_all[images.detections.category == "3" & images.detections.conf >= 0.8, class_id_model_step_3 := "Vehicle"]
d_all[images.detections.conf < 0.1 | is.na(class_id_model_step_3) == T, class_id_model_step_3 := "Empty"]

d_all[is.na(images.detections.conf)==T, class_id_model_step_3 := "Empty"]

d_all[, .N, by = .(class_id_model_step_3)]

d_all[, v_image_name := sapply(strsplit(as.character(images.file), split="/"), "[", 2)]# Extracts site from image filename

# create classification variables long format
dat_all <- dcast(d_all, images.file + v_image_name + images.max_detection_conf ~ class_id_model_step_3, drop = TRUE)

# All megadetector variable present
dat_all[Human == 0 & Animal == 0 & Empty > 0 , class_id_model_step_3 := "Empty"]
dat_all[Animal != 0, class_id_model_step_3 := "Animal"]
# Use if vehicle
dat_all[Animal == 0 & Human > 0, class_id_model_step_3 := "Human"]

dat_all[, .N, by = .(class_id_model_step_3)]

# Load quality model results
selected <- fread("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2.csv", na.strings = "")

# Merge Quality image classification and Megadetector
c_varanger <- merge(selected, dat_all[, .(v_image_name, class_id_model_step_3, images.max_detection_conf)], by = "v_image_name")

# Identify Bad images
c_varanger[class_id_model_step_2 == "Bad", class_id_model_step_3 := "Bad"]

# Merge Human and Vehicle
c_varanger[class_id_model_step_3 == "Vehicle", class_id_model_step_3 := "Human"]

# Save classifications. Modified directory to include location where you want to save on your drive.
fwrite(c_varanger, "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2_step3.csv")