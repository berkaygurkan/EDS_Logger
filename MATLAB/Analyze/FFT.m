% --- MATLAB Code to Perform FFT and Estimate Noise ---

% **Assumptions:**
% 1. Your data is in a 1D array (vector) in MATLAB.
% 2. You know the sampling frequency (fs) which is 1 kHz in your case.
% 3. "Noise" here is broadly interpreted as unwanted frequency components
%    that are not the signal of interest.  This code provides a basic way
%    to estimate a noise floor and its power, but more sophisticated
%    noise analysis might be needed depending on your specific noise type.

% **Steps in the code:**
% 1. **Load or Generate Data:** Replace the example data with your actual data.
% 2. **Define Sampling Frequency (fs):**  Set fs to 1000 Hz (1 kHz).
% 3. **Perform FFT:** Calculate the Fast Fourier Transform of your data.
% 4. **Calculate Magnitude Spectrum:** Get the magnitude of the FFT, which
%    represents the amplitude of each frequency component.
% 5. **Generate Frequency Axis:** Create a frequency axis to plot against
%    the magnitude spectrum.
% 6. **Plot the Spectrum:** Visualize the frequency spectrum.
% 7. **Noise Estimation (Basic Method - You'll need to adapt this):**
%    - **Visual Inspection:**  The code includes a suggestion to visually
%      inspect the spectrum to identify frequency ranges that seem to be
%      dominated by noise (flat regions, high frequencies if signal is low freq).
%    - **Averaging Magnitude in a "Noise Band":**  The code provides an example
%      of averaging the magnitude spectrum in a high-frequency band to
%      estimate noise level. **You need to define this "noise band" based
%      on your data and what you consider noise.**
% 8. **Calculate Noise Power (Optional):** Estimate the power of the noise
%    in the selected band.
% 9. **Output Results:** Display the estimated noise level and power.

% --- START OF MATLAB CODE ---




% 1. Load or Generate Data (Replace with your actual data loading)
% Example: Generate a sample signal with some noise
fs = 1000; % Sampling frequency (Hz)
%t = 0:1/fs:1; % 1 second time vector



% **Important: Replace the lines above with how you load your actual data into the 'data' variable.**
% For example, if your data is in a file 'data.txt':
% data = load('data.txt');


% 2. Define Sampling Frequency (fs) - Already defined above as 1000 Hz
data = myDataBuffer;
% 3. Perform FFT
N = length(data); % Length of the data
fft_data = fft(data);

% 4. Calculate Magnitude Spectrum
magnitude_spectrum = abs(fft_data);

% 5. Generate Frequency Axis
f = fs*(0:(N/2))/N; % Frequency axis (positive frequencies up to Nyquist)

% 6. Plot the Spectrum
figure;
plot(f, magnitude_spectrum(1:N/2+1)); % Plot only positive frequencies
title('Magnitude Spectrum of the Data');
xlabel('Frequency (Hz)');
ylabel('Magnitude');
grid on;


% --- Noise Estimation (Basic Method - YOU NEED TO ADAPT THIS) ---

% 7. Noise Estimation - **Adapt this based on your data and visual inspection**

% **Method 1: Visual Inspection and Average in a High-Frequency Band**

% **a) Visual Inspection:**
%   - Look at the plotted spectrum.
%   - Identify a frequency range that seems to be dominated by noise.
%     This is often at higher frequencies where the signal components (peaks)
%     are less prominent and the spectrum looks more "flat" or random.
%   - **YOU need to decide on the `noise_start_frequency` and `noise_end_frequency`
%     based on your visual inspection.**

noise_start_frequency = 400; % **<--  YOU NEED TO ADJUST THIS based on your spectrum!**
noise_end_frequency   = 500; % **<--  YOU NEED TO ADJUST THIS based on your spectrum!**

% **b) Find indices corresponding to the noise band**
noise_start_index = find(f >= noise_start_frequency, 1, 'first');
noise_end_index   = find(f <= noise_end_frequency,   1, 'last');

if isempty(noise_start_index) || isempty(noise_end_index)
    disp('Warning: Noise frequency band is outside the plotted frequency range.');
    noise_level_estimate = NaN; % Indicate invalid estimate
    noise_power_estimate = NaN;
else
    % **c) Average magnitude in the noise band**
    noise_magnitudes_in_band = magnitude_spectrum(noise_start_index:noise_end_index);
    noise_level_estimate = mean(noise_magnitudes_in_band);

    % 8. Calculate Noise Power (Optional - basic estimate)
    % **Important:** This is a very basic estimate of noise power.
    % More accurate power estimation would require considering the bandwidth
    % and potentially PSD (Power Spectral Density).
    noise_power_estimate = mean(noise_magnitudes_in_band.^2); % Mean squared magnitude in the band
end


