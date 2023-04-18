# Initiate each session
cd ~/git/cameratraps
conda activate cameratraps-detector
export PYTHONPATH="$PYTHONPATH:$HOME/git/cameratraps:$HOME/git/ai4eutils:$HOME/git/yolov5"

# Single image classification
cd ~/git/CameraTraps
python detection/run_detector.py "/Users/gerardocelis/Downloads/md_v5b.0.0_rebuild_pt-1.12_zerolr.pt" --image_file "/Users/gerardocelis/Downloads/g2_2019-03-30_05-50-00.JPG" --threshold 0.1


# Batch of images classification
cd ~/git/CameraTraps
python detection/run_detector_batch.py "/Users/gerardocelis/Downloads/md_v5b.0.0_rebuild_pt-1.12_zerolr.pt" "/Users/gerardocelis/Documents/Images_for_models/renamed_images/yamal/2022" "/Users/gerardocelis/Library/CloudStorage/OneDrive-UniversityofArkansas/Ungar Lab/CameraTraps/Manuscript/github_code/Yamal_MegaDetector_md_v5b_output.json" --output_relative_filenames --recursive --checkpoint_frequency 10000
