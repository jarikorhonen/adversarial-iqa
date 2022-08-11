% ----------------------------------------------------------------------
% This scripts makes resized (512x384 resolution) version of the
% original SPAQ dataset.

% MODIFY HERE: -8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--
% Set the path to the original SPAQ dataset here
in_path = 'g:\\spaq\\testimage';
% Set the path to the resized SPAQ dataset here
out_path = 'j:\\spaq';
% --8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--

for i=1:11125
    im = imread(sprintf("%s\\%05d.jpg", in_path, i));
    if size(im,1)>size(im,2)
        im = imrotate(im,90);
    end
    im = imresize(im,[384,512]);
    imwrite(im,sprintf("%s\\%05d.png", out_path, i));
end

% eof