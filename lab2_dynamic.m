%% Associate filenames to frequency

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

%% Extract deformations and forces from the files.

sample_count = 10000;       % Numero di campioni restituiti dall'oscilloscopio.
extensimeter_voltage = 5;   % Voltaggio di alimentazione dell'estensimetro.

deformations = cell(length(filenames)); % Ogni misura di deformazione è salvata come timeseries (dati + tempo) in questo array.
forces = cell(length(filenames));       % Ogni misura di forza è salvata come timeseries in questo array.

for i = 1:length(filenames)
    lines = readlines(filenames(i));
    interval_line = split(lines(7), ",");   % Le righe 2, 3 contengono gli intervalli per i due canali, in microsecondi.

    channel_1_interval = str2double(erase(interval_line(2), "uS")) * 1e-6;
    channel_2_interval = str2double(erase(interval_line(3), "uS")) * 1e-6;

    samples = readtable( ...
        filenames(i), "NumHeaderLines", 8, "VariableNamingRule", "preserve");

    channel_1 = samples(:, 2);
    channel_2 = samples(:, 3);

    deformations{i} = timeseries( ...
        table2array(channel_1) ./ extensimeter_voltage, ...
        linspace(0, channel_1_interval * sample_count, sample_count), ...
        "Name", "Deformation [mV/V]");
    forces{i} = timeseries( ...
        table2array(channel_2), ...
        linspace(0, channel_2_interval * sample_count, sample_count), ...
        "Name", "Force [mV]");
end

%% Fourier transform

deformation_amplitudes = zeros(length(filenames), 1);
deformation_frequencies = zeros(length(filenames), 1);
deformation_phases = zeros(length(filenames), 1);
force_amplitudes = zeros(length(filenames), 1);
force_frequencies = zeros(length(filenames), 1);
force_phases = zeros(length(filenames), 1);

for i = 1:length(filenames)
    deformation_fft = fft(deformations{i}.Data);
    deformation_fft = deformation_fft(1:end/2) / sample_count;

    [deformation_amplitudes(i), peak_index] = max(abs(deformation_fft));
    deformation_frequencies(i) = peak_index / deformations{i}.Time(end);
    deformation_phases(i) = angle(deformation_fft(peak_index));

    force_fft = fft(forces{i}.Data);
    force_fft = force_fft(1:end/2) / sample_count;

    [force_amplitudes(i), peak_index] = max(abs(force_fft));
    force_frequencies(i) = peak_index / forces{i}.Time(end);
    force_phases(i) = angle(force_fft(peak_index));
end

amplitudes = 20 * log10(deformation_amplitudes ./ force_amplitudes);
phases = mod(rad2deg(deformation_phases - force_phases), 360) - 360;

%% Plot Bode diagrams
xi = 0.07;      % Coefficiente di smorzamento analitico.
omega_0 = 136;  % Pulsazione naturale analitica, in rad/s.

% TODO: CONTROLLARE NON SONO GIUSTE!!!!!
analytical_amplitudes = @(omega) 20 * log10(1 ./ sqrt((1 - (omega / omega_0).^2).^2 + (2 * xi * omega / omega_0).^2));
analytical_phases = @(omega) mod(rad2deg(atan2(2 * xi * omega / omega_0, 1 - (omega / omega_0).^2)), 360) - 360;

figure();
tiledlayout(2, 1);

nexttile();
hold on;
grid on;
title("Diagramma di Bode dell'ampiezza");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
xscale log;
scatter(frequency, amplitudes);
fplot(@(f) analytical_amplitudes(2 * pi * f), [min(frequency), max(frequency)], "--");

nexttile();
hold on;
grid on;
title("Diagramma di Bode della fase");
xlabel("Frequenza [Hz]");
ylabel("Sfasamento [°]");
yticks(-360:90:0);
xscale log;
scatter(frequency, phases);
fplot(@(f) analytical_phases(2 * pi * f), [min(frequency), max(frequency)], "--");

%% Test FFT estimation

i = 39;

deformation_fft = fft(deformations{i}.Data);
deformation_fft = deformation_fft(1:end/2) / (sample_count / 2);

[deformation_amplitude, peak_index] = max(abs(deformation_fft));
deformation_frequency = peak_index / max(deformations{i}.Time);
deformation_phase = angle(deformation_fft(peak_index));

force_fft = fft(forces{i}.Data);
force_fft = force_fft(1:end/2) / (sample_count / 2);

[force_amplitude, peak_index] = max(abs(force_fft));
force_frequency = peak_index / max(forces{i}.Time);
force_phase = angle(force_fft(peak_index));

figure();
hold on;
grid on;

plot(deformations{i});
plot(forces{i});

magic_factor = 2 * pi; % Should be 2pi

fplot(@(t) deformation_amplitude * cos(magic_factor * deformation_frequency * t + deformation_phase), ...
    [0, max(deformations{i}.Time)], "--");
fplot(@(t) force_amplitude * cos(magic_factor * force_frequency * t + force_phase), ...
    [0, max(forces{i}.Time)], "--");

legend("Deformation", "Force", "Estimated deformation", "Estimated force");

%% Plot ellipses

figure()
grid on
hold on

for i = 1:length(deformations)
    plot(deformations{i}.Data, forces{i}.Data)
end

legend(Hz_labels, "Interpreter", "none")
