## TRAINING WITH CYCLIC LEARNING RATE

# Load packages; install if needed along with dependencies
library(keras)
library(tensorflow)
library(data.table)
library(reticulate)
library(tidyverse)

## set file names
model.name <- "model_resnet50_ImageQuality.h5"
history.name <-"model_resnet50_ImageQuality_history.csv"


#### FUNCTION FOR CYCLIC LEARNING RATE
Cyclic_LR <- function(iteration=1:32000, base_lr=1e-5, max_lr=1e-3, step_size=2000, mode='triangular', gamma=1, scale_fn=NULL, scale_mode='cycle'){ # translated from python to R, original at: https://github.com/bckenstler/CLR/blob/master/clr_callback.py # This callback implements a cyclical learning rate policy (CLR). # The method cycles the learning rate between two boundaries with # some constant frequency, as detailed in this paper (https://arxiv.org/abs/1506.01186). # The amplitude of the cycle can be scaled on a per-iteration or per-cycle basis. # This class has three built-in policies, as put forth in the paper. # - "triangular": A basic triangular cycle w/ no amplitude scaling. # - "triangular2": A basic triangular cycle that scales initial amplitude by half each cycle. # - "exp_range": A cycle that scales initial amplitude by gamma**(cycle iterations) at each cycle iteration. # - "sinus": A sinusoidal form cycle # # Example # > clr <- Cyclic_LR(base_lr=0.001, max_lr=0.006, step_size=2000, mode='triangular', num_iterations=20000) # > plot(clr, cex=0.2)
  
  
  ########
  if(is.null(scale_fn)==TRUE){
    if(mode=='triangular'){scale_fn <- function(x) 1; scale_mode <- 'cycle';}
    if(mode=='triangular2'){scale_fn <- function(x) 1/(2^(x-1)); scale_mode <- 'cycle';}
    if(mode=='exp_range'){scale_fn <- function(x) gamma^(x); scale_mode <- 'iterations';}
    if(mode=='sinus'){scale_fn <- function(x) 0.5*(1+sin(x*pi/2)); scale_mode <- 'cycle';}
  }
  lr <- list()
  if(is.vector(iteration)==TRUE){
    for(iter in iteration){
      cycle <- floor(1 + (iter / (2*step_size)))
      x2 <- abs(iter/step_size-2 * cycle+1)
      if(scale_mode=='cycle') x <- cycle
      if(scale_mode=='iterations') x <- iter
      lr[[iter]] <- base_lr + (max_lr-base_lr) * max(0,(1-x2)) * scale_fn(x)
    }
  }
  lr <- do.call("rbind",lr)
  return(as.vector(lr))
}
####################



#### START TRAINING

## setup
epochs = 55
batch_size  = 64

learning_rate_min = 0.000001
learning_rate_max = 0.001


## setup image generators
datagen <- image_data_generator(rescale = 1/255,
                                rotation_range = 40,
                                width_shift_range = 0.2,
                                height_shift_range = 0.2,
                                shear_range = 0.2,
                                zoom_range = 0.2,
                                horizontal_flip = TRUE,
                                fill_mode = "nearest")

testgen <- image_data_generator(rescale = 1/255)


# Generates batches of data from images in a directory. Modified directory to include location of images on your drive.
train_generator <- flow_images_from_directory(directory = "/Users/gerardocelis/Documents/2class/train", 
                                              generator = datagen, 
                                              target_size = c(224, 224), 
                                              batch_size = batch_size, 
                                              class_mode = "categorical")


# Generates batches of data from images in a directory. Modified directory to include location of images on your drive.
val_generator <- flow_images_from_directory(directory = "/Users/gerardocelis/Images_for_models/2class/validate", 
                                            generator = testgen, 
                                            target_size = c(224, 224), 
                                            batch_size = batch_size, 
                                            class_mode = "categorical")


# load the resnet50 model
model <- application_resnet50(include_top = TRUE, weights = NULL, classes = 2)

# compile the model
model <- model %>%   compile(loss = 'categorical_crossentropy', optimizer = optimizer_adam(learning_rate = 0.000001),metrics = c("accuracy"))

## Define callbacks
## R6 function 
LogMetrics <- R6::R6Class("LogMetrics",
                          inherit = KerasCallback,
                          public = list(
                            loss = NULL,
                            acc = NULL,
                            on_batch_end = function(batch, logs=list()) {
                              self$loss <- c(self$loss, logs[["loss"]])
                              self$acc <- c(self$acc, logs[["acc"]])
                            }
                          ),
                          lock_objects = FALSE)

## function to set iteration to zero and clear history (at the begininng of training)
callback_lr_init <- function(logs){
  iter <<- 0
  lr_hist <<- c()
  iter_hist <<- c()
}

## function to set the learning rate at the beginning of each batch
callback_lr_set <- function(batch, logs){
  iter <<- iter + 1
  LR <- l_rate[iter] # if number of iterations > l_rate values, make LR constant to last value
  if(is.na(LR)) LR <- l_rate[length(l_rate)]
  k_set_value(model$optimizer$lr, LR)
}

## function to log the learning rate and iteration number
callback_lr_log <- function(batch, logs){
  lr_hist <<- c(lr_hist, k_get_value(model$optimizer$lr))
  iter_hist <<- c(iter_hist, k_get_value(model$optimizer$iterations))
}

## create the callbacks
callback_lr <- callback_lambda(on_train_begin=callback_lr_init, on_batch_begin=callback_lr_set)
callback_logger <- callback_lambda(on_batch_end=callback_lr_log)

## Cyclic learning rate
n_iter <- epochs * ceiling(train_generator$n/batch_size)

l_rate <- Cyclic_LR(iteration=1:n_iter, base_lr=learning_rate_min, max_lr=learning_rate_max, step_size=n_iter/2,
                    mode='triangular', gamma=1, scale_fn=NULL, scale_mode='cycle')

## initiate the the logger
callback_log_acc_lr <- LogMetrics$new()

## put all callbacks in a list
callbacks_list <- list(callback_model_checkpoint(filepath = paste0("/Users/gerardocelis/model/", model.name), 
                                                 save_best_only = TRUE), 
                       callback_csv_logger(filename = paste0("/Users/gerardocelis/model/", history.name), append = TRUE),
                       callback_lr, callback_logger, callback_log_acc_lr
                       )

# train
history <- model %>% fit(train_generator, 
                                   steps_per_epoch = ceiling(train_generator$n/batch_size), 
                                #    steps_per_epoch = ceiling(nrow(train_data)/batch_size), 
                                   epochs = epochs, 
                                   callbacks = callbacks_list,
                                   validation_data = val_generator, 
                                   validation_steps = ceiling(val_generator$n/batch_size),
                                  #validation_steps = ceiling(nrow(val_data)/batch_size),
                                  workers = 16)



#Save model directly
# Modified file name to include location on your drive.
save_model_hdf5(model, "/Users/gerardocelis/model/model_resnet50_ImageQuality.h5")


# load model
# Modified file name to include location on your drive.
model <- load_model_hdf5("/Users/gerardocelis/model/model_resnet50_ImageQuality.h5")

# Generates batches of data from images in a directory. Modified directory to include location of images on your drive.
test_generator <- flow_images_from_directory(directory = "/Users/gerardocelis/Images_for_models/2class/test", 
                                             generator = testgen, 
                                             target_size = c(224, 224), 
                                             batch_size = 1, 
                                             class_mode = "categorical", shuffle = FALSE)


test_generator$reset()
model %>%
  evaluate(test_generator, 
                     steps = as.integer(test_generator$n))

# Run with CPU
#with(tf$device("CPU:0"), {system.time(model %>%
#              evaluate(test_generator, 
#                       steps = as.integer(test_generator$n)))})

# Desktop computer with CPU 3.3 GHz Quad-Core Intel Core i5 & 8 Gb of Ram- 958 images in 344 seconds; second run 85 seconds

# create library of indices & class labels
classes <- test_generator$classes %>%
  factor() %>%
  table() %>%
  as_tibble()
colnames(classes)[1] <- "value"

indices <- test_generator$class_indices %>%
  as.data.frame() %>%
  gather() %>%
  mutate(value = as.character(value)) %>%
  left_join(classes, by = "value")

# Run model
test_generator$reset()
predictions <- model %>% 
  predict(test_generator,
    generator = test_generator,
    steps = as.integer(test_generator$n)
  ) %>%
  #round(digits = 2) %>%
  as_tibble()


colnames(predictions) <- indices$key

predictions <- predictions %>%
  mutate(truth_idx = as.character(test_generator$classes)) %>%
  left_join(indices, by = c("truth_idx" = "value"))


# Get file names
predictions$file <- test_generator$filenames


predictions <- data.table(predictions)
predictions[, class_id_model := colnames(.SD)[max.col(.SD, ties.method = "first")], .SDcols = c('Bad', 'Good')]

# Create confusion matrix
con.tbl.v1 <- confusionMatrix(data=factor(predictions[]$class_id_model),
                              reference = factor(predictions[]$key),
                              mode = "prec_recall")
con.tbl.v1

t <- data.table(con.tbl.v1$byClass, id = rownames(con.tbl.v1$byClass))[,.(id, Precision, Recall, F1)]  %>%
  mutate(across(where(is.numeric), ~ round(., digits = 3))) 

# Save table with preformance indices
fwrite(t, file = "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/Model_Varanger_5class_Performance.csv")  

# Create confusion matrix plot
predictions[, compare := ifelse(key == class_id_model, "similar", "not_similar")]
predictions[, .N, by  = .(compare)]
indices.max <- predictions[, .N, by = .(key, class_id_model)]
pred.sum.max<- merge(indices.max, predictions[, .N, by = .(key)], by = c("key"))
pred.sum.max[, percentage_pred := N.x / N.y * 100]
pred.sum.max[, id_col := ifelse(key == class_id_model, "Correct", "Incorrect")]

# Create figure of confusion matrix
fig_good_bad_varanger_model_test <- pred.sum.max[] %>%
  ggplot(aes(x = key, y = class_id_model, 
             fill = id_col, 
             label = paste(round(percentage_pred, 1), "%", "\n", format(N.x, big.mark = ",", scientific = FALSE), sep = ""))) +
  geom_tile(aes(alpha = percentage_pred)) +
  scale_alpha(range = c(0.1, 1))+
  scale_fill_manual(values = c(Correct = "#1b9e77", Incorrect = "#d95f02")) +
  geom_text()+
  theme_bw()+
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))+
  labs(x = "True class", y = "Predicted Class", fill = "Prediction", alpha = "Percentage") + theme(strip.background = element_blank(), panel.grid.major = element_blank())
fig_good_bad_varanger_model_test

# Save figure
ggsave("/Users/gerardocelis/model/Figures/Model_ImageQuality_Test_ConfMtrx.pdf", fig_good_bad_varanger_model_test, dpi = 320, width = 7, height = 5)
