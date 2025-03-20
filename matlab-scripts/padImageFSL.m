function padImageFSL(inputFile, outputFile, padding)
%PADIMAGEFSL Pad a nifti image using fslroi.
%
% DESCRIPTION:
%     padImageFSL pads a nifti image using the fslroi command. It first
%     gets the dimensions of the input image using fslinfo, then calculates
%     new dimensions based on the specified padding. Finally, it uses
%     fslroi to pad the image, effectively expanding the image dimensions
%     and placing the original image data in the correct position. The
%     function requires the input file, output file, and padding to be
%     specified. It uses the FSL command line tools fslinfo and fslroi,
%     which must be accessible from the MATLAB command line.
%
% USAGE:
%     padImageFSL(inputFile, outputFile, padding)
%
% INPUTS:
%     inputFile     - String, filename for input image. 
%     outputFile    - String, filename for output image. 
%     padding       - Padding given as [L, R, P, A, I, S], a 1x6 array
%                     specifying the number of voxels to add on each side
%                     (Left, Right, Posterior, Anterior, Inferior,
%                     Superior).
%
% ABOUT:
%     author        - Bradley Treeby
%     date          - 2nd July 2024
%     last update   - 2nd July 2024

% Check input arguments
if nargin ~= 3
    error('Three input arguments are required.');
end

if length(padding) ~= 6
    error('Padding must be a 1x6 array [L, R, P, A, I, S].');
end

% Get the dimensions of the input image
[~, cmdout] = system(['fslinfo ' inputFile ' | grep dim1']);
xsize = str2double(regexp(cmdout, '\d+', 'match'));
[~, cmdout] = system(['fslinfo ' inputFile ' | grep dim2']);
ysize = str2double(regexp(cmdout, '\d+', 'match'));
[~, cmdout] = system(['fslinfo ' inputFile ' | grep dim3']);
zsize = str2double(regexp(cmdout, '\d+', 'match'));

% Calculate new dimensions
new_xsize = xsize + padding(1) + padding(2);
new_ysize = ysize + padding(3) + padding(4);
new_zsize = zsize + padding(5) + padding(6);

% Prepare fslroi command
cmd = sprintf('fslroi %s %s 0 %d 0 %d 0 %d', ...
    inputFile, outputFile, ...
    new_xsize, new_ysize, new_zsize);

% Execute fslroi command
[status, cmdout] = system(cmd);

% Check if the command was successful
if status ~= 0
    error('fslroi command failed with error: %s', cmdout);
end

% Now we need to shift the original data to the correct position
% We'll use fslmaths for this
shift_cmd = sprintf('fslmaths %s -mul 0 -add %s -roi %d %d %d %d %d %d 0 -1 %s', ...
    outputFile, inputFile, ...
    padding(1), xsize, padding(3), ysize, padding(5), zsize, ...
    outputFile);

[shift_status, shift_cmdout] = system(shift_cmd);

% Check if the shift command was successful
if shift_status ~= 0
    error('fslmaths command failed with error: %s', shift_cmdout);
end

fprintf('Image padded successfully. Output saved as: %s\n', outputFile);
