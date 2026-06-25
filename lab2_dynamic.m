%% Associazione dei filename con le frequenze

filename_template = "lab2/data_45_%03d.csv";
max_filename_number = 54;

filenames = strings(max_filename_number, 1);    % Nomi dei file che contengono le serie di dati.
frequency = zeros(max_filename_number, 1);      % Frequenza corrispondente a ogni filename, in Hz.
skipped = 0; % Keeps count of skipped files.

for i = 1:max_filename_number
    filename = sprintf(filename_template, i);
    filenames(i - skipped) = sprintf(filename_template, i);

    % Skip adding non-existent files.
    if ~isfile(filename)
        fprintf("Skipping `%s`: file not found.\n", filename);
        skipped = skipped + 1;
    end

    if i == 1
        frequency(i) = 1;                                           % Il primo file è la misura a 1 Hz.
    elseif i <= 10
        frequency(i - skipped) = frequency(i - skipped - 1) + 1;    % Fino al file 010 passi da 1Hz.
    elseif i <= 24
        frequency(i - skipped) = frequency(i - skipped - 1) + 5;    % Fino al file 024 passi da 5Hz.
    elseif i < 48
        frequency(i - skipped) = frequency(i - skipped - 1) + 10;   % Successivamente passi da 10Hz.
    elseif i == 48
        frequency(i - skipped) = 0.3;                               % Dal file 48 si riparte dal 300mHz.
    else
        frequency(i - skipped) = frequency(i - skipped - 1) + 0.1;  % Successivamente passi da 100mHz.
    end
end

frequency = frequency(filenames ~= "");
filenames = filenames(filenames ~= "");

Hz_labels = arrayfun(@(f) sprintf("%.02f Hz", f), frequency);

%% Estrazione di forze e deformazioni dai file

sample_count = 10000;       % Numero di campioni restituiti dall'oscilloscopio.
extensimeter_voltage = 5;   % Voltaggio di alimentazione dell'estensimetro.

deformations = cell(length(filenames)); % Ogni misura di deformazione è salvata come timeseries (dati + tempo) in questo array.
forces = cell(length(filenames));       % Ogni misura di forza è salvata come timeseries in questo array.

for i = 1:length(filenames)
    lines = readlines(filenames(i));
    interval_line = split(lines(7), ",");   % Le colonne 2, 3 contengono gli intervalli per i due canali, in microsecondi.

    channel_1_interval = str2double(erase(interval_line(2), "uS")) * 1e-6;
    channel_2_interval = str2double(erase(interval_line(3), "uS")) * 1e-6;

    samples = readtable( ...
        filenames(i), "NumHeaderLines", 8, "VariableNamingRule", "preserve");

    channel_1 = samples(:, 2);
    channel_2 = samples(:, 3);

    deformations{i} = timeseries( ...
        table2array(channel_1) ./ extensimeter_voltage, ...
        linspace(0, channel_1_interval * sample_count, sample_count), ...
        "Name", "Deformazione [mV/V]");
    forces{i} = timeseries( ...
        table2array(channel_2), ...
        linspace(0, channel_2_interval * sample_count, sample_count), ...
        "Name", "Forza [mV]");
end

%% Trasformata di Fourier

deformation_magnitudes = zeros(length(filenames), 1);
deformation_frequencies = zeros(length(filenames), 1);
deformation_phases = zeros(length(filenames), 1);
force_magnitudes = zeros(length(filenames), 1);
force_frequencies = zeros(length(filenames), 1);
force_phases = zeros(length(filenames), 1);

