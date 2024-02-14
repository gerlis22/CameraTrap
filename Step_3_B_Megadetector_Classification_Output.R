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
json_data.aug.tile.merge <- jsonlite::read_json(path='/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/image_computer_classification/PC_computer/merged_uark-celis-2024-01-30-aug_to_tiled-a-md_v5a_aug_0.04_0.9_5_0.5_filtering_2024.02.04.10.55.49.json', simplifyVector = TRUE)

# Create a data.frame
dat.aug.tile.merge <- as.data.frame(json_data.aug.tile.merge)

# Convert data.frame to data.table
dat.aug.tile.merge <- data.table(dat.aug.tile.merge)

# Create variable with length on list for each nested image.detection
dat.aug.tile.merge[, N := length(data.table::rbindlist(images.detections, use.names = TRUE, fill = TRUE)), by=.(images.file)]

# Unnest individual detections
d_unlist.aug.tile.merge <- copy(dat.aug.tile.merge[N == 3,])
d_unlist.aug.tile.merge <- d_unlist.aug.tile.merge[, data.table::rbindlist(images.detections, fill = TRUE), by=.(images.file)]
d_unlist.aug.tile.merge_2 <- copy(dat.aug.tile.merge[N == 4,])
d_unlist.aug.tile.merge_2 <- unnest(d_unlist.aug.tile.merge_2, images.detections, names_sep = ".")
setnames(d_unlist.aug.tile.merge_2, c("images.detections.category", "images.detections.conf", "images.detections.bbox"), c("category", "conf", "bbox"))

# Get non-detections informations
d_no_detection.aug.tile.merge <- dat.aug.tile.merge[N == 0, on=.(images.file)]

# Create list of data to merge
l_aug.tile <- list(d_unlist.aug.tile.merge, d_unlist.aug.tile.merge_2, d_no_detection.aug.tile.merge[, .(images.file)])

# Merge data
d_all <- rbindlist(l_aug.tile, fill = TRUE)

# Symmetric threshold
d_all[category == "1" & conf >= 0.1, class_id_model_step_3 := "Animal"]
d_all[category == "2" & conf >= 0.1, class_id_model_step_3 := "Human"]
d_all[category == "2" & conf < 0.1, class_id_model_step_3 := "Empty"]
d_all[category == "3" & conf >= 0.1, class_id_model_step_3 := "Vehicle"]
d_all[category == "3" & conf < 0.1, class_id_model_step_3 := "Empty"]
d_all[conf < 0.1 & is.na(class_id_model_step_3) == T, class_id_model_step_3 := "Empty"]

#d_all.2022.a[is.na(conf)==T, class_id_model_step_3 := "Empty"]
d_all[is.na(class_id_model_step_3)==T, class_id_model_step_3 := "Empty"]

# Asymmetric threshold
#d_all[category == "1" & conf >= 0.1, class_id_model_step_3 := "Animal"]
#d_all[category == "2" & conf >= 0.1, class_id_model_step_3 := "Human"]
#d_all[category == "3" & conf >= 0.8, class_id_model_step_3 := "Vehicle"]
#d_all[conf < 0.1 | is.na(class_id_model_step_3) == T, class_id_model_step_3 := "Empty"]
#d_all[is.na(conf)==T, class_id_model_step_3 := "Empty"]

# check number of image per class
d_all[, .N, by = .(class_id_model_step_3)]

d_all[, v_image_name := sapply(strsplit(as.character(images.file), split="/"), "[", 2)]# Extracts site from image filename

# create classification variables long format
dat_all <- dcast(d_all, images.file + v_image_name + images.max_detection_conf ~ class_id_model_step_3, drop = TRUE)

# All megadetector variable present
dat_all[Vehicle == 0 & Human == 0 & Animal == 0 & Empty > 0 , class_id_model_step_3 := "Empty"]
dat_all[Animal == 0 & Vehicle > 0, class_id_model_step_3 := "Human"]
dat_all[Animal == 0 & Human > 0, class_id_model_step_3 := "Human"]
dat_all[Animal > 0 & Human > 0, class_id_model_step_3 := "Animal_Human"]
dat_all[Animal > 0 & Vehicle > 0, class_id_model_step_3 := "Animal_Human"]
dat_all[Animal > 0 & Vehicle == 0 & Human == 0, class_id_model_step_3 := "Animal"]

# check number of image per class
dat_all[, .N, by = .(class_id_model_step_3)]

# Load quality model results
selected <- fread("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2.csv", na.strings = "")

# Merge Quality image classification and Megadetector
c_yamal <- merge(selected, dat_all[, .(v_image_name, class_id_model_step_3, conf)], by = "v_image_name")

# Identify Bad images
c_yamal[class_id_model_step_2 == "Bad", class_id_model_step_3 := "Bad"]

# Save classifications. Modified directory to include location where you want to save on your drive.
fwrite(c_yamal, "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2_step3.csv")