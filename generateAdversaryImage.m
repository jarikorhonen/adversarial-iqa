%--------------------------------------------------------------------
%  This function implements the adversarial image generator as
%  described in:
%  J. Korhonen, J. You: "Adversarial Attacks against Blind Image Quality 
%  Assessment Models", QoEVMA'22
%
%  Inputs: 
%          iqa_model:     the substitute IQA model
%          learning_rate: learning rate for Adam optimizer
%          input_im:      file path to load the input image
%          output_im:     file path to save the output image
%
%  As an output, function saves adversarial image in output_im
%
%  Written by Jari Korhonen, Shenzhen University, 2021.
%

function [origmos,finalmos] = generateAdversaryImage(iqa_model, ...
    learning_rate, input_im, output_im)

    fprintf("Input: %s\nOutput: %s\n",input_im, output_im);
    
    % Read the initial image
    contentImage = im2double(imread(input_im));

    % This hack is needed to make BatchNormalizationLayer to work 
    % correctly in custom loop as dlnetwork
    lgraph = layerGraph(iqa_model);
    for l = 1:length(lgraph.Layers)
        layer = lgraph.Layers(l);
        if isa(layer,'nnet.cnn.layer.BatchNormalizationLayer')
            scales = layer.Scale ./ sqrt(layer.TrainedVariance+layer.Epsilon);
            offsets = -layer.Scale .* layer.TrainedMean ./ ...
                     sqrt(layer.TrainedVariance+layer.Epsilon) + layer.Offset; 
            lgraph = replaceLayer(lgraph,layer.Name,scalingLayer( ...
                     "Name",layer.Name,"Bias",offsets,"Scale",scales));
        end
    end

    % Change the input layer size to match with input image
    imageSize = size(contentImage);
    norm_mean = iqa_model.Layers(1).Mean;
    norm_mean = imresize(norm_mean,[imageSize(1) imageSize(2)]);
    lgraph = replaceLayer(lgraph,'input_1',imageInputLayer( ...
        imageSize,'Normalization','zerocenter','Name','input_1','Mean',norm_mean));
    lgraph = removeLayers(lgraph,{'dropout','output'});
    lgraph = connectLayers(lgraph,'avg_pool','fc_output');
    dlNet = dlnetwork(lgraph);

    % Make spatial activity map for the original content image
    mapImg = makeSpatialActivityMap(contentImage);

    % Convert images into dlarrays
    contentImg = single(contentImage.*255);
    transferImg = contentImg;
    dlContent = dlarray(contentImg,'SSC');
    dlTransfer = dlarray(transferImg,'SSC');   
    dlMap = dlarray(mapImg,'SSC');
    if canUseGPU
        dlContent = gpuArray(dlContent);
        dlTransfer = gpuArray(dlTransfer);
        dlMap = gpuArray(dlMap);
    end
    dlOutput = dlTransfer;

    % Get the predicted MOS for the initial image
    dlres = forward(dlNet,dlContent,'Outputs','sigmoid');
    origmos = dlres;
    fprintf('Initial predicted MOS [0,1]: %1.2f\n', origmos); 

    % Initialize training options and convergence criteria    
    trailingAvg = [];
    trailingAvgSq = [];
    minimumLoss = inf;
    minNumIterations = 20;
    maxNumIterations = 100;
    convergenceCrit = 2;
    convergenceCnt = 0;
    iteration = 1;

    % Image update main loop
    while (iteration < minNumIterations) || (iteration < maxNumIterations && ...
                                             convergenceCnt < convergenceCrit)
        
        % Evaluate the transfer image gradients 
        [grad,loss] = dlfeval(@imageGradients,dlNet,dlTransfer);    
        grad = grad .* dlMap;
        [dlTransfer,trailingAvg,trailingAvgSq] = adamupdate( ...
            dlTransfer, grad, trailingAvg, trailingAvgSq, iteration, learning_rate);

        % Update if loss decreases
        if loss < minimumLoss
            minimumLoss = loss;
            dlOutput = dlTransfer;
%             fprintf("New MOS: %1.2f\n", (1-loss)*4 + 1);
            convergenceCnt = 0;
        else
            convergenceCnt = convergenceCnt + 1;
        end

        % Display the transfer image regularly 
%         if mod(iteration,10) == 0 || (iteration == 1)
% 
%             transferImage = gather(extractdata(dlTransfer));
%             imshow(imtile({uint8(contentImg),uint8(transferImage)}, ...
%                 'GridSize',[1 2],'BackgroundColor','w'));
%             title(['Transfer Image After Iteration ',num2str(iteration)])
%             axis off image
%             drawnow
%         end  

        % Increase iteration counter
        iteration = iteration + 1;
    
    % End of the main loop
    end

    % Display final predicted MOS
    dlres = forward(dlNet,dlOutput,'Outputs',{'sigmoid'});
    finalmos = dlres;
    fprintf('Final predicted MOS [0,1]: %1.2f\n', finalmos); 
    
    % Save the output image
    outImage = uint8(gather(extractdata(dlOutput)));
%     imshow(imtile({uint8(contentImg),outImage}, ...
%         'GridSize',[1 2],'BackgroundColor','w'));
    imwrite(outImage,output_im);
    imwrite(contentImage,'cntnt.png');
end

% Function to obtain image gradients with Matlab automatic differentiation
function [gradients,loss] = imageGradients(dlNet, dlTransfer)
 
    % Extract loss from the transfer image
    dlres = forward(dlNet,dlTransfer,'Outputs',{'sigmoid'});
    loss = 1-dlres;
    gradients = dlgradient(loss,dlTransfer);
end

% Function to make the spatial activity map
function out_im = makeSpatialActivityMap(in_im)

    % Apply Sobel filter
    H = [-1 -2 -1; 0 0 0; 1 2 1]./8;
    im = rgb2ycbcr(in_im);
    im_sob = (imfilter(im(:,:,1),H).^2 + imfilter(im(:,:,1),H').^2);
    im_zero = zeros(size(im_sob,1),size(im_sob,2));
    im_zero(2:end-1,2:end-1) = im_sob(2:end-1,2:end-1);
    maxval = max(max(im_zero));

    % Special case: maximum value of activity map is zero
    if maxval == 0
        im_zero = im_zero + 1;
        maxval = 1;
    end
    im_sob = im_zero./maxval; % Normalize

    % Dilate kernel (5x5)
    DF = [0 1 1 1 0; 
          1 1 1 1 1; 
          1 1 1 1 1; 
          1 1 1 1 1 ; 
          0 1 1 1 0];

    % Dilate to make the final spatial activity map
    out_im = imdilate(im_sob,DF);
end

% eof
