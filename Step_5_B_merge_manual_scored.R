# Load packages; install if needed along with dependencies
library(data.table)

# add directory location
csv.dir <- "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/csv files/manual/"

# Get list of all csv files
all.files <- list.files(path = csv.dir, pattern = ".csv", full.names=TRUE, recursive = TRUE)

# Create a list of all data files
l <- lapply(all.files, fread, sep=",", skip = 1)

# Combine all data files from list
manual <- rbindlist(l)

# Check number image per location
manual[, .N , by = Location][order(Location)]

# Create image name
manual[, v_image_name := paste(Location, `Image Name`, sep = " ")]

# Set animal variables
col.anim <- c('arctic fox', 'corvidsp', 'crow', 'eaglesp', 'foxsp', 'goldeneagle', 'gull', 'human', 'magpie', 'mammalsp', 'raven', 'red fox', 'reindeer', 'seaeagle', 'snowyowl', 'wolverine')

# replace NAs with zero
setnafill(manual, cols=col.anim, fill=0)

# Sum total for animal variables
manual[, Animal_total := rowSums(.SD), .SDcols=col.anim]
manual[, Animal_present := ifelse(Animal_total > 0, "Animal", "Empty")]


# Rename variables
setnames(manual, c('arctic fox', 'corvidsp', 'crow', 'eaglesp', 'foxsp', 'goldeneagle', 'gull', 'human', 'magpie', 'mammalsp', 'raven', 'red fox', 'reindeer', 'seaeagle', 'snowyowl', 'wolverine'),
         c('vul_lag', 'corvidsp', 'cor_corn', 'eaglesp', 'foxsp', 'aqu_chr', 'gull', 'hom_sap', 'pic_pic', 'mammalsp', 'cor_cora', 'vul_vul', 'ran_tar', 'hal_alb', 'snowyowl', 'gul_gul'), skip_absent=TRUE)


# Import model classification
classified <- fread("/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Varanger_classified_2022_gaissene_toCheck.csv")

#col.anim.auto <- c("alc_alc", "aqu_chr", "cor_cora", "cor_corn", "gul_gul", "hal_alb",  "ran_tar", "vul_lag", "vul_vul")
#classified[, Animal_total := rowSums(.SD), .SDcols=col.anim.auto]

# Merge manual and model classifications
all <- merge.data.table(manual, classified,
                        by = c("v_image_name"),
                        suffixes = c(".manual", ".auto"))
# Model incorrect
model.wrong <- all[Animal_present.auto == "Empty" & Animal_present.manual == "Animal"]
# Check how many images were incorrect
model.wrong[, .N]

# Export data to CSV file
fwrite(model.wrong, file = "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Model_Corrrect_2022.csv")

# Human incorrect
human.wrong <- all[Animal_present.auto == "Animal" & Animal_present.manual == "Empty"]
# Check how many images were incorrect
human.wrong[, .N]

# Export data to CSV file
fwrite(human.wrong, file = "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Model_Corrrect_2022.csv")
