# Setup and installation

Some of the scripts rely on [FreeSurfer](https://surfer.nmr.mgh.harvard.edu/), [3D Slicer](https://www.slicer.org/), and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSL).

If you are running on the BUG servers, you can skip to the `Setting up the bash scripts` section.

## Installing FreeSurfer
To install FreeSurfer, download the debian Ubuntu package from [here](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation). Install using:

```
sudo dpkg-deb -x freesurfer_ubuntu22-7.4.0_amd64.deb /mnt/Software/FreeSurfer/7.4.0
```

Note, this may install the application with several un-needed nested folders. Bring the files up to the correct folder level after the install (so that `SetUpFreeSurfer.sh` is in the root directory).

It may also be necessary to install `csh` and `tcsh` to run the bash scripts.

```
sudo apt-get install csh
sudo apt-get install tcsh
```

For some scripts, the MATLAB redistributable may also be required. Follow the [instructions](https://surfer.nmr.mgh.harvard.edu/fswiki/MatlabRuntime) to install the correct version, e.g.,

```
cd $FREESURFER_HOME/bin
sudo curl https://raw.githubusercontent.com/freesurfer/freesurfer/dev/scripts/fs_install_mcr -o fs_install_mcr
sudo chmod +x fs_install_mcr
sudo FREESURFER_HOME=$FREESURFER_HOME ./fs_install_mcr R2019b
```

## Installing FSL

To install FSL, download the python installer from [here](). Install using:

```
python fslinstaller.py -d /mnt/Software/FSL/6.0.6.5 -n
```

## Installing 3D Slicer

TBD

## Setting up the bash scripts on Linux servers

To use the scripts in the `bash-scripts` folder from the command line on Linux servers, add the paths to your bash profile file.

1. Open profile file

    ```
    nano ~/.bash_profile
    ```

2. Add the `bash-scripts` folder to the path as follows (changing the paths as appropriate)
   
    ```
    export PATH="/home/btreeby/Drive/Repos/k-stim-image-processing/bash-scripts:$PATH"
    ```

    If you don't already have FSL, FreeSurfer, and dcm2niix setup, also add the following (again changing the paths as appropriate).

    FSL:

    ```
    FSLDIR=/mnt/Software/FSL
    . ${FSLDIR}/etc/fslconf/fsl.sh
    PATH=${FSLDIR}/bin:${PATH}
    export FSLDIR PATH
    ```

    FreeSurfer:

    ```
    export FREESURFER_HOME=/mnt/Software/FreeSurfer/7.3.2
    source $FREESURFER_HOME/SetUpFreeSurfer.sh
    ```

    dcm2niix:

    ```
    export PATH="/mnt/Software/dcm2niix:$PATH"
    ```
    
    Slicer:
    
    ```
    export PATH="/mnt/Software/Slicer/Slicer-5.0.2-linux-amd64:$PATH"
	export PATH="/mnt/Software/Slicer/Slicer-5.0.2-linux-amd64/bin:$PATH"
    ```

3. Save by pressing `CTRL + X`, type `Y`, then press enter
4. Exit and re-login to server
5. Depending on what operating system and git settings used to clone / download the repository, it may be necessary to change the line endings of the bash scripts. Inside the `bash-scripts` directory, call
    ```
    dos2unix *.sh
    ```
