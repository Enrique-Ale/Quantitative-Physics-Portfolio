%% INDIRECT BAND GAP ANALYSIS (SILICON) - ESSICK METHOD
%  Author: Enrique A. Alcántara
%  Description: 
%     Analyzes the optical properties of a Silicon (Si) wafer.
%     Implements the Essick Method to handle Indirect Band Gaps, separating
%     phonon absorption and emission processes to calculate Optical Band Gap (Eg)
%     and Phonon Energy (Ep).

clear; clc; close all;

%% 1. DATA INGESTION
% Import settings for Perkin-Elmer Lambda 25 UV-VIS Spectrophotometer output
opts = delimitedTextImportOptions("NumVariables", 2);
opts.DataLines = [87, Inf];
opts.Delimiter = "\t";
opts.VariableNames = ["Wavelength", "Transmittance"];
opts.VariableTypes = ["double", "double"];
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

% Load Dataset
dataTable = readtable("SI.SP", opts);
lambda = dataTable.Wavelength;      % nm
T_raw = dataTable.Transmittance;    % %T

%% 2. CALCULATE REFLECTANCE (Essick Approximation)
% Find max transmittance in the transparent region (sub-gap)
lambda_start = 860; 
lambda_end = 1100;
idx_transparent = (lambda >= lambda_start & lambda <= lambda_end);

T_transparent = T_raw(idx_transparent);
T_max = max(T_transparent);

fprintf('Max Transmittance (Transparent Region): %.2f %%\n', T_max);

% Calculate Reflectance (R) assuming absorption is negligible at T_max
T_frac_max = T_max / 100;
R = (1 - T_frac_max) / (1 + T_frac_max);
fprintf('Calculated Reflectance (R): %.4f\n', R);

%% 3. COMPUTE ABSORPTION COEFFICIENT (Alpha)
d_nm = 30000; % Thickness in nm (30 microns)
T_frac = T_raw / 100;

% Exact solution for Alpha considering multiple reflections
term_sqrt = sqrt((1-R)^4 + 4 .* T_frac.^2 .* R^2);
numerator = term_sqrt - (1-R)^2;
denominator = 2 .* T_frac .* R^2;

alpha_nm = (-1/d_nm) * log(numerator ./ denominator);

% Clean imaginary or negative values (physical constraints)
alpha_nm(imag(alpha_nm) ~= 0 | alpha_nm < 0 | ~isfinite(alpha_nm)) = 0;
alpha_cm = alpha_nm * 1e7; % Convert to cm^-1

%% 4. INDIRECT BAND GAP & PHONON ENERGY EXTRACTION
hv = 1240 ./ lambda; % Photon Energy (eV)
y_tauc = sqrt(alpha_cm); % Indirect Gap scales with sqrt(alpha)

% --- Linear Region 1: Phonon Absorption (Eg - Ep) ---
% Target specific low-energy tail
range_1 = find(hv > 1.12 & hv < 1.135); 

if length(range_1) > 2
    p1 = polyfit(hv(range_1), y_tauc(range_1), 1);
    Eg_minus_Ep = -p1(2)/p1(1);
    fprintf('Intercept 1 (Eg - Ep): %.4f eV\n', Eg_minus_Ep);
else
    Eg_minus_Ep = NaN; warning('Range 1 fitting failed.');
end

% --- Linear Region 2: Phonon Emission (Eg + Ep) ---
% Target higher energy slope
range_2 = find(hv > 1.225 & hv < 1.268); 

if length(range_2) > 2
    p2 = polyfit(hv(range_2), y_tauc(range_2), 1);
    Eg_plus_Ep = -p2(2)/p2(1);
    fprintf('Intercept 2 (Eg + Ep): %.4f eV\n', Eg_plus_Ep);
else
    Eg_plus_Ep = NaN; warning('Range 2 fitting failed.');
end

% --- Final Calculation ---
if isfinite(Eg_minus_Ep) && isfinite(Eg_plus_Ep)
    Eg_final = (Eg_plus_Ep + Eg_minus_Ep) / 2;
    Ep_final = abs(Eg_plus_Ep - Eg_minus_Ep) / 2;
    
    fprintf('\n>>> FINAL RESULTS <<<\n');
    fprintf('Indirect Band Gap (Eg): %.4f eV\n', Eg_final);
    fprintf('Phonon Energy (Ep):     %.4f eV (%.1f meV)\n', Ep_final, Ep_final*1000);
else
    warning('Could not solve for Eg and Ep. Check ranges.');
end

%% 5. VISUALIZATION
figure('Color', 'white', 'Name', 'Silicon Indirect Analysis');

% Subplot 1: Tauc Plot with Dual Regressions
subplot(1,2,1);
plot(hv, y_tauc, 'ko', 'MarkerSize', 3); hold on;

% Plot regression lines
if isfinite(Eg_minus_Ep)
    plot(hv, polyval(p1, hv), 'r--', 'LineWidth', 1.5, 'DisplayName', 'Phonon Absorption');
end
if isfinite(Eg_plus_Ep)
    plot(hv, polyval(p2, hv), 'b--', 'LineWidth', 1.5, 'DisplayName', 'Phonon Emission');
end

title('Indirect Tauc Plot (Silicon)');
xlabel('Photon Energy (eV)');
ylabel('\alpha^{1/2} (cm^{-1/2})');
xlim([1.05, 1.3]); ylim([0, max(y_tauc)*0.8]);
legend('Location', 'best'); grid on;

% Subplot 2: Absorption Coefficient (Log Scale)
subplot(1,2,2);
semilogy(hv, alpha_cm, 'LineWidth', 2, 'Color', '#D9534F');
title('Absorption Coefficient');
xlabel('Photon Energy (eV)'); ylabel('\alpha (cm^{-1})');
grid on;