function [frequency, magnitude, phase, fft_result] = fft_analysis(data, time_duration, expected_frequency)
    % Questa funzione analizza i dati con la Trasformata di Fourier.

    sample_count = length(data);
    %padded_count = lcm(sample_count, ceil(expected_frequency));
    padded_count = sample_count;
    
    % Espansione con zeri dei dati per migliorare la risoluzione e ridurre il leakage.
    % Questa tecnica si è dimostrata non necessaria, dato che padded_count = sample_count
    % questo codice non modifica il risultato dell'FFT.
    data_padded = zeros(padded_count, 1);
    data_padded(1:sample_count) = data;
    
    fft_result = fft(data_padded);
    fft_result = fft_result(2:end/2) / (padded_count / 2); % Shift left because it is zero-indexed. (?)
    
    % Selezione di un intervallo di frequenze vicino alla frequenza prevista.
    window_radius = 1;
    expected_index = round(expected_frequency * time_duration / sample_count * padded_count);
    fft_result_windowed = fft_result(expected_index-window_radius:expected_index+window_radius);

    [magnitude, peak_index_windowed] = max(abs(fft_result_windowed));
    magnitude = magnitude * padded_count / sample_count;
    phase = angle(fft_result_windowed(peak_index_windowed));

    peak_index = peak_index_windowed + expected_index - window_radius;
    frequency = peak_index / time_duration * sample_count / padded_count;
end

for i = 1:length(filenames)
    [deformation_frequencies(i), deformation_magnitudes(i), deformation_phases(i)] = ...
        fft_analysis(deformations{i}.Data, max(deformations{i}.Time), frequency(i));
    
    [force_frequencies(i), force_magnitudes(i), force_phases(i)] = ...
        fft_analysis(forces{i}.Data, max(forces{i}.Time), frequency(i));
end

magnitudes = 20 * log10(deformation_magnitudes ./ force_magnitudes);    % Rapporto di ampiezza, in dB.
phases = mod(rad2deg(deformation_phases - force_phases), 360) - 360;    % Sfasamento, riportato all'intervallo [-180°, 0°].

%% Spiegazione trasformata di Fourier

i = 20;
time_duration = max(deformations{i}.Time);
expected_frequency = frequency(i);

[~, ~, ~, deformations_fft] = fft_analysis(deformations{i}.Data, time_duration, expected_frequency);
[~, ~, ~, forces_fft] = fft_analysis(forces{i}.Data, time_duration, expected_frequency);

sample_count = length(deformations{i}.Data);
padded_count = sample_count; % lcm(sample_count, ceil(expected_frequency));

display_count = round(length(deformations_fft) / 100);

figure();
tiledlayout(2, 1);
%sgtitle(sprintf("Spettro delle frequenze della misura a %.01f Hz", expected_frequency))

nexttile();
grid on;
hold on;
xlabel("Frequenza [Hz]");
ylabel("Modulo")
plot( ...
    (1:display_count) / time_duration * sample_count / padded_count, ...
    abs(deformations_fft(1:display_count)) * padded_count / sample_count);
plot( ...
    (1:display_count) / time_duration * sample_count / padded_count, ...
    abs(forces_fft(1:display_count)) * padded_count / sample_count);
xline(expected_frequency, "--r");
legend(["Deformazione"; "Forza"; "Frequenza di misura"])

nexttile();
grid on;
hold on;
xlabel("Frequenza [Hz]");
ylabel("Fase [°]")
plot( ...
    (1:display_count) / time_duration * sample_count / padded_count, ...
    rad2deg(angle(deformations_fft(1:display_count))));
plot( ...
    (1:display_count) / time_duration * sample_count / padded_count, ...
    rad2deg(angle(forces_fft(1:display_count))));
xline(expected_frequency, "--r");

%% Diagrammi di Bode

omega = linspace(log(0.1), log(500), 500);
omega = exp(omega);     % Frequenze di campionamento delle FdT, con andamento esponenziale.

% FdT del sistema analitico, con frequenza caratteristica w0 e smorzamento xi.
%                    1
% H(s) = --------------------------
%        1/w0^2 s^2 + 2 xi/w0 s + 1
xi = 0.007048;
w0 = 44.6996;

[analytical_magnitudes, analytical_phases] = ...
    bode(tf(1, [1 / (w0^2), 2 * xi / w0, 1]), omega);

% FdT del sistema analitico ma con smorzamento xi_2.
%                     1
% H(s) = ----------------------------
%        1/w0^2 s^2 + 2 xi_2/w0 s + 1
xi_2 = 0.6;