% 9. Output Results
disp('--- Noise Estimation Results ---');
disp(['Estimated Noise Level (Average Magnitude in ', num2str(noise_start_frequency), '-', num2str(noise_end_frequency), ' Hz band): ', num2str(noise_level_estimate)]);
disp(['Estimated Noise Power (Average Squared Magnitude in ', num2str(noise_start_frequency), '-', num2str(noise_end_frequency), ' Hz band): ', num2str(noise_power_estimate)]);


% --- Explanation and Next Steps ---

% **Explanation of the Code:**

% 1. **Data Loading & Sampling Frequency:**
%    - The code starts by generating example data for demonstration. **You MUST replace this with your actual data loading method.**
%    - `fs = 1000;` sets the sampling frequency to 1 kHz as you specified.  Make sure this matches your data logging frequency.

% 2. **FFT (Fast Fourier Transform):**
%    - `fft_data = fft(data);` calculates the FFT of your data. The FFT decomposes your time-domain signal into its frequency components.

% 3. **Magnitude Spectrum:**
%    - `magnitude_spectrum = abs(fft_data);` computes the magnitude of the FFT. This tells you the strength (amplitude) of each frequency component in your signal.

% 4. **Frequency Axis:**
%    - `f = fs*(0:(N/2))/N;` creates the frequency axis for the plot.  In FFT, the frequencies are spaced from 0 up to the Nyquist frequency (fs/2).

% 5. **Plotting the Spectrum:**
%    - `plot(f, magnitude_spectrum(1:N/2+1));` plots the magnitude spectrum against the frequency axis. We only plot up to N/2+1 because the spectrum is symmetric for real signals, and the positive frequencies contain all unique information.

% 6. **Noise Estimation (Basic Method):**
%    - **Visual Inspection is Key:**  The most crucial part is **YOU visually inspecting the plotted spectrum.** Look for regions in the frequency spectrum that appear to be dominated by noise rather than your signal of interest.
%    - **Noise Band Selection:**  Based on visual inspection, you need to define a frequency band (e.g., from `noise_start_frequency` to `noise_end_frequency`). In the example, `400-500 Hz` is just a placeholder. **You must adjust these values.**
%    - **Averaging Magnitude:** The code then finds the indices in the frequency axis corresponding to your chosen noise band and calculates the average magnitude of the spectrum within that band. This average magnitude is taken as a basic estimate of the noise level.
%    - **Noise Power Estimate:**  `noise_power_estimate` is a simple calculation of the average squared magnitude in the noise band. It provides a rough estimate of the noise power in that frequency range.

% **Important Considerations and Next Steps:**

% * **Visual Inspection is Crucial:** The accuracy of this basic noise estimation heavily depends on your visual inspection of the spectrum and your correct selection of the noise frequency band.

% * **Nature of Noise:** The effectiveness of this method depends on the type of noise you have. If your noise is truly broadband and relatively uniform across a frequency band, this method might give a reasonable estimate. If your noise is signal-dependent or has specific frequency characteristics, more sophisticated noise analysis techniques might be needed.

% * **Signal vs. Noise Frequency Separation:** This method works best if your signal and noise are somewhat separated in the frequency domain. If your signal and noise overlap significantly in frequency, it becomes harder to isolate noise using this simple approach.

% * **Alternative Noise Estimation Techniques:** For more advanced noise analysis, you might consider:
%     - **Power Spectral Density (PSD):**  Using `pwelch` or `periodogram` in MATLAB to estimate the PSD, which is a more robust way to analyze the distribution of power over frequencies, especially for noisy signals.
%     - **Noise Floor Estimation Algorithms:**  There are algorithms specifically designed to estimate noise floors in spectra.
%     - **Filtering Techniques:** If you know the frequency range of your signal, you might be able to use filters to reduce noise outside that range.
%     - **Signal Averaging (if applicable):** If you have multiple recordings of similar signals, averaging them can often reduce random noise.

% * **Adjust Noise Band:**  **Experiment by changing `noise_start_frequency` and `noise_end_frequency`** and see how the noise estimate changes.  Look at your spectrum carefully to choose a band that seems to represent noise well.

% * **Context is Key:** The "best" way to find noise depends heavily on the nature of your data, what you consider "noise," and what you want to achieve.  This code provides a starting point and a basic method, but you might need to explore more advanced techniques if this simple approach is not sufficient for your needs.

% **To use this code:**

% 1. **Replace the example data generation** with the code to load your actual 1D data into the `data` variable.
% 2. **Run the code.**
% 3. **Carefully examine the plotted magnitude spectrum.**
% 4. **Based on visual inspection, adjust `noise_start_frequency` and `noise_end_frequency`** in the code to define a frequency band that represents noise in your spectrum.
% 5. **Re-run the code** to get the noise level and power estimates for your chosen band.
% 6. **Consider if this basic method is sufficient** for your noise analysis, or if you need to explore more advanced techniques.