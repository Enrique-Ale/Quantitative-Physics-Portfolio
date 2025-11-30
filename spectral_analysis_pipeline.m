%% AUTOMATED SPECTRAL ANALYSIS PIPELINE (ETL)
%  Project: Photoluminescence Analysis of Single Crystal Silicon Thin Films
%  Author: Enrique A. Alcántara
%  Description: 
%     This script functions as an ETL (Extract, Transform, Load) pipeline.
%     It automates the ingestion of raw sensor data from Quartz-substrate 
%     Silicon samples, performs data cleaning (duplicate removal, sorting),
%     and generates comparative spectral visualizations.

clear; clc; close all;

%% 1. CONFIGURATION & DATA INGESTION
% Automate file reading (Reads all files matching pattern, scalable solution)
filePattern = 'LAB IV_*.txt'; 
files = dir(filePattern);

if isempty(files)
    warning('No files found matching pattern: %s', filePattern);
else
    fprintf('Found %d files for processing.\n', length(files));
end

% Set import options for raw data (Tab-delimited)
opts = delimitedTextImportOptions("NumVariables", 2);
opts.DataLines = [32, Inf]; 
opts.Delimiter = "\t";
opts.VariableNames = ["Energy_eV", "Intensity"];
opts.VariableTypes = ["double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Visualization setup
figure('Color', 'white', 'Name', 'Batch Spectral Analysis');
hold on;

% Pre-calculate number of files to avoid repeating length()
num_files = length(files);

colors = lines(num_files); 

% Pre-allocate Cell Array for text strings
% We reserve space for 'num_files' entries.
legendEntries = cell(num_files, 1);

%% 2. BATCH PROCESSING LOOP (ETL Core)
disp('>>> Starting Batch Processing...');

% Pre-allocate array for speed (Memory Management)
% We create a vector of Zeros with the same size as the number of files.
num_files = length(files);
max_intensities = zeros(num_files, 1);

for i = 1:length(files)
    fileName = files(i).name;
    
    % --- Step 2.1: EXTRACT (Import Data) ---
    try
        dataTable = readtable(fileName, opts);
    catch ME
        warning('Failed to import: %s. Skipping.', fileName);
        continue;
    end
    
    % --- Step 2.2: TRANSFORM (Data Cleaning & Advanced Despiking) ---
    raw_E = dataTable.Energy_eV;
    raw_I = dataTable.Intensity;
    
    % A. Remove NaN/Infinite values
    valid_idx = isfinite(raw_E) & isfinite(raw_I);
    clean_E = raw_E(valid_idx);
    clean_I = raw_I(valid_idx);
    
    % B. Sort and Unique
    [sorted_E, sortIdx] = sort(clean_E, 'ascend');
    sorted_I = clean_I(sortIdx);
    [final_E, uniqueIdx] = unique(sorted_E);
    final_I = sorted_I(uniqueIdx);
    
    % C. DESPIKING (Outlier Removal)
    [clean_signal, ~] = filloutliers(final_I, 'pchip', 'movmedian', 15);
    
    % D. NOISE REDUCTION (Optional Polish)
    final_signal = smoothdata(clean_signal, 'gaussian', 5);
    
    % --- Step 2.3: LOAD/VISUALIZE ---
    plot(final_E, final_signal, 'LineWidth', 1.2, 'Color', colors(i,:));
    
    % Store the max value of the CLEANED signal
    max_intensities(i) = max(final_signal);
    
    % Legend formatting
    [~, name, ~] = fileparts(fileName);
    legendEntries{i} = strrep(name, '_', ' ');
end

hold off;

%% 3. FINAL VISUALIZATION SETTINGS
% Context: Single Crystal Silicon Thin Films on Quartz
title('Photoluminescence Spectra: Single Crystal Silicon Thin Films', 'FontSize', 12);
xlabel('Energy (eV)', 'FontSize', 10);
ylabel('Intensity (Arbitrary Units)', 'FontSize', 10);

grid on;
legend(legendEntries, 'Location', 'best', 'Interpreter', 'none');

% --- SMART SCALING (Auto-Zoom) ---
% Filter out zeros (from failed imports) to avoid skewing the median
valid_intensities = max_intensities(max_intensities > 0);

if ~isempty(valid_intensities)
    % Focus on the median peak intensity to avoid outliers setting the scale
    y_limit = median(valid_intensities) * 1.5; 
    ylim([0, y_limit]);
    xlim([1.3 2.3]); 
end

disp('>>> Pipeline Execution Completed.');