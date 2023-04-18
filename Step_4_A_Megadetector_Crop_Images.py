# Initiate each session
cd ~/git/cameratraps
conda activate cameratraps-detector
export PYTHONPATH="$PYTHONPATH:$HOME/git/cameratraps:$HOME/git/ai4eutils:$HOME/git/yolov5"


# Crop images with animals
python classification/crop_detections_copy.py \
"/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Varanger_gaissene_MegaDetector_md_v5b_output.json" \
"/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/2022_cropped" \
--images-dir "/Users/gerardocelis/Documents/Images_for_models/Images_to_classify/2022/gaissene" \
--threshold 0.1 \
--save-full-images --square-crops \
--threads 50 \
--logdir "."
