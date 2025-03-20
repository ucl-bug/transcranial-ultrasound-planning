#!/bin/bash
# This script performs the necessary processing and registration steps to
# prepare the planning images and target positions for loading into k-Plan.
#
# It should be called as a source script after defining the requisite
# variables.
#
# After running this script, load the following images into k-Plan:
#      ct.nii.gz
#      t1.nii.gz
#      lgn_left.nii.gz
#      lgn_right.nii.gz
#      helmet.nii.gz
#      t1_positioning.nii.gz
#
# Check that:
#      the CT and T1 are correctly registered
#      the lgn masks are in approximately the right place
#      the target positions overlap with the lgn masks
#      the positioning and planning t1 images are correctly registered
#      the positioning and helmet images are correctly registered
#      the loaded transducer position overlaps the positioning image

###############################################################################
# SETUP FILENAMES
###############################################################################

# CT image
data_folder="/mnt/k-Stim-Data/Subject-Data/${subject}"
ct_in="${data_folder}/Images-CT/${ct_filename}"
ct_proc="${data_folder}/Images-kPlan/ct.nii.gz"

# Planning T1
t1_in="${data_folder}/Images-Planning/${mr_foldername_planning}/${t1_ax_filename}"
t1_reg="${data_folder}/Images-kPlan/t1.nii.gz"
t1_transform="${data_folder}/Images-kPlan/transform_t1_to_ct.txt"

# Free Surfer LGN Segmentations
left_lgn_posterior_in="${data_folder}/Images-Planning/${mr_foldername_planning}/${freesurfer_seg_folder}/posterior_left_left-lgn.nii.gz"
left_lgn_posterior_reg="${data_folder}/Images-kPlan/lgn_left.nii.gz"
right_lgn_posterior_in="${data_folder}/Images-Planning/${mr_foldername_planning}/${freesurfer_seg_folder}/posterior_right_right-lgn.nii.gz"
right_lgn_posterior_reg="${data_folder}/Images-kPlan/lgn_right.nii.gz"

left_lgn_target_pos_file="${data_folder}/Images-kPlan/target_position_left_lgn.txt"
right_lgn_target_pos_file="${data_folder}/Images-kPlan/target_position_right_lgn.txt"

# Output folders
kplan_im_folder="${data_folder}/Images-kPlan"
helmet_reg_folder="${data_folder}/Images-kPlan/helmet-registration"

# Positioning T1
t1_pos_in="${data_folder}/Images-Positioning/${mr_foldername_positioning}/${t1_no_mp_filename}"

###############################################################################
# REGISTER PLANNING IMAGES AND TARGETS TO CT SPACE
###############################################################################

# Start timer
start=$(date +%s)

# 1. Reslice CT to isotropic, and pad to leave extra space for the helmet
echo "Reslicing CT..."
module load Matlab/2021a
matlab -nodisplay -nodesktop -r "restoredefaultpath; addpath('${nifti_toolbox}'); addpath('${matlab_folder}'); resliceImageToRAS('${ct_in}', '${ct_proc}', [32, 32, 64, 64, 0, 128]); exit;"

# 2. Register planning T1 to CT
echo "Registering planning T1 to CT..."
flirt \
-in $t1_in \
-out $t1_reg \
-ref $ct_proc \
-cost normmi \
-omat $t1_transform \
-dof 6

# 3. Apply transform to LGN segmentations
echo "Transforming LGN segmentations..."
flirt \
-in $left_lgn_posterior_in \
-out $left_lgn_posterior_reg \
-ref $ct_proc \
-init $t1_transform \
-applyxfm

flirt \
-in $right_lgn_posterior_in \
-out $right_lgn_posterior_reg \
-ref $ct_proc \
-init $t1_transform \
-applyxfm

# 4. Map target positions to CT (in pixels), then CT (in k-Plan world coords)
rm -f $left_lgn_target_pos_file
rm -f $right_lgn_target_pos_file

# Left LGN
if [ -z "${left_lgn_target}" ]; then
    echo "left_lgn_target is empty"
