%% OPTICAL CONSTANTS ANALYSIS (ZnTe) - SWANEPOEL METHOD
%  Author: Enrique A. Alcántara
%  Description: 
%     Analyzes the transmission spectrum of Zinc Telluride (ZnTe) thin films.
%     Implements the Swanepoel Method using interference fringes to derive:
%       1. Refractive Index (n) and dispersion via Cauchy model.
%       2. Film Thickness (d).
%       3. Absorption Coefficient (alpha).
%       4. Optical Band Gap (Eg) for Direct transitions.

clear; clc; close all;

%% 1. CONFIGURATION & DATA INGESTION
% Import settings for raw spectral data
opts = delimitedTextImportOptions("NumVariables", 2);
opts.DataLines = [87, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["Wavelength", "Transmittance"];
opts.VariableTypes = ["double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Load Dataset
% Note: Ensure 'ZNTE.SP' is in the working directory
try
    dataTable = readtable("ZNTE.SP", opts);
    lambda = dataTable.Wavelength;      % nm
    T_raw = dataTable.Transmittance;    % %T
    disp('Data loaded successfully.');
catch
    error('File ZNTE.SP not found.');
end

%% 2. MINIMA DETECTION (Interference Fringes)
% Step 2.1: Automatic Detection using Moving Average smoothing
T_smooth = smoothdata(T_raw, 'movmean', 16);
T_inverted = -T_smooth; % Invert to find valleys using findpeaks
[~, locs] = findpeaks(T_inverted, 'MinPeakProminence', 1);

min_lambda = lambda(locs);
min_T = T_raw(locs);

% Step 2.2: Manual Override (Correction for specific artifacts)
% In real-world data, automated detection might miss subtle fringes.
% We manually add a known minimum in the 570-580nm range.
range_start = 570;
range_end = 580;
idx_range = find(lambda >= range_start & lambda <= range_end);

[~, idx_local_min] = min(T_raw(idx_range));
idx_global = idx_range(idx_local_min);

lambda_manual = lambda(idx_global);
T_manual = T_raw(idx_global);

% Step 2.3: Merge and Sort Minima
all_min_lambda = sort([min_lambda; lambda_manual]);
all_min_T = [min_T; T_manual];
[all_min_lambda, sort_order] = sort(all_min_lambda);
all_min_T = all_min_T(sort_order);

%% 3. OPTICAL CONSTANTS CALCULATION (Swanepoel Logic)
% A. Calculate 'n' at minima points
s = 1.5; % Refractive index of substrate (Glass/Quartz)
T_min_frac = all_min_T / 100;

M_min = (2 * s) ./ T_min_frac - (s^2 + 1)/2;
n_min = sqrt(M_min + sqrt(M_min.^2 - s^2));

% B. Calculate Film Thickness 'd' (Iterative average)
% Pre-allocate memory. 
% Since we calculate thickness between pairs of minima, the resulting 
% array size is (number_of_minima - 1).
num_minima = length(all_min_lambda);
d_values = zeros(num_minima - 1, 1);

for i = 1:(num_minima - 1)
    l1 = all_min_lambda(i);
    l2 = all_min_lambda(i+1);
    n1 = n_min(i);
    n2 = n_min(i+1);
    
    % Swanepoel thickness formula
    d_calc = abs((l1 * l2) / (2 * (n1*l2 - n2*l1)));
    
    % Store directly in pre-allocated slot
    d_values(i) = d_calc;
end
d_avg = mean(d_values); % Average thickness

%% 4. DISPERSION & ABSORPTION MODELING
% C. Interpolate 'n' and apply Cauchy Fit (n = A + B/lambda^2)
n_interp = interp1(all_min_lambda, n_min, lambda, 'pchip', 'extrap');

% Clean data for fitting (Remove NaN/Inf)
valid_idx = isfinite(n_interp) & isreal(n_interp);
lambda_fit = lambda(valid_idx);
n_fit = n_interp(valid_idx);

x_cauchy = 1 ./ (lambda_fit.^2);
y_cauchy = n_fit;

% Linear Regression for Cauchy Coefficients
if length(x_cauchy) > 2 
    coeffs = polyfit(x_cauchy, y_cauchy, 1);
    A_cauchy = coeffs(2); 
    B_cauchy = coeffs(1); 
else
    A_cauchy = NaN; B_cauchy = NaN;
    warning('Insufficient points for Cauchy fit.');
end

% D. Absorption Coefficient (Alpha)
T_frac = T_raw / 100;
% Swanepoel absorption term
Abs_term = ((n_interp+1).^3 .* (n_interp+s^2)) ./ (16 .* n_interp.^2 .* s);
alpha_nm = (-1/d_avg) * log(T_frac ./ Abs_term);

% Physics constraint: Alpha cannot be negative or imaginary
alpha_nm(imag(alpha_nm) ~= 0 | alpha_nm < 0 | ~isfinite(alpha_nm)) = 0;

%% 5. DIRECT BAND GAP (Tauc Plot)
hv = 1240 ./ lambda;        % Photon Energy (eV)
alpha_cm = alpha_nm * 1e7;  % Convert nm^-1 to cm^-1

% Direct Gap Model: (alpha * hv)^2
y_tauc = (alpha_cm .* hv).^2; 

% Linear Regression Region (Tunable based on visual inspection)
linear_region = find(hv > 2.5 & hv < 2.8);

if length(linear_region) > 2
    p = polyfit(hv(linear_region), y_tauc(linear_region), 1);
    Eg = -p(2)/p(1);
    slope = p(1);
    intercept = p(2);
else
    Eg = NaN; slope = NaN; intercept = NaN;
end

%% 6. RESULTS SUMMARY
fprintf('\n>>> OPTICAL ANALYSIS RESULTS (ZnTe) <<<\n');
fprintf('Average Thickness (d):  %.2f nm\n', d_avg);
fprintf('Cauchy Parameters:      A = %.4f, B = %.2e\n', A_cauchy, B_cauchy);
fprintf('Direct Band Gap (Eg):   %.3f eV\n', Eg);
fprintf('========================================\n');

%% 7. VISUALIZATION
% Figure 1: Detection of Minima
figure('Color', 'white', 'Name', 'Interference Fringes');
plot(lambda, T_raw, 'LineWidth', 1.5, 'Color', '#0072BD'); hold on;
plot(min_lambda, min_T, 'ro', 'MarkerFaceColor', 'r', 'DisplayName', 'Auto Minima');
plot(lambda_manual, T_manual, 'bs', 'MarkerFaceColor', 'b', 'MarkerSize', 8, 'DisplayName', 'Manual Fix');
title('Transmittance Spectrum with Minima Detection');
xlabel('Wavelength (nm)'); ylabel('Transmittance (%)');
legend; grid on;

% Figure 2: Optical Constants Dashboard
figure('Color', 'white', 'Name', 'Optical Constants Dashboard');
sgtitle(['ZnTe Analysis Summary (d \approx ', num2str(d_avg, '%.0f'), ' nm)']);

% Subplot A: Refractive Index
subplot(1, 3, 1);
plot(lambda, n_interp, 'LineWidth', 2, 'Color', 'k'); hold on;
plot(all_min_lambda, n_min, 'ro');
title('Refractive Index (n)');
xlabel('Wavelength (nm)'); ylabel('n'); grid on;

% Subplot B: Absorption Coefficient
subplot(1, 3, 2);
semilogy(lambda, alpha_cm, 'LineWidth', 2, 'Color', '#D9534F');
title('Absorption Coefficient');
xlabel('Wavelength (nm)'); ylabel('\alpha (cm^{-1})'); grid on;

% Subplot C: Tauc Plot (Direct Gap)
subplot(1, 3, 3);
plot(hv, y_tauc, 'o', 'Color', [0.5 0.5 0.5]); hold on;
if isfinite(Eg)
    plot(hv, polyval(p, hv), 'r--', 'LineWidth', 2);
    title(['Tauc Plot (Eg = ', num2str(Eg, '%.2f'), ' eV)']);
    xlim([Eg-0.2, 3]);
    ylim([0, max(y_tauc)*1.1]);
end
xlabel('Photon Energy (eV)'); ylabel('(\alpha h \nu)^2'); grid on;