[analytical_xi_magnitudes, analytical_xi_phases] = ...
    bode(tf(1, [1 / (w0^2), 2 * xi_2 / w0, 1]), omega);

approx_xi = 1.5;
low_w0 = 0.12;
high_w0 = 400;

% Spiega perfettament la fase.
[approx_xi_magnitudes, approx_xi_phases] = ...
    bode( ...
        tf([1/low_w0, 8], [1 / (low_w0^2), 2 * approx_xi / low_w0, 1]) * tf([1/low_w0, 8], 1) ...
            * tf(1, [1 / (high_w0^2), 2 * approx_xi / high_w0, 1]), ...
            omega);


% Spiega perfettamente l'ampiezza.
%[approx_xi_magnitudes, approx_xi_phases] = ...
%    bode( ...
%        tf([1/low_w0, 8], 1) * tf([1/low_w0, 8], [1 / (low_w0^2), 2 * approx_xi / low_w0, 1]) ...
%        * tf(1, [1 / (w0^2), 2 * approx_xi / w0, 1]) * tf(1, [1/w0, 1]) * tf(1, [1/w0, 1]), ...
%        omega);

% Spiega perfettamente l'ampiezza.
%[approx_xi_magnitudes, approx_xi_phases] = ...
%    bode( ...
%        tf(1, [1 / (low_w0^2), 2 * approx_xi / low_w0, 1]) ...
%        * tf(1, [1 / (w0^2), 2 * approx_xi / w0, 1]) * tf(1, [1/w0, 1]) * tf(1, [1/w0, 1]), ...
%        omega);


low_w0 = 0.12;
approx_xi = 1.5;
[approx_xi_magnitudes, approx_xi_phases] = ...
    bode( ...
        tf(1, [1, 2 * approx_xi * low_w0, low_w0^2]) ...
        * tf([1, 1], 1) ...
        * tf([1, 1], 1) ...
        , ...
            omega);

[approx_2ndorder_magnitudes, ~] = bode(tf(60^2, [1, 0]) * tf(1, [1, 0]), omega(round(end/3*2):end));
[approx_3ndorder_magnitudes, ~] = bode(tf(90^3, [1, 0]) * tf(1, [1, 0]) * tf(1, [1, 0]), omega(round(end/3*2):end));

figure();
tiledlayout(2, 1);

nexttile();
hold on;
grid on;
title("Diagramma di Bode dell'ampiezza");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
xscale log;
scatter(frequency, magnitudes)
%scatter(frequency, 20 * log10(force_magnitudes));
%scatter(frequency, 20 * log10(deformation_amplitudes));
plot(omega, 20 * log10(analytical_magnitudes(:)));
%plot(omega, 20 * log10(analytical_xi_magnitudes(:)));
%plot(omega, 20 * log10(approx_xi_magnitudes(:)));
%plot(omega(round(end/3*2):end), 20 * log10(approx_2ndorder_magnitudes(:)), '--');
%plot(omega(round(end/3*2):end), 20 * log10(approx_3ndorder_magnitudes(:)), '--');

legend(["Dati misurati"; "Soluzione analitica"; sprintf("Soluzione analitica con $\\xi=%.02f$", xi_2); "Risonanza a bassa frequenza"], "Interpreter", "latex")

nexttile();
hold on;
grid on;
title("Diagramma di Bode della fase");
xlabel("Frequenza [Hz]");
ylabel("Sfasamento [°]");
yticks(-360:90:0);
xscale log;
scatter(frequency, phases);
%scatter(frequency, mod(rad2deg(deformation_phases), 360) - 360);
%scatter(frequency, mod(rad2deg(force_phases), 360) - 360);
plot(omega, analytical_phases(:));
%plot(omega, analytical_xi_phases(:));
%plot(omega, approx_xi_phases(:));

%% Plot ellipses

figure()
grid on
hold on

for i = 1:length(deformations)
    plot(deformations{i}.Data, forces{i}.Data)
end

legend(Hz_labels, "Interpreter", "none")
