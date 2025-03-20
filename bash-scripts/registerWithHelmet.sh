#!/bin/bash
# This script is used to register a T1 registration image with the helmet
# registration image. It performs the following steps:
#   1. Uses the 'bet' command to create a brain mask. Note, this may require setting
#      the coordinates for the centre of the brain using the -c flag.
#   2. Inverts the brain mask, and applies this to the input image so that only
#      water is visible.
#   4. Registers the masked input image with the reference image using flirt.
#   5. Applies the transform to other images.
# An initial transform for the flirt registration can be provided using the -t flag.

# Default values
center="-c 98, 176, 72"
output_folder=""
initial_transform=""
input_file=""

print_usage() {
  echo "Usage: registerWithHelmet.sh -i <filename.nii.gz> [-c x y z] [-o output_folder] [-t transform_file]"
  echo "       -i filename.nii.gz: Input file in NIfTI format (required)"
  echo "       -c x,y,z: Optional center coordinates in voxels for the 'bet' command"
  echo "       -o output_folder: Optional output folder for processed images"
  echo "       -t transform_file: Optional initial transform for the registration"
}

# Parse flags
while getopts 'c:o:t:i:h' flag; do
  case "${flag}" in
    c) IFS=',' read -ra ADDR <<< "${OPTARG}"
       center="-c ${ADDR[0]}, ${ADDR[1]}, ${ADDR[2]}" ;;
    o) output_folder="${OPTARG}"
       mkdir -p "$output_folder" ;;
    t) initial_transform="-init ${OPTARG} -searchrx -10 10 -searchry -10 10 -searchrz -10 10" ;;
    i) input_file="${OPTARG}" ;;
    h) print_usage
       exit 0 ;;
    *) print_usage
       exit 1 ;;
  esac
done

# Check if a filename was provided as argument
if [ -z "$input_file" ]; then
  print_usage
  exit 1
fi

# Get filename without any extension
filename="$input_file"
file_basename=$(basename "$filename")
file_basename=$(echo "$file_basename" | sed -r 's/(.nii|.nii.gz)$//')

if [ -z "$output_folder" ]; then
  output_folder=$(dirname "$filename")
fi

seg_file="$output_folder/${file_basename}_brain.nii.gz"
mask_file="$output_folder/${file_basename}_brain_mask.nii.gz"
inverted_mask_file="$output_folder/${file_basename}_brain_mask_inverted.nii.gz"
masked_file="$output_folder/${file_basename}_masked.nii.gz"
registered_file="$output_folder/${file_basename}_registered_to_helmet.nii.gz"
#registered_masked_file="$output_folder/${file_basename}_masked_registered.nii.gz"
registered_seg_file="$output_folder/${file_basename}_brain_registered_to_helmet.nii.gz"
registered_ref_file="$output_folder/${file_basename}_helmet_registered_to_brain.nii.gz"
transform_file="$output_folder/${file_basename}_transform_t1_nomp_to_helmet.txt"
transform_inverse_file="$output_folder/${file_basename}_transform_helmet_to_t1_nomp.txt"
mapped_points_in_file="$output_folder/${file_basename}_mapped_points_in.txt"
mapped_points_out_file="$output_folder/${file_basename}_mapped_points_out.txt"

# Set location to the reference image
ref_file_rel="../reference-images/helmet-registration-image-1mm.nii.gz"
script_dir="$(dirname "$(readlink -f "$0")")"
ref_file="$(readlink -f "$script_dir/$ref_file_rel")"

# Start timer
start=$(date +%s)

# Get brain mask and invert
echo "Step 1: Getting head mask..."
bet $filename $seg_file -o $center -m

echo "Step 2: Inverting head mask..."
fslmaths $mask_file -mul -1 -add 1 $inverted_mask_file

# Apply inverted mask to file
echo "Step 3: Applying head mask to input file..."
fslmaths $filename -mul $inverted_mask_file $masked_file

# Register masked file with reference image
echo "Step 4: Registering masked file with reference image..."
flirt -in $masked_file -ref $ref_file -dof 6 -cost mutualinfo -omat $transform_file $initial_transform

# Save inverse transform also
convert_xfm -omat $transform_inverse_file -inverse $transform_file

# Apply transform to other images
echo "Step 5: Applying registration to other images..."
flirt -in $seg_file -ref $ref_file -out $registered_seg_file -init $transform_file -applyxfm
# flirt -in $filename -ref $ref_file -out $registered_file -init $transform_file -applyxfm
# flirt -in $ref_file -ref $filename -out $registered_ref_file -init $transform_inverse_file -applyxfm

# Convert standard points to calculate the transducer coordinate transform
# echo -e "200 200 50\n210 200 50\n200 210 50\n" > $mapped_points_in_file
# img2imgcoord -src $ref_file -dest $filename -xfm $transform_inverse_file $mapped_points_in_file > $mapped_points_out_file

# Cleanup unused images
rm $mask_file
rm $inverted_mask_file
rm $masked_file
#rm $registered_masked_file

# Print run time
end=$(date +%s)
runtime=$((end-start))
echo "Script completed in $runtime seconds."
