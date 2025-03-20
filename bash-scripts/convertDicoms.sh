#!/bin/bash

# Converts dicom images in current folder to NIFTIs using dcm2niix. The dicom
# images are assumed to have the signature 001_0%s_0%p. The converted images
# are stored in a subfolder called "converted".

# Get the current directory
input_folder=$(pwd)

# Define the subdirectory
output_folder="${input_folder}/converted"

# Ensure output_folder exists
mkdir -p "$output_folder"

# Call dcm2niix with the specified parameters
dcm2niix -z n -d 0 -f 001_0%s_0%p -o "$output_folder" "$input_folder"
