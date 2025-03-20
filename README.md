# Ultrasound system for precise neuromodulation of human deep brain circuits: MR and CT Image Processing Tools for Targeting and Registration

[![bioRxiv](https://img.shields.io/badge/bioRxiv-10.1101/2024.06.08.597305-blue)](https://doi.org/10.1101/2024.06.08.597305) [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

This repository contains scripts and utilities for processing MR and CT images used with our advanced transcranial ultrasound system, a 256-element array designed for precise deep brain neuromodulation in humans. These tools were written by Bradley Treeby, University College London.

## Overview

The tools in this repository support a complete workflow for:
- Converting DICOM to NIfTI format
- Registering brain and positioning images to the helmet reference frame
- Processing planning images for transducer targeting
- Real-time replanning between sessions to maintain targeting accuracy
- Segmenting thalamic nuclei using FreeSurfer
- Computing targeting shifts for re-registration

## Research Publication

These scripts were developed for and used in the neuromodulation system described in the paper:

`Martin, E., Roberts, M., Grigoras, I.F., Wright, O., Nandi, T., Rieger, S.W., Campbell, J., den Boer, T., Cox, B.T., Stagg, C.J. and Treeby, B.E., "Ultrasound system for precise neuromodulation of human deep brain circuits." bioRxiv, https://doi.org/10.1101/2024.06.08.597305, 2024.`

If you find these tools useful for your reserach, please consider citing our paper.

## Repository Structure

- **Bash Scripts**: Collection of shell scripts for image processing and registration
  - `convertDicoms.sh` - Convert DICOM images to NIfTI format
  - `registerWithHelmet.sh` - Register T1 images with the helmet reference image
  - `registerWithHelmetSaveAll.sh` - Register T1 images with additional outputs
  - `segmentThalamus.sh` - Extract thalamic nuclei maps using FreeSurfer
  - `computeTargetShift.sh` - Calculate shifts in target position
  - `processImagesForPlanning.sh` - Main workflow script for image processing

- **MATLAB Functions**: Support functions for image processing
  - `resliceImageToRAS.m` - Reslice and pad NIfTI images
  - `extractTransducerPosition.m` - Generate transformations for k-Plan
  - `computeRigidTransform.m` - Compute transformations between coordinate systems

## Documentation

- [Setup and Installation](docs/setup.md) - How to install required software and set up scripts
- [Image Conversion](docs/image-conversion.md) - Converting DICOM images to NIfTI format
- [Processing Planning Images](docs/processing-planning-images.md) - Detailed workflow for planning
- [k-Plan Simulations](docs/k-plan.md) - Setting up k-Plan simulations
- [Real-Time Replanning](docs/replanning.md) - Protocol for between-session adjustments

## Requirements

- FSL (FMRIB Software Library)
- FreeSurfer
- 3D Slicer
- MATLAB (for some processing steps)
- dcm2niix (for DICOM conversion)

For complete setup instructions, see the [Setup and Installation](docs/setup.md) guide.

## Usage

A typical workflow involves:
1. Converting DICOM images using `convertDicoms.sh`
2. Segmenting thalamic nuclei with `segmentThalamus.sh`
3. Creating a subject-specific script based on `processImagesForPlanningS00X.sh`
4. Running the processing script to generate targeting data
5. Using `computeTargetShift.sh` for between-session replanning

See [Processing Planning Images](docs/processing-planning-images.md) for detailed instructions.