else
    echo "Mapping position of left LGN..."
    echo "LEFT LGN" >> $left_lgn_target_pos_file
    echo "Target Position in T1 Image (0-indexed voxels)" >> $left_lgn_target_pos_file
    echo "$left_lgn_target" >> $left_lgn_target_pos_file

    echo "${left_lgn_target}" | img2imgcoord \
    -src $t1_in \
    -dest $ct_proc \
    -xfm  $t1_transform \
    >> "$left_lgn_target_pos_file"

    sed -i '4s/.*/Target Position in CT Image (0-indexed voxels)/' "$left_lgn_target_pos_file"
    
    pos=$(sed -n '5p' $left_lgn_target_pos_file) # output is stored on 5th line of text file
    echo "Coordinates: ${pos}"
    echo "Target Position in CT Image (k-Plan world coords, mm)" >> $left_lgn_target_pos_file
    matlab -nodisplay -nodesktop -r "restoredefaultpath; addpath('${nifti_toolbox}'); addpath('${matlab_folder}'); voxelToWorld('${ct_proc}', [${pos}], '${left_lgn_target_pos_file}'); exit;"
fi

# Right LGN
if [ -z "${right_lgn_target}" ]; then
    echo "right_lgn_target is empty"
else
    echo "Mapping position of right LGN..."
    echo "RIGHT LGN" >> $right_lgn_target_pos_file
    echo "Target Position in T1 Image (0-indexed voxels)" >> $right_lgn_target_pos_file
    echo "$right_lgn_target" >> $right_lgn_target_pos_file

    echo "${right_lgn_target}" | img2imgcoord \
    -src $t1_in \
    -dest $ct_proc \
    -xfm  $t1_transform \
    >> "$right_lgn_target_pos_file"

    sed -i '4s/.*/Target Position in CT Image (0-indexed voxels)/' "$right_lgn_target_pos_file"

    pos=$(sed -n '5p' $right_lgn_target_pos_file)
    echo "Coordinates: ${pos}"
    echo "Target Position in CT Image (k-Plan world coords, mm)" >> $right_lgn_target_pos_file
    matlab -nodisplay -nodesktop -r "restoredefaultpath; addpath('${nifti_toolbox}'); addpath('${matlab_folder}'); voxelToWorld('${ct_proc}', [${pos}], '${right_lgn_target_pos_file}'); exit;"
fi

###############################################################################
# REGISTER POSITIONING IMAGES AND PLANNING IMAGES TO HELMET
###############################################################################

# 1. Register positioning image with helmet
echo "Registering positioning image with helmet..."
mkdir -p "${helmet_reg_folder}"
cp "${t1_pos_in}" "${helmet_reg_folder}/t1_nomp_helmet.nii"
cd "${helmet_reg_folder}"
registerWithHelmetSaveAll.sh -i t1_nomp_helmet -c "${t1_no_mp_head_centre}"

# 2. Extract brain from planning t1
echo "Extracting brain from planning t1..."
eval bet "${t1_in}" "${helmet_reg_folder}/t1_planning_brain.nii.gz" -c "${t1_ax_head_centre}" -o

# 3. Debias brain extracted images
echo "Debiasing images..."
Slicer --launch N4ITKBiasFieldCorrection "${helmet_reg_folder}/t1_nomp_helmet_brain.nii.gz" "${helmet_reg_folder}/t1_nomp_helmet_brain_debiased.nii.gz" --iterations 50,40,30,20,10
Slicer --launch N4ITKBiasFieldCorrection "${helmet_reg_folder}/t1_planning_brain.nii.gz" "${helmet_reg_folder}/t1_planning_brain_debiased.nii.gz" --iterations 50,40,30,20,10

# 4. Register positioning t1 with planning t1
echo "Registering positioning t1 with planning t1..."
flirt \
-in "${helmet_reg_folder}/t1_nomp_helmet_brain_debiased.nii.gz" \
-out "${helmet_reg_folder}/t1_nomp_helmet_brain_registered_to_planning.nii.gz" \
-ref "${helmet_reg_folder}/t1_planning_brain_debiased.nii.gz" \
-omat "${kplan_im_folder}/transform_positioning_t1_to_planning_t1.txt" \
-cost mutualinfo \
-dof 6

