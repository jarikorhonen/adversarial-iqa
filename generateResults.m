%------------------------------------------------------------------------
%  Script for generating the predicted results for the adversarial images 
%  used in:
%  J. Korhonen, J. You: "Adversarial Attacks against Blind Image Quality 
%  Assessment Models", QoEVMA'22
%
%  Requires that substitute model  IQA_MODEL_01.mat and the adversarial 
%  images are available.
%
%  Written by Jari Korhonen, Shenzhen University, 2021.
%

% MODIFY HERE: -8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--
% Define the folder for the adversarial images here
folder = 'j:\\adversarials'; 
% Define output file for the results
outf = fopen('result.csv','w');
% --8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--

% Load the substitute BIQA model
load('IQA_MODEL_01.mat', 'model');

% Loop through all the adversarial images
files = dir(sprintf('%s\\*.png', folder));
for i=1:length(files)
    fname = sprintf('%s\\%s', folder, files(i).name);
    image = imread(fname);

    % Predict MOS and store in file
    mos = predict(model, uint8(image));
    fprintf(outf, '%s,%1.4f\n', files(i).name, mos*4 + 1);
end
fclose(outf);

% eof

