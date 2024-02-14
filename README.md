# Image classification workflow guide.

Celis et al. 2024, A versatile semi-automated image analysis workflow for time-lapse camera trap image classification.

## Table of contents

1. [Introduction](#Introduction)
2. [Step 1](#Step 1)
3. [Step 2](#Step 2)
  * [Model training for image quality](##Model training for image quality)

## Introduction

This document provides a guide for the image classification workflow (Fig. 1). General instructions are provided for each step of the workflow and there will be a corresponding file with code scripts. Each script will contain embedded instructions with more details for each step.


Figure 1. Time-lapse camera trap workflow. Data preparation and model steps are adapted from Böhner et al. (2022).

Users may adapt the code to fit their specific needs. To run the code for each step of the workflow, you will need to install R, Python, and several packages/libraries. Please follow the instructions at each source, which will depend on your computer and operating system:
•	R; https://cran.r-project.org, we also suggest installing an IDE such as Rstudio; https://posit.co/downloads/.
•	Python; https://www.python.org
•	Tensorflow for R; https://tensorflow.rstudio.com/install/
•	MegaDetector; https://github.com/microsoft/CameraTraps/blob/main/megadetector.md#using-the-model

# Step 1
## Renaming files

Before running the renaming R script, you must organize your images into folders such that all images from one camera trap are contained in a single folder. In our specific case, we had sites that had multiple cameras. For example, the Komagdalen site had eight cameras, and each camera station had a unique name (k1 - k8; Fig. 2). Before applying the classification workflow, all images should have unique names that correspond to the site, camera, and timestamp. We provide a script for renaming images that extracts the camera locations from the names of the folders in a folder structure, as suggested in Fig. 2.

The image renaming script is: Step_1_Rename_Files.R.

# Step 2
## Model training for image quality