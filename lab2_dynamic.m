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
        linspace(0, channel_1_interval, sample_count), ...
        "Name", "Deformation [mV/V]");
    forces{i} = timeseries( ...
        table2array(channel_2), ...
        linspace(0, channel_2_interval, sample_count), ...
        "Name", "Force [mV]");
end


%% Plot Bode diagram

deformation_amplitudes = zeros(1, length(filenames));
force_amplitudes = zeros(1, length(filenames));

% Adesso per misurare l'ampiezza ho preso la differenza tra valore massimo e minimo della serie.
% È un metodo primitivo molto suscettibile al disturbo, sarebbe meglio usare Fourier.
for i = 1:length(filenames)
    deformation_amplitudes(i) = max(deformations{i}) - min(deformations{i});
    force_amplitudes(i) = max(forces{i}) - min(forces{i});
end

amplitudes = deformation_amplitudes ./ force_amplitudes;

restart_point = length(filenames) - 6;
amplitudes_reordered = ...
    [amplitudes(restart_point:end), amplitudes(1:restart_point-1)];
frequency_reordered = ...
    [frequency(restart_point:end); frequency(1:restart_point-1)];

figure()
hold on
semilogy(frequency_reordered, amplitudes_reordered);


%% Plot ellipses

figure()
grid on
hold on

for i = 1:length(deformations)
    plot(deformations{i}.Data, forces{i}.Data)
end

legend(Hz_labels, "Interpreter", "none")
