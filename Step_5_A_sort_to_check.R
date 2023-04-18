# Load packages; install if needed along with dependencies
library(data.table)

# import classified image data. Modified directory to include location of file on your drive.
classified <- fread("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_step_2_step3_step_4.csv")
classified[, sn_site := sapply(strsplit(as.character(v_image_name), split=" "), "[", 1)]# Extracts last item in list

# total number of images
classified[, .N]

# Total number of images per classification
classified[, .N, by = .(sn_site, class_id_model_all)]

# Randomly select 10% of total images from each site and model classification
image_check <- classified[,.SD[sample(.N, ceiling(.N * 0.1))], by = .(sn_site, class_id_model_all)]

##* using all animals to check

# Check number of images sampled
image_check[, .N, by = .(sn_site, class_id_model_all)]
image_check[, .N]

# Create directories if needed
dir.create("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Check_Yamal_2022")

# Subfolder names based on classification
subfolder_names <- unique(image_check$class_id_model_all) 

# Create subfolders
for (j in 1:length(subfolder_names)){
  folder<-dir.create(file.path("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Check_Yamal_2022/",subfolder_names[j]))
}


# Copy files to folders
image_check %>% 
  with(walk2(.x = filepaths, .y = class_id_model_all,
             .f = ~file.copy(.x, paste0("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Check_Yamal_2022/", .y))))

# Save file with data that will be checked manually
fwrite(image_check, "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_classified_2022_toCheck.csv")
