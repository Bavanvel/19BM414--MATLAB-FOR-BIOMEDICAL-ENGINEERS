# EXPERIMENT 1: ECG Noise Removal and QRS Detection

## AIM:
  To remove noise from an ECG signal and detect QRS complexes using MATLAB.

## INPUT:
  One ECG waveform and sampling frequency. Example: ecg_sample.mat containing ecg and fs = 360 
Hz.

## INPUT FILE/PARAMETERS
  File name/model: ecg_sample.mat

## THEORY/PRINCIPLE:
  ECG contains characteristic P, QRS and T waves and may be contaminated by baseline wander, powerline interference and 
  high-frequency noise. A band-pass filter is used to emphasize QRS energy Differentiation, squaring and moving-window 
  integration further enhance the QRS complexes before peak detection.

## PROCESSING FLOWCHART:
<img width="1900" height="532" alt="image" src="https://github.com/user-attachments/assets/7ba8e50b-ef4a-4de7-8ad0-fad9b141b02a" />

## PROCEDURE:
1. Load the ECG and inspect its duration and amplitude.
2. Remove the DC component.
3. Design and apply a 5–15 Hz Butterworth band-pass filter.
4. Differentiate and square the filtered ECG.
5. Apply a 150 ms moving-window integration.
6. Detect QRS candidates using minimum height and minimum distance.
7. Calculate RR intervals and estimated heart rate

