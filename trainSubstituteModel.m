% ----------------------------------------------------------------------
%  This scripts trains the substitute BIQA model used in:
%  J. Korhonen, J. You: "Adversarial Attacks against Blind Image Quality 
%  Assessment Models", QoEVMA'22
%
%  KoNIQ-10k dataset (in 512x384 resolution) is required.   
%
%  Written by Jari Korhonen, Shenzhen University, 2021.
%

% MODIFY HERE: -8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--
% Set the path to the KoNIQ dataset (512x384 resolution) here!
path = 'g:\\koniq\\smallver';
% --8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--

% Load KoNIQ-10k metadata and initialize
[mosdata,datatxt] = xlsread(sprintf('%s\\koniq10k_scores_and_distributions.csv',path));
sqlen = size(mosdata,1);
sq = randperm(sqlen);

% Make table with images for training (all images included)
filenames = {};
mos = [];
for i=sq(1:ceil(1*sqlen)) 
    filenames = [filenames; sprintf('%s\\%s',path,datatxt{i+1,1})];
    mos = [mos; mosdata(i,9)/100]; % Normalize Z-scores to [0,1]
end
T = table(filenames, mos);

% Make table with images for validation (not really needed, because all 
% the images are used for training in this case)
filenames = {};
mos = [];
for i=sq(ceil(0.8*sqlen)+1:sqlen) 
    filenames = [filenames; sprintf('%s\\%s',path,datatxt{i+1,1})];
    mos = [mos; mosdata(i,9)/100]; % Normalize Z-scores to [0,1]
end
Tval = table(filenames, mos);  

% Load resnet50    
net = resnet50;

lgraph = layerGraph(net);   

% Change input resolution to 512x384
norm_mean = lgraph.Layers(1).Mean;
norm_mean = imresize(norm_mean,[384 512]);
lgraph = replaceLayer(lgraph,'input_1',imageInputLayer([384 512 3],'Normalization','zerocenter','Name','input_1','Mean',norm_mean));

% Replace classification layers with new layers for regression 
lgraph = removeLayers(lgraph,'fc1000');
lgraph = removeLayers(lgraph,'fc1000_softmax');
lgraph = removeLayers(lgraph,'ClassificationLayer_fc1000');    
headLayers = layerGraph([...
       dropoutLayer(0.25,'Name','dropout')
       fullyConnectedLayer(1,'WeightLearnRateFactor',2,'BiasLearnRateFactor',2,'Name','fc_output','WeightsInitializer','narrow-normal')       
       sigmoidLayer('Name','sigmoid')
       regressionLayer('Name','output')]);
layers = [lgraph.Layers
          headLayers.Layers];
connections = [lgraph.Connections
               headLayers.Connections];

% Adjust learning rates for lower layers
layers(1:5) = setLayerWeights(layers(1:5),0.25);    
layers(6:36) = setLayerWeights(layers(6:36),0.5); 
layers(37:140) = setLayerWeights(layers(37:140),0.75); 

% Finally, assemble the modified model
lgraph = createLgraphUsingConnections(layers,connections);
lgraph = connectLayers(lgraph, 'avg_pool', 'dropout');

 % Define training options
 options = trainingOptions('sgdm', ...
        'MiniBatchSize',16, ...        
        'MaxEpochs',2, ...
        'L2Regularization',0.01, ...
        'InitialLearnRate',0.0005, ...
        'Shuffle','every-epoch', ...
        'ExecutionEnvironment','gpu', ...
        'ValidationData',Tval, ...
        'ValidationFrequency',200, ...
        'ResetInputNormalization',false, ...
        'Verbose',false, ...
        'Plots','training-progress');

% Train the model
model = trainNetwork(T,'mos',lgraph,options);

% Save the model
save('IQA_MODEL_01.mat','model');

% eof