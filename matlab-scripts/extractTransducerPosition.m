function extractTransducerPosition(inputFile)
%EXTRACTTRANSDUCERPOSITION Extract transducer position from file.
%
% DESCRIPTION:
%     extractTransducerPosition extracts the position of the transducer
%     relative to a registration image. It does this by creating a rigid
%     transform matrix calculated using two sets of three points: one set
%     in the reference image of the transducer, and one set in the
%     registration image. The position of the points in the registration
%     image are calculed using FSL img2imgcoords. These points are saved in
%     a file called transform_mapped_points_out. The k-Plan position
%     transform is saved as kplan_transducer_position.h5.
%
%     This function was written, as directly using the registration matrix
%     save by FSL flirt proved to be difficult (the transducer appears
%     rotated and offset from the correct position).
%
% USAGE:
%     extractTransducerPosition(inputFile)
%
% INPUTS:
%     inputFile      - Filename for input image.
%
% ABOUT:
%     author         - Bradley E. Treeby
%     date           - 14th March 2023
%     last update    - 12th March 2024

% Get input file if not provided.
if (nargin == 0) || isempty(inputFile)
    [file,path] = uigetfile('*.nii; *.nii.gz', 'Select NIFTI image');
    if file == 0
        return
    else
        inputFile = fullfile(path, file);
    end
else
    validateattributes(inputFile, {'char'}, {'mustBeFile'});
end

% The original points in the rastered image are:
%     200 200 50
%     210 200 50
%     200 210 50
% These correspond to the following points in the transducer coordinate
% system where we want the mapping from:
%     0 0 0
%     10 0 0
%     0 10 0
pointsRef = [0, 0, 0; 10, 0, 0; 0 10 0].';

% Get the image voxel spacing
nii = load_nii(inputFile);
pixdim = nii.hdr.dime.pixdim(2:4);

% Filename for points file.
[pathname, ~, ~] = fileparts(inputFile);
pointsFile = fullfile(pathname, 'helmet-registration/transform_mapped_points_out.txt');

% Open the file for reading.
fid = fopen(pointsFile, 'r');

% Read and discard the header line added by img2imgcoords ("Coordinates in
% Destination volume (in voxels)")
fgetl(fid);

% Read the position of the points in the registration image.
pointsImg = reshape(fscanf(fid, '%f'), [3, 3]);

% Scale by the pixel dimensions
pointsImg(1, 1:3) = pointsImg(1, 1:3) * pixdim(1);
pointsImg(2, 1:3) = pointsImg(2, 1:3) * pixdim(2);
pointsImg(3, 1:3) = pointsImg(3, 1:3) * pixdim(3);

% Close the file.
fclose(fid);

% Compute rigid transform.
tform = computeRigidTransform(pointsRef, pointsImg);

% Convert mm to m.
tform(1:3, 4) = 1e-3 * tform(1:3, 4);

% Save as HDF5 file.
filename = fullfile(pathname, 'kplan_transducer_position.kps');
if exist(filename, "file")
    delete(filename);
end

h5create(filename, '/1/position_transform', [4, 4, 1], 'DataType', 'single');
h5write(filename, '/1/position_transform', single(tform));
h5writeatt(filename, '/1', 'transform_label', 'Helmet transform', 'TextEncoding', 'system');

h5writeatt(filename, '/', 'application_name', 'k-Plan', 'TextEncoding', 'system');
h5writeatt(filename, '/', 'file_type', 'k-Plan Transducer Position', 'TextEncoding', 'system');
h5writeatt(filename, '/', 'number_transforms', uint64(1));
