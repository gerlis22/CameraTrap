# Image classification workflow guide.

Celis et al. 2024, A versatile semi-automated image analysis workflow for time-lapse camera trap image classification.

## Table of contents

1. [Introduction](##Introduction)
2. [Step 1](#Step-1)
3. [Step 2](#Step-2)
  * [Model training for image quality](#Model-training-for-image-quality)
  * [Image classification for image quality](#Image-classification-for-image-quality)

## Introduction

This document provides a guide for the image classification workflow (Fig. 1). General instructions are provided for each step of the workflow and there will be a corresponding file with code scripts. Each script will contain embedded instructions with more details for each step.


Figure 1. Time-lapse camera trap workflow. Data preparation and model steps are adapted from Böhner et al. (2022).

Users may adapt the code to fit their specific needs. To run the code for each step of the workflow, you will need to install R, Python, and several packages/libraries. Please follow the instructions at each source, which will depend on your computer and operating system:
•	R; https://cran.r-project.org, we also suggest installing an IDE such as Rstudio; https://posit.co/downloads/.
•	Python; https://www.python.org
•	Tensorflow for R; https://tensorflow.rstudio.com/install/
•	MegaDetector; https://github.com/microsoft/CameraTraps/blob/main/megadetector.md#using-the-model

## Step 1
### Renaming files

Before running the renaming R script, you must organize your images into folders such that all images from one camera trap are contained in a single folder. In our specific case, we had sites that had multiple cameras. For example, the Komagdalen site had eight cameras, and each camera station had a unique name (k1 - k8; Fig. 2). Before applying the classification workflow, all images should have unique names that correspond to the site, camera, and timestamp. We provide a script for renaming images that extracts the camera locations from the names of the folders in a folder structure, as suggested in Fig. 2.

The image renaming script is: Step_1_Rename_Files.R.

## Step 2
### Model training for image quality
Model training for image quality can be performed using users' images based on the two classes, Bad and Good, or can be trained to include additional classes of interest. For example, one may be interested in identifying if a lure bait is present in the image. The R script for model training is Step_2_A_Model_Training_ImageQuality.R. However, if you want to use our train model for image quality, proceed to the next section, “Image classification for image quality”.

Model training requires you have manually classified images and separated them into individual folders. For example, our image quality model has two classes ‘Good’ and ‘Bad’ quality. In addition, you will need images for training the model, validation during training and test model once it has been trained (Fig. 3). We split the data such that 90% of image were used to train the model, 8% for validation and 2% to evaluate (test).

Figure 3. Folder structure for Image quality training (2 classes).

### Image classification for image quality

The image classification for image quality can be done with our model or with the model created by user in the previous section. Our classification script is Step_2_B_Image Classification.R and the model can be is: model_resnet50_ImageQuality.h5(Temporary location until available on Arctic Data Center). This step will produce a csv file with image file names, model scoring for each image and classification based on the scoring.
The classification of each image can be set as the maximum value of prediction scoring, or one can set the classification based on a threshold. See example below.

```batch
# create class predictions using Maximum by column
predictions.gaissene[, class_id_model_step_2 := colnames(.SD)[max.col(.SD, ties.method = "first")], .SDcols = c("Bad", "Good")]

# create class predictions using asymmetric criteria
predictions.gaissene[Bad >= 0.95, class_id_model_step_2 := "Bad"]
predictions.gaissene[Bad < 0.95, class_id_model_step_2 := "Good"]

```