# Load packages; install if needed along with dependencies
library(keras)
library(tensorflow)
library(data.table)
library(reticulate)
library(tidyverse)

# image augmentation
testgen <- image_data_generator(rescale = 1/255)

# Load trained model, include file name with complete path. Modified directory to include location of model file on your drive.
model <- load_model_hdf5("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/model_resnet50_Species.h5")

# Generates batches of data from images in a directory. Modified directory to include location of images on your drive.
test_generator <- flow_images_from_directory(directory = "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/2022_cropped",
                                             generator = testgen,
                                             target_size = c(224, 224),
                                             batch_size = 1, 
                                             class_mode = "categorical", shuffle = FALSE)

# Run predictions
test_generator$reset()
predictions <-
  predict(model, test_generator,
          generator = test_generator,
          verbose = 1,
          steps = as.integer(test_generator$n)
  )
  #round(digits = 2) %>%
predictions <-data.table(predictions)

predictions$filepaths <- test_generator$filepaths
predictions$file <- test_generator$filenames

colnames(predictions) <- c("Bait", "Bait_yamal", "Empty", "Rock", "alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc", "pic_pic", "ran_tar", "vul_lag", "vul_vul", "filepaths", "file")

predictions[, v_image_temp := sapply(strsplit(as.character(file), split="/"), tail, 1)]# Extracts last item in list
predictions[, v_image_name := sapply(strsplit(as.character(v_image_temp), split="__"), "[",1)]# Extracts last item in list

# all predicittns
#predictions[, v_species_model := colnames(.SD)[max.col(.SD, ties.method = "first")], .SDcols = c("Bait", "Bait_yamal", "Empty", "Rock", "alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc", "pic_pic", "ran_tar", "vul_lag", "vul_vul")]
#predictions[, v_species_model_max := do.call(pmax, .SD), .SDcols = c("Bait", "Bait_yamal", "Empty", "Rock", "alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc", "pic_pic", "ran_tar", "vul_lag", "vul_vul")]

#predictions[, .N, by = .(v_species_model)]

# Removed Bait_yamal, pic_pic
predictions[, v_species_model := colnames(.SD)[max.col(.SD, ties.method = "first")], .SDcols = c("Bait", "Empty", "Rock", "alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc", "ran_tar", "vul_lag", "vul_vul")]
predictions[, v_species_model_max := do.call(pmax, .SD), .SDcols = c("Bait", "Empty", "Rock", "alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc", "ran_tar", "vul_lag", "vul_vul")]


fwrite(predictions, "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Varanger_classified_2022_gaissene_Step_4.csv")

# Calculate abundance per image for all species
predictions.abu <- predictions[, .(v_abundance_model = .N), by = .(v_image_name, v_species_model)]
predictions.abu[, .N, by = .(v_species_model)]

# Convert to long format
d <- dcast(predictions.abu, v_image_name ~ v_species_model, value.var = "v_abundance_model", drop = TRUE, fill = 0L)


# Import mode results for 
c <- fread("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2_step3.csv", na.strings = "")

# Merge steps 2 and 3 with 4.
all <- merge(c, d, by = "v_image_name", all.x = T)

# Use if only specific columns require NA = 0
col.anim <- c("alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc",  "ran_tar", "vul_lag", "vul_vul")
setnafill(all, cols=col.anim, fill=0)

# Determine empty (non-species) 
col.other <- c("Bait",  "Empty", "Rock")
setnafill(all, cols=col.other, fill=0)

# create human variable 
all[, hom_sap := ifelse(class_id_model_step_3 == "Person", 1, 0)]
all[, hom_sap := ifelse(class_id_model_step_3 == "Vehicle", 1, 0)]


# All species, but will vary depending on year and location
all[, Animal_total := rowSums(.SD), .SDcols=c("alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc", "pic_pic", "ran_tar", "vul_lag", "vul_vul")]
all[, Non_Animal_total := rowSums(.SD), .SDcols=c("Bait", "Bait_yamal", "Empty", "Rock")]
all[Animal_total > 0, Animal_present :=  "Animal"]
all[Animal_total == 0, Animal_present := "Empty"]
all[, .N, by = .(Animal_present)]
all[, .N]

# Removed Bait_yamal, pic_pic
#all[, Animal_total := rowSums(.SD), .SDcols=c("alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb", "lag_mut", "lep_arc",  "ran_tar", "vul_lag", "vul_vul")]
#all[, Non_Animal_total := rowSums(.SD), .SDcols=c("Bait",  "Empty", "Rock")]
#all[Animal_total > 0, Animal_present :=  "Animal"]
#all[Animal_total == 0, Animal_present := "Empty"]
#all[, .N, by = .(Animal_present)]
#all[, .N]

# created image quality variable
all[, v_quality := ifelse(class_id_model_step_2 == "Bad" & class_id_model_step_3 == "Empty", 0, 1)]

# Classify based on all models
all[Animal_present == "Animal", class_id_model_all := "Animal"]
all[Animal_present == "Empty", class_id_model_all := "Empty"]
all[class_id_model_step_2 == "Bad", class_id_model_all := "Bad"]
all[class_id_model_step_3 == "Human", class_id_model_all := "Human"]

all[, .N, by = class_id_model_all]

# Export data. Modified directory to include location of file on your drive.
fwrite(all, "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2_step3_step_4.csv")

