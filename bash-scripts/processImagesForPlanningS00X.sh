#!/bin/bash
# Script to process subject images.

# Subject ID
subject="S007"

# CT image filename
ct_filename="Images-CT_10.10_Low_Dose_head_-_Trial_setup_MB_HHedit_30.03.23_20240129140700_301.nii.gz"

# MR planning images
mr_foldername_planning="F3T_2023_008_007"
t1_ax_filename="images_010_t1_mpr_ax_1mm_iso_withNose_32ch_v2.nii"
t1_ax_head_centre="114 105 104" # space separated, get numbers from, e.g., ITKSnap
freesurfer_seg_folder="images_010_t1_mpr_ax_1mm_iso_withNose_32ch_v2_thalamus_segmentations"

# Target position in t1_ax image in FSL voxel coordinates (0-indexed)
left_lgn_target="89 98 91" # space separated, or empty string to skip
right_lgn_target="131 99 93" # space separated, or empty string to skip

# MR Positioning images
mr_foldername_positioning="F3T_2023_009_024"
t1_no_mp_filename="images_012_t1_NOmp_ax_1p5mm_iso_FSOn_337_176sl_NormOff.nii"
t1_no_mp_head_centre="99,114,71" # comma separated, get numbers from, e.g., ITKSnap

# Script folders (only change these if the folders are in a different place)
matlab_folder="$HOME/Drive/Repos/k-stim-image-processing/matlab-scripts"
nifti_toolbox="$HOME/Drive/Repos/k-plan-qms-sem/libraries/nifti"
helmet_ref_file="$HOME/Drive/Repos/k-stim-image-processing/reference-images/helmet-registration-image-1mm.nii.gz"

# Run script
source processImagesForPlanning.sh
