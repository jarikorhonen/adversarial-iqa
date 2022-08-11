%------------------------------------------------------------------------
%  Script for displaying results for Tables 1-5 in:
%  J. Korhonen, J. You: "Adversarial Attacks against Blind Image Quality 
%  Assessment Models", QoEVMA'22
%
%  Requires that the results for individual images have been computed and 
%  they are available in a CSV file.
%
%  Written by Jari Korhonen, Shenzhen University, 2021.
%

% MODIFY HERE: -8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--
% Define here the results file (e.g. "res_ours.csv" or "res_koncept.csv")
resultfile = 'j://hyperiqa_x.csv';
% --8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--8<--

% Read the results from the file
[results,filenames] = xlsread(resultfile);

% Loop through the results and compute for each class
label_init = ["spaq","spaq_low","spaq_med","spaq_hgh","noise"];
label_val = ["orig.png","01.png","05.png","20.png","50.png"];
for k=1:length(label_init)
    mos_vals = {[],[],[],[],[]};
    for i=1:length(filenames)
        if strcmp(filenames{i}(1:strlength(label_init(k))), label_init(k))
            for j=1:length(label_val)
                if strcmp(filenames{i}(end-strlength(label_val(j))+1:end), label_val(j))
                    mos_vals{j} = [mos_vals{j};results(i)];
                end
            end
        end
    end
    
    % Print the results
    fprintf("Mean results for %s\n", label_init(k));
    for i=1:5
        fprintf("*%s: %2.2f \n", label_val(i), mean(mos_vals{i}));
    end
    fprintf("-----------------------\n");
end

label_init = "sharp";
label_val = ["01.png","02.png","03.png","04.png","05.png"];
mos_vals = {[],[],[],[],[]};
for i=1:length(filenames)
    if strcmp(filenames{i}(1:strlength(label_init)), label_init)
        for j=1:length(label_val)
            if strcmp(filenames{i}(end-strlength(label_val(j))+1:end), label_val(j))
                mos_vals{j} = [mos_vals{j};results(i)];
            end
        end
    end
end
    
% Print the results
fprintf("Mean results for synthetic sharp images\n");
for i=1:5
    fprintf("*%s: %2.2f\n", label_val(i), mean(mos_vals{i}));
end
fprintf("\n");

% eof

