%-------------------------------------------------------------------------
%  Script for generating adversarial images used in:
%  J. Korhonen, J. You: "Adversarial Attacks against Blind Image Quality 
%  Assessment Models", QoEVMA'22
%
%  Requires that substitute model IQA_MODEL_01.mat has been trained
%  and SPAQ dataset (512x384 resolution) is installed.
%
%  Written by Jari Korhonen, Shenzhen University, 2021.
%

% MODIFY HERE: -8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--
% Change the folder here for SPAQ dataset (containing images and metadata)
spaq_folder = 'e:\\spaq';
% Change the output folder for generated adversarial images here
out_folder = 'j:\\adversarials'; 
% --8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--

% Read metadata
[mosdata,datatxt] = xlsread(sprintf('%s\\mos_spaq.xlsx', spaq_folder));
filenames = datatxt(2:end,1);

% Read the pre-trained substitute model
load('IQA_MODEL_01.mat', 'model');
[~,mos_idx]=sort(mosdata(:,1),'ascend');

% Generate low quality SPAQ adversarial images
low = mos_idx(1:500); 
for i=1:length(low)
    infilename = sprintf('%s\\%05d.png', spaq_folder, low(i));
    outfilename = sprintf('%s\\spaq_low_%02d_orig.png',out_folder, i);
    im = imread(infilename);
    imwrite(im, outfilename);
    outfilename = sprintf('%s\\spaq_low_%02d_01.png',out_folder,i);
    generateAdversaryImage(model, 0.1, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_low_%02d_05.png',out_folder,i);
    generateAdversaryImage(model, 0.5, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_low_%02d_20.png',out_folder,i);
    generateAdversaryImage(model, 2, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_low_%02d_50.png',out_folder,i);
    generateAdversaryImage(model, 5, infilename, outfilename);
end

% Generate medium quality SPAQ adversarial images
med = mos_idx(5501:6000); 
for i=1:length(med)
    infilename = sprintf('%s\\%05d.png', spaq_folder, med(i));
    outfilename = sprintf('%s\\spaq_med_%02d_orig.png',out_folder,i);
    im = imread(infilename);
    imwrite(im, outfilename);
    outfilename = sprintf('%s\\spaq_med_%02d_01.png',out_folder,i);
    [origmos,thismos] = generateAdversaryImage(model, 0.1, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_med_%02d_05.png',out_folder,i);
    generateAdversaryImage(model, 0.5, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_med_%02d_20.png',out_folder,i);
    generateAdversaryImage(model, 2, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_med_%02d_50.png',out_folder,i);
    generateAdversaryImage(model, 5, infilename, outfilename);
end

% Generate high quality SPAQ adversarial images
high = mos_idx(end-499:end); 
for i=1:length(high)
    infilename = sprintf('%s\\%05d.png', spaq_folder, high(i));
    outfilename = sprintf('%s\\spaq_hgh_%02d_orig.png',out_folder,i);
    im = imread(infilename);
    imwrite(im, outfilename);
    outfilename = sprintf('%s\\spaq_hgh_%02d_01.png',out_folder,i);
    generateAdversaryImage(model, 0.1, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_hgh_%02d_05.png',out_folder,i);
    generateAdversaryImage(model, 0.5, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_hgh_%02d_20.png',out_folder,i);
    generateAdversaryImage(model, 2, infilename, outfilename);
    outfilename = sprintf('%s\\spaq_hgh_%02d_50.png',out_folder,i);
    generateAdversaryImage(model, 5, infilename, outfilename);
end

% Generate adversarial images initialized with white noise
rng(666);
for i=1:10
    nlow = randi([0,254],1);
    nhigh = randi([nlow+1,255],1);
    noiseim = randi([nlow,nhigh],[384,512,3]);
    infilename = sprintf('%s\\noise_%02d_orig.png',out_folder,i);
    imwrite(double(noiseim)/255, infilename);
    outfilename = sprintf('%s\\noise_%02d_01.png',out_folder,i);
    generateAdversaryImage(model, 0.1, infilename, outfilename);
    outfilename = sprintf('%s\\noise_%02d_05.png',out_folder,i);
    generateAdversaryImage(model, 0.5, infilename, outfilename);
    outfilename = sprintf('%s\\noise_%02d_20.png',out_folder,i);
    generateAdversaryImage(model, 2, infilename, outfilename);
    outfilename = sprintf('%s\\noise_%02d_50.png',out_folder,i);
    generateAdversaryImage(model, 5, infilename, outfilename);
end

% Generate random synthetic sharp images
rng(666);
for i=1:10
    
    % Select the color randomly
    color1i = randi([0,1],[3,1]);
    color2i = randi([0,1],[3,1]);
    while color1i(1)==color2i(1) && color1i(2)==color2i(2) && color1i(3)==color2i(3)
        color2i = randi([0,1],3);
    end

    limits = [0,50,75,100,125];
    for j=1:5
        % Scale colors
        color1 = limits(j).*(color1i==0) + (255-limits(j)).*(color1i==1);
        color2 = limits(j).*(color2i==0) + (255-limits(j)).*(color2i==1);
        im(:,:,1) = ones(384,512).*color1(1);
        im(:,:,2) = ones(384,512).*color1(2);
        im(:,:,3) = ones(384,512).*color1(3);

        for k=1:800
            x_st = randi([-20,532],1);
            x_en = randi([x_st+1,x_st+30],1);
            y_st = randi([-20,404],1);
            y_en = randi([y_st+1,y_st+30],1);
            color = color2;
%             if(rand()<0.5)
%                 color = color2;
%             end
            im(max(y_st,1):min(384,y_en),max(x_st,1):min(512,x_en),1) = color(1);
            im(max(y_st,1):min(384,y_en),max(x_st,1):min(512,x_en),2) = color(2);
            im(max(y_st,1):min(384,y_en),max(x_st,1):min(512,x_en),3) = color(3);
        end
        outfilename = sprintf('%s\\sharp_%02d_%02d.png',out_folder,i,j);
        imwrite(double(im)/255, outfilename);
    end
end

% eof