## MATLAB PROGRAM:
```
%% EXPERIMENT 1: ECG NOISE REMOVAL AND QRS DETECTION
% Complete program: Generate input, save, load, filter,
% detect QRS complexes, calculate heart rate, and plot results.

clear;
close all;
clc;

%% STEP 1: CREATE A SIMULATED ECG INPUT FILE
fs = 360;                  % Sampling frequency in Hz
duration = 10;              % Duration in seconds
heartRateOriginal = 75;     % Simulated heart rate in bpm

t = (0:1/fs:duration-1/fs)';
ecg = zeros(size(t));

beatInterval = 60 / heartRateOriginal;
numberOfBeats = ceil(duration / beatInterval);

% Generate simulated P, QRS and T waves
for beat = 0:numberOfBeats-1

    beatTime = 0.5 + beat * beatInterval;

    if beatTime + 0.35 >= duration
        continue;
    end

    % P wave
    ecg = ecg + 0.12 * exp( ...
        -((t - (beatTime - 0.20))/0.045).^2);

    % Q wave
    ecg = ecg - 0.15 * exp( ...
        -((t - (beatTime - 0.035))/0.012).^2);

    % R wave
    ecg = ecg + 1.00 * exp( ...
        -((t - beatTime)/0.015).^2);

    % S wave
    ecg = ecg - 0.25 * exp( ...
        -((t - (beatTime + 0.035))/0.015).^2);

    % T wave
    ecg = ecg + 0.30 * exp( ...
        -((t - (beatTime + 0.25))/0.070).^2);
end

% Add baseline drift and random noise
rng(1);  % Repeatable results
ecg = ecg ...
    + 0.10 * sin(2*pi*0.4*t) ...
    + 0.05 * randn(size(t));

% Save the generated ECG input file
filename = 'ecg_sample.mat';
save(filename, 'ecg', 'fs');

fprintf('STEP 1: ECG input file created successfully.\n');
fprintf('File name: %s\n', filename);

%% STEP 2: LOAD THE ECG INPUT FILE
S = load(filename);

ecg = double(S.ecg(:));
fs = S.fs;
t = (0:length(ecg)-1)' / fs;

fprintf('\nSTEP 2: ECG file loaded successfully.\n');
fprintf('Number of samples = %d\n', length(ecg));
fprintf('Sampling frequency = %d Hz\n', fs);
fprintf('Signal duration = %.2f seconds\n', t(end));

%% STEP 3: DISPLAY THE RAW ECG
figure('Name', 'Figure 1 - Raw ECG');
plot(t, ecg, 'k');
grid on;
xlabel('Time (seconds)');
ylabel('Amplitude');
title('Raw ECG Signal');

%% STEP 4: REMOVE BASELINE DRIFT
ecg0 = ecg - mean(ecg);

% Estimate baseline using a moving-average window
baselineWindow = round(0.6 * fs);
baselineWindow = max(baselineWindow, 1);

baseline = conv(ecg0, ...
    ones(baselineWindow, 1)/baselineWindow, 'same');

ecgCorrected = ecg0 - baseline;

%% STEP 5: SMOOTH THE ECG TO REDUCE HIGH-FREQUENCY NOISE
% Short moving-average window
smoothWindow = 5;

ecgFiltered = conv(ecgCorrected, ...
    ones(smoothWindow, 1)/smoothWindow, 'same');

figure('Name', 'Figure 2 - Filtered ECG');
plot(t, ecgFiltered, 'b');
grid on;
xlabel('Time (seconds)');
ylabel('Amplitude');
title('ECG after Baseline Correction and Smoothing');

%% STEP 6: ENHANCE THE QRS COMPLEXES
% Calculate the first difference
dECG = [0; diff(ecgFiltered)];

% Square the derivative
squaredECG = dECG .^ 2;

% Moving-window integration over approximately 150 ms
integrationWindow = round(0.150 * fs);

integratedECG = conv(squaredECG, ...
    ones(integrationWindow, 1)/integrationWindow, 'same');

figure('Name', 'Figure 3 - QRS Enhancement');
plot(t, integratedECG, 'm');
grid on;
xlabel('Time (seconds)');
ylabel('Integrated energy');
title('Moving-Window Integrated ECG');

%% STEP 7: DETECT QRS CANDIDATES
threshold = 0.35 * max(integratedECG);
minimumDistance = round(0.25 * fs);

% Find local maxima without using findpeaks
candidateLocs = [];

for i = 2:length(integratedECG)-1
    if integratedECG(i) >= integratedECG(i-1) && ...
       integratedECG(i) > integratedECG(i+1) && ...
       integratedECG(i) >= threshold

        candidateLocs(end+1, 1) = i;
    end
end

% Retain the strongest peak within each minimum-distance interval
qrsLocs = [];

if ~isempty(candidateLocs)

    [~, order] = sort( ...
        integratedECG(candidateLocs), 'descend');

    selectedLocs = [];

    for k = 1:length(order)
        loc = candidateLocs(order(k));

        if isempty(selectedLocs) || ...
           all(abs(selectedLocs - loc) >= minimumDistance)

            selectedLocs(end+1, 1) = loc;
        end
    end

    qrsLocs = sort(selectedLocs);
end

%% STEP 8: DISPLAY DETECTED QRS CANDIDATES
figure('Name', 'Figure 4 - QRS Detection');
plot(t, ecgFiltered, 'b');
hold on;

if ~isempty(qrsLocs)
    plot(t(qrsLocs), ecgFiltered(qrsLocs), ...
        'ro', 'MarkerFaceColor', 'r');
end

grid on;
xlabel('Time (seconds)');
ylabel('Amplitude');
title('Filtered ECG with Detected QRS Candidates');
legend('Filtered ECG', 'QRS candidates');
hold off;

%% STEP 9: CALCULATE RR INTERVAL AND HEART RATE
if length(qrsLocs) >= 2

    RR = diff(qrsLocs) / fs;
    meanRR = mean(RR);
    HR = 60 / meanRR;

else

    RR = [];
    meanRR = NaN;
    HR = NaN;

    warning(['Fewer than two QRS candidates were detected. ', ...
        'Heart rate cannot be estimated reliably.']);
end

%% STEP 10: DISPLAY THE RESULTS
fprintf('\n====================================\n');
fprintf('         EXPERIMENT 1 RESULTS\n');
fprintf('====================================\n');

fprintf('Sampling frequency = %d Hz\n', fs);
fprintf('Signal duration = %.2f seconds\n', t(end));
fprintf('Original simulated heart rate = %d bpm\n', ...
    heartRateOriginal);
fprintf('Detected QRS candidates = %d\n', length(qrsLocs));

if isnan(meanRR)
    fprintf('Mean RR interval = Not available\n');
    fprintf('Estimated heart rate = Not available\n');
else
    fprintf('Mean RR interval = %.4f seconds\n', meanRR);
    fprintf('Estimated heart rate = %.2f bpm\n', HR);
end

fprintf('Input file saved as: %s\n', filename);
fprintf('====================================\n');
fprintf('Experiment completed successfully.\n');
```
## OUTPUT:
FIGURE 1- RAW ECG
<img width="1606" height="791" alt="image" src="https://github.com/user-attachments/assets/8ea6f846-ca8c-41ef-b4fe-c749f474ac15" />

FIGURE 2 - FILTERED ECG
<img width="1640" height="785" alt="image" src="https://github.com/user-attachments/assets/84c81b40-ec01-4de9-a771-7b5ec6a9ee26" />

FIGURE 3- QRS ENHANCEMENT
<img width="1597" height="792" alt="image" src="https://github.com/user-attachments/assets/46232a5d-ed3a-4a16-b6c4-dfbe517bb137" />

FIGURE 4- QRS DETECTION
<img width="1582" height="787" alt="image" src="https://github.com/user-attachments/assets/6e3c8545-ea68-41aa-83f5-87c3ff4c9c44" />

## OBSERVATION:
1. Sampling frequency = 360 Hz
2. Signal duration = 10.00 seconds
3. Original simulated heart rate = 75 bpm
4. Detected QRS candidates = 12
5. Mean RR interval = 0.7980 seconds
6. Estimated heart rate = 75.19 bpm
7. Input file saved as: ecg_sample.mat

## RESULT:
The experiment was performed successfully using MATLAB. The input was processed according to the 
stated method and the expected biomedical output was obtained.



