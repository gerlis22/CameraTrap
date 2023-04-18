# Load packages; install if needed along with dependencies
library(exifr)
library(data.table)
library(lubridate)
library(stringr)
library(purrr)
library(magick)

# Extract image metadata; this can take a long time depending on computer and number of images
# Modified path to include location of images on your drive.
meta <- read_exif(path = "/Users/gerardocelis/Documents/Images_for_models/raw_images/yamal/2022", 
                              tags = c("FileName", "DateTimeOriginal"), args = c("-fast2"), recursive = TRUE, quiet = F)

###* add more metadata examples

# Create data.table from metadata dataframe
meta <- data.table(meta)

# convert ":" to dashes in the date and time variable
meta[, date_time := str_replace_all(DateTimeOriginal, ":", "-")]

# Replace space
meta[, date_time := str_replace(date_time, " ", "_")]

# Extract year, region and site, from original filename; this will depend on folder structure. Need to adapt accordingly
meta[, year := sapply(strsplit(as.character(SourceFile), split="/"), "[", 8)]# Extracts eight item
meta[, region := sapply(strsplit(as.character(SourceFile), split="/"), "[", 7)]# Extracts seventh item
meta[, site := sapply(strsplit(as.character(SourceFile), split="/"), "[", 9)]# Extracts ninth item

# Create a new image filename using site, date and time
meta[, v_image_name := paste(site, date_time, sep = "_")]
meta[, v_image_name := paste0(v_image_name, ".JPG")]

# Create variable with directory and nested folders for location where renamed files will go
meta[, SourceFile_rename := paste("/Users/gerardocelis/Documents/Images_for_models/renamed_images/yamal/2022", site, v_image_name, sep = "/")]

# Create directories if needed
dir.create("/Users/gerardocelis/Documents/Images_for_models/renamed_images/yamal/2022", recursive = TRUE)

# create list of all sites
subfolder_names <- unique(meta$site) 

# Create subfolders for each site in the new directory
for (j in 1:length(subfolder_names)){
  folder <- dir.create(file.path("/Users/gerardocelis/Documents/Images_for_models/renamed_images/yamal/2022/", subfolder_names[j]))
}

# Copy files to new directory with rename.
meta %>% 
  with(walk2(.x = SourceFile, .y = SourceFile_rename,
             .f = ~file.copy(.x, .y)))

# Copy files to new directory with rename.
meta %>% 
  with(walk(.x = "/Users/gerardocelis/Documents/Images_for_models/renamed_images/yamal/2022/", .y = site,
             .f = ~fwrite(.x, .y)))

# Create data file with new filenames
list_dt <- split(meta, by = c("year", "region", "site"))

for(i in 1:length(list_dt)) {
  fwrite(list_dt[[i]], paste0("/Users/gerardocelis/Documents/Images_for_models/renamed_images/yamal/2022/", str_replace_all(names(list_dt[i]), "[.]", "_"), ".csv"))
  }



