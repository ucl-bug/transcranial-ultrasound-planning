#!/bin/bash

# This script calculates the shift in the position of a target using two
# images that have been registered with the helmet reference image. The
# registration is performed using the brain extracted using bet, and mapped to
# space of the helmet registration image. The target coordinates should be in
# the coordinates of the reference (first) image.

# Check if a filename was provided as argument
if [ $# -lt 1 ]; then
  echo "Usage: computeTargetShift.sh <reference_filename.nii.gz> <target_filename.nii.gz> x y z"
  echo "       reference_filename.nii.gz: Reference image in NIfTI format"
  echo "       target_filename.nii.gz: Target image in NIfTI format"
  echo "       x y z: Voxel coordinates to map from reference to target image"
  exit 1
fi

# Assign inputs
reference="$1"
comparison="$2"
target="$3 $4 $5"

# Setup filenames
reference_basename=$(echo "$reference" | sed -r 's/(.nii|.nii.gz)$//')
comparison_basename=$(echo "$comparison" | sed -r 's/(.nii|.nii.gz)$//')

reference_brain="${reference_basename}_brain_registered_to_helmet.nii.gz"
comparison_brain="${comparison_basename}_brain_registered_to_helmet.nii.gz"
comparison_brain_registered="${comparison_basename}_brain_registered_with_reference.nii.gz"
transform_file="${comparison_basename}_brain_registered_with_reference_transform.txt"
transform_inverse_file="${comparison_basename}_brain_registered_with_reference_transform_inverse.txt"
target_file="${comparison_basename}_brain_registered_with_reference_target_shift.txt"

# Start timer
start=$(date +%s)

# Register two segmented brain images
echo "Registering brain images..."
flirt -in $comparison_brain -ref $reference_brain -out $comparison_brain_registered -dof 6 -omat $transform_file

# Save inverse transform also
convert_xfm -omat $transform_inverse_file -inverse $transform_file

# Calculate the shifted target position and save to file
echo -e "Coordinates in Reference volume (in voxels)\n$target\n" > $target_file
echo $target | img2imgcoord -src $reference_brain -dest $comparison_brain -xfm $transform_inverse_file -vox >> $target_file

# Read file
text_contents=$(cat "$target_file")

# Extract the first set of coordinates
read x1 y1 z1 <<< $(echo "$text_contents" | sed -n '2p')

# Output the first set of coordinates to the command line
echo "First set of coordinates:"
echo "x1 = $x1, y1 = $y1, z1 = $z1"

# Extract the second set of coordinates
read x2 y2 z2 <<< $(echo "$text_contents" | sed -n '5p')

# Output the second set of coordinates to the command line
echo "Second set of coordinates:"
echo "x2 = $x2, y2 = $y2, z2 = $z2"

# Calculate the differences
dx=$(echo "scale=4; $x2 - $x1" | bc)
dy=$(echo "scale=4; $y2 - $y1" | bc)
dz=$(echo "scale=4; $z2 - $z1" | bc)

# Output the differences to the command line
echo "Differences:"
echo "dx = $dx, dy = $dy, dz = $dz"

# Write the result
echo -e "\nChange in target position" >> $target_file
echo "$dx $dy $dz" >> $target_file

# Print run time
end=$(date +%s)
runtime=$((end-start))
echo "Script completed in $runtime seconds."