# 5. Combine transforms
convert_xfm \
-omat "${kplan_im_folder}/transform_positioning_t1_to_ct.txt" \
-concat "${kplan_im_folder}/transform_t1_to_ct.txt" "${kplan_im_folder}/transform_positioning_t1_to_planning_t1.txt"

convert_xfm \
-omat "${kplan_im_folder}/transform_helmet_to_ct.txt" \
-concat "${kplan_im_folder}/transform_positioning_t1_to_ct.txt" \
"${helmet_reg_folder}/t1_nomp_helmet_transform_helmet_to_t1_nomp.txt"

# 6. Transform positioning T1 (for visual check)
echo "Transforming positioning image..."
flirt \
-in "${helmet_reg_folder}/t1_nomp_helmet.nii" \
-out "${kplan_im_folder}/t1_positioning.nii.gz" \
-ref "${ct_proc}" \
-init "${kplan_im_folder}/transform_positioning_t1_to_ct.txt" \
-applyxfm

# 7. Transform helmet image (for visual check)
echo "Transforming helmet image..."
flirt \
-in "${helmet_ref_file}" \
-out "${kplan_im_folder}/helmet.nii.gz" \
-ref "${ct_proc}" \
-init "${kplan_im_folder}/transform_helmet_to_ct.txt" \
-applyxfm

# 8. Get transducer transform
echo "Getting transducer transform..."
echo -e "200 200 50\n210 200 50\n200 210 50\n" \
> "${helmet_reg_folder}/transform_mapped_points_in.txt"

img2imgcoord \
-src "${helmet_ref_file}" \
-dest "${ct_proc}" \
-xfm "${kplan_im_folder}/transform_helmet_to_ct.txt" \
"${helmet_reg_folder}/transform_mapped_points_in.txt" \
> "${helmet_reg_folder}/transform_mapped_points_out.txt"

matlab -nodisplay -nodesktop -r "restoredefaultpath; addpath('${nifti_toolbox}'); addpath('${matlab_folder}'); extractTransducerPosition('${ct_proc}'); exit;"

###############################################################################
# GET TARGET IN HELMET COORDS
###############################################################################

echo "Getting target in helmet coords..."
convert_xfm \
-omat "${kplan_im_folder}/transform_planning_t1_to_positioning_t1.txt" \
-inverse "${kplan_im_folder}/transform_positioning_t1_to_planning_t1.txt"

convert_xfm \
-omat "${kplan_im_folder}/transform_planning_t1_to_helmet.txt" \
-concat "${helmet_reg_folder}/t1_nomp_helmet_transform_t1_nomp_to_helmet.txt" "${kplan_im_folder}/transform_planning_t1_to_positioning_t1.txt"

# Left LGN
if [ -n "${left_lgn_target}" ]; then
    echo "${left_lgn_target}" | img2imgcoord \
    -src $t1_in \
    -dest "${helmet_reg_folder}/t1_nomp_helmet_brain_registered_to_helmet.nii.gz" \
    -xfm "${kplan_im_folder}/transform_planning_t1_to_helmet.txt" \
    >> "$left_lgn_target_pos_file"

    sed -i '8s/.*/Target Position in Helmet Coordinates (0-indexed voxels)/' "$left_lgn_target_pos_file"
fi

# Right LGN
if [ -n "${right_lgn_target}" ]; then
    echo "${right_lgn_target}" | img2imgcoord \
    -src $t1_in \
    -dest "${helmet_reg_folder}/t1_nomp_helmet_brain_registered_to_helmet.nii.gz" \
    -xfm "${kplan_im_folder}/transform_planning_t1_to_helmet.txt" \
    >> "$right_lgn_target_pos_file"

    sed -i '8s/.*/Target Position in Helmet Coordinates (0-indexed voxels)/' "$right_lgn_target_pos_file"
fi

# Print run time
end=$(date +%s)
runtime=$((end-start))
echo "Script completed in $runtime seconds."
