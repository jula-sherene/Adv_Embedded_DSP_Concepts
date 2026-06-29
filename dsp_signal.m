%% STM32 FFT Benchmarking Interface
% Matches the "READY_BIN" handshake protocol

clear; clc; close all;

% --- Configuration ---

portName = 'COM4'; % <---  to ST-LINK Virtual COM Port
baudRate = 115200;
FFT_LEN  = 256;
MAG_LEN  = FFT_LEN/2 + 1; 
Fs       = 1000; % Assuming 1kHz sample rate for plotting

% --- 1. Generate Test Signal ---

t = (0:FFT_LEN-1) / Fs;
f1 = 50;  % 50 Hz component
f2 = 120; % 120 Hz component
% Create a signal with two sines and some noise
signal = 0.6*sin(2*pi*f1*t) + 0.4*sin(2*pi*f2*t) + 0.1*randn(size(t));

% --- 2. Initialize Serial Port ---
s = serialport(portName, baudRate);
configureTerminator(s, "CR/LF");
flush(s);

fprintf("Connected to %s. Triggering FFT...\n", portName);

% --- 3. The Handshake ---
% Send 'run' command to the STM32 CLI
writeline(s, "run");

% Wait for the "READY_BIN" trigger
ready = "";
while ~contains(ready, "READY_BIN")
    if s.NumBytesAvailable > 0
        ready = readline(s);
        disp("STM32: " + ready);
    end
end

% --- 4. Send & Receive Binary Data ---
% Send the signal as raw 32-bit floats ('single' in MATLAB)
write(s, single(signal), "single");

% Read back the magnitude array (MAG_LEN floats)
mag_data = read(s, MAG_LEN, "single"); 

fprintf("Data received successfully!\n");

% --- 5. Visualization ---
freq_axis = (0:MAG_LEN-1) * (Fs/FFT_LEN);

figure('Color', 'w');
subplot(2,1,1);
plot(t*1000, signal, 'Color', [0 0.447 0.741], 'LineWidth', 1.5);
title('Input Signal (Time Domain)');
xlabel('Time (ms)'); ylabel('Amplitude');
grid on;

subplot(2,1,2);
stem(freq_axis, mag_data, 'MarkerFaceColor', [0.85 0.325 0.098], 'LineWidth', 1);
title('FFT Magnitude (Processed by STM32)');
xlabel('Frequency (Hz)'); ylabel('Magnitude');
xlim([0 Fs/2]);
grid on;

% Clean up
delete(s);
