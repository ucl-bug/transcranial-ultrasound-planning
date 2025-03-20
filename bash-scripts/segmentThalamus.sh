#!/bin/bash
# Script to extract the LGN maps from a input T1 image using Freesurfer
#
# Usage:
#
#     segmentThalamus inputfile.nii
#
# To install FreeSurfer, download .deb package and install using:
#
#     sudo dpkg-deb -x freesurfer_ubuntu22-7.3.2_amd64.deb /mnt/Software/FreeSurfer/7.3.2
#
# To add this directory and FreeSurfer to path, first run:
#
#     cd ~/
#     nano .bash_profile
#
# Then add:
#
#     export FREESURFER_HOME=/mnt/Software/FreeSurfer/7.3.2
#     source $FREESURFER_HOME/SetUpFreeSurfer.sh
#     export PATH="/mnt/Software/MR-Processing:$PATH"
#
# author: Bradley Treeby
# date: 29 March 2022
# last update: 16th February 2023

# echo filename
echo "====================================================="
echo "RUNNING FS LGN ATLAS REGISTRATION - VER 16-FEB-2023"
echo "====================================================="

subj_dir="/mnt/Simulations/FreeSurferSubjectsDir/"
export SUBJECTS_DIR=$subj_dir
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=16
export WRITE_POSTERIORS=1

# ------------------
# Filenames
# ------------------

# current dir
starting_dir="$(pwd)"

# get filename without path and extension
pathname=$(dirname -- "$1")
filename=$(basename -- "$1")
filename_no_ext="${filename%%.*}"

# display filenames
echo "Input filename: ${filename}"
echo "Input pathname: ${pathname}"

# cd into folder
cd "${pathname}"

# output folder
out_folder="${filename_no_ext}_thalamus_segmentations"

# delete folders if it already exists
rm -R -f "${subj_dir}/${filename_no_ext}"
rm -R -f "${pathname}/${out_folder}"
mkdir -p "${pathname}/${out_folder}"

# ------------------
# Processing
# ------------------

# call free surfer
recon-all -all -cw256 -i "${pathname}/${filename}" -subject "${filename_no_ext}" -openmp 16 |& tee "${pathname}/${out_folder}/recon_all_log.txt"
segmentThalamicNuclei.sh "${filename_no_ext}" |& tee "${pathname}/${out_folder}/segmentThalamicNuclei_log.txt"

# New syntax:
# segment_subregions thalamus --cross "${filename_no_ext}" --threads 16 |& tee "${pathname}/${out_folder}/segmentThalamicNuclei_log.txt"


# ------------------
# Cleanup
# ------------------

# convert and copy hard segmentations
echo "Converting outputs to nifti..."
mri_convert "${subj_dir}/${filename_no_ext}/mri/ThalamicNuclei.v12.T1.mgz" "${pathname}/${out_folder}/ThalamicNuclei.v12.T1.nii.gz" --like "${pathname}/${filename}"	
mri_convert "${subj_dir}/${filename_no_ext}/mri/ThalamicNuclei.v12.T1.FSvoxelSpace.mgz" "${pathname}/${out_folder}/ThalamicNuclei.v12.T1.FSvoxelSpace.nii.gz" --like "${pathname}/${filename}"

# convert and copy soft segmentations
for in_name in "${subj_dir}/${filename_no_ext}/mri/posterior_"*; do
	in_name_short=$(basename -- "${in_name}")
	in_name_short="${in_name_short%%.*}"
    echo "Converting ${in_name}"
    mri_convert "${in_name}" "${pathname}/${out_folder}/${in_name_short}.nii.gz" --like "${pathname}/${filename}"	
done

# delete free surfer subject directory
# rm -R -f "${subj_dir}/${filename_no_ext}"
