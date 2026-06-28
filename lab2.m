
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%                                                         %%%%%%%%%
%%%%%%%%%        LABORATORIO 2: CAMPAGNA DI MISURA DINAMICA       %%%%%%%%%
%%%%%%%%%                                                         %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear
clc
close all

%% CODE

% Il seguente codice è pensato per essere eseguito nella cartella contenente le
% sottocartelle lab2/ e lab2_frequencies/ che contengono i dati raccolti nel 
% secondo laboratorio.

% Copia dei file di dati con un nome che rifletta la frequenza di campionamento.
% ==============================================================================
% Ad esempio il file campionato a 60 Hz viene copiato nel percorso 
% lab2_frequencies/60Hz.csv. Questa parte è commentata nel codice consegnato
% e i file rinominati sono già forniti.

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

    % Il file 000 si salta perché è stato creato come test.
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

for i = 1:length(filenames)
    % Si è scelto di commentare questa parte e fornire i file già rinominati.
    %copyfile(filenames(i), sprintf("lab2_frequencies/%gHz.csv", frequency(i)))
end


% Primo tentativo di rappresentare i diagrammi di Bode
% ==============================================================================

% Calcolo delle ampiezze
% ------------------------------------------------------------------------------

freqs = [0.3,0.4,0.5,0.6,0.7,0.8,0.9,...
    1,2,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,55,60,65,70,...
    80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,...
    230,240,250,260,270,280,290,300]; 

amp_def = zeros(size(freqs));
amp_forza = zeros(size(freqs));
rapporto= zeros(size(freqs));
 

for i = 1:length(freqs)
    filename = sprintf('lab2_frequencies/%gHz.csv', freqs(i));
    
    if isfile(filename)
        % leggiamo i dati saltando le 9 righe di intestazione
        % 'VariableNamingRule', 'preserve' serve per evitare errori con i nomi colonne
        data = readtable(filename, 'NumHeaderLines', 9, 'VariableNamingRule', 'preserve');
        
        % estraggo le colonne(Ch1 = Deformazione, Ch2 = Forza)
        v_def = data{:,2} ./ (5);  %[mV/V]
        v_forza = data{:,3}; %[mV]
        % max e min, un po' brutale
        max_d = max(v_def);
        min_d = min(v_def);
        
        max_f = max(v_forza);
        min_f = min(v_forza);
        
        % calcolo dell'ampiezza(picco-picco)
        amp_def(i) = abs(max_d - min_d);
        amp_forza(i) =abs(max_f - min_f);
        
        % calcolo del rapporto
        rapporto(i) =abs (amp_def(i)/amp_forza(i));
        
    else
        rapporto(i)=NaN;
    end
end


% Calcolo delle fasi
% ------------------------------------------------------------------------------

fasi = zeros(size(freqs));

for i = 1:length(freqs)
    filename = sprintf('lab2_frequencies/%gHz.csv', freqs(i));
    if isfile(filename)
        data = readtable(filename, 'NumHeaderLines', 9);
        F= data{:, 3} - mean(data{:, 3}); % forza centrata
        D= data{:, 2} - mean(data{:, 2}); % deformazione centrata (bilancio a mano)
        
        %corrisponde a B 
        Y_max = (max(F) - min(F)) / 2;
        
        %trovo l'intercetta A 
        [~, idx_zero] = min(abs(D)); 
        Y_0 = abs(F(idx_zero));
       
        ratio =Y_0 / Y_max;
        if ratio > 1, ratio = 1; end
        
        fasi(i) = asind(ratio); % Risultato in gradi
        
    else
        fasi(i) = NaN;
    end
end

% Diagrammi di Bode
% ------------------------------------------------------------------------------

% Diagramma di modulo 
figure('Name', 'Diagramma di bode ');
subplot(2,1,1);
semilogx(freqs, 20 * log10(rapporto), 'o');
title("Diagramma di Bode dell'ampiezza")
grid on;
legend('Dati misurati')
xlabel('Frequenza [Hz]');
ylabel('Rapporto di ampiezza [dB]');

%Diagramma di Fase
subplot(2,1,2);
semilogx(freqs, -fasi, 'o');
title('Diagramma di Bode della fase')
grid on;
xlabel('Frequenza [Hz]');
ylabel('Sfasamento [°]');


% Calcolo analitico della frequenza di risonanza e delle incertezze 
% ==============================================================================

% Incertezze tipo
ul = 0.0029/1000; 
ub = 0.0029/1000;
uh = 0.0029/1000;
% Dati
E = 70 * 1e9; 
b = 18.60 * 1e-3; 
h = 2.02 * 1e-3;
l = 160.92 * 1e-3; 
rho_al = 2700;  
coeff_c = 0.5; 
% prendiamo un modello che modella la massa anzichè come 
% distribuita come divisa in due una parti sull'incastro e l'altra
% sull'estremo libero 

J = b * h^3 / 12; 
k = (3*E*J)/(l^3); 
M =  coeff_c * rho_al * l * b * h; 
omega_n= sqrt(k/M);
f_n = sqrt(k/M)/(2*pi); 

% Calcolo delle incertezze su k, omega e f_ 
u_k = sqrt((3*ul/l)^2+ (3*uh/h)^2 + (ub/b)^2);
U_k = 1.96*u_k*k; 

u_f = sqrt((2*ul/l)^2 + (uh/h)^2);
U_f = 1.96*u_f*f_n;
U_omega =1.96*u_f*omega_n;

fprintf("Frequenza di risonanza analitica: %g ± %g Hz.\n", f_n, U_f)


% Approccio definitivo al calcolo dei diagrammi di Bode
% ==============================================================================
% Si usa la FFT per calcolare i diagrammi di Bode in modo più accurato.

% Associazione dei filename con le frequenze
% ------------------------------------------------------------------------------

frequency = [0.3,0.4,0.5,0.6,0.7,0.8,0.9,...
    1,2,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,55,60,65,70,...
    80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,...
    230,240,250,260,270,280,290,300]; 

filenames = strings(length(frequency), 1);    % Nomi dei file che contengono le serie di dati.
for i = 1:length(frequency)
    filenames(i) = sprintf("lab2_frequencies/%gHz.csv", frequency(i));
end

Hz_labels = arrayfun(@(f) sprintf("%.02f Hz", f), frequency);

% Estrazione di forze e deformazioni dai file
% ------------------------------------------------------------------------------

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

% Trasformata di Fourier
% ------------------------------------------------------------------------------

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

% Spiegazione trasformata di Fourier
% ------------------------------------------------------------------------------

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

% Diagrammi di Bode
% ------------------------------------------------------------------------------

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
plot(omega, 20 * log10(analytical_magnitudes(:)));
plot(omega, 20 * log10(analytical_xi_magnitudes(:)));
plot(omega, 20 * log10(approx_xi_magnitudes(:)));

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
plot(omega, analytical_phases(:));
plot(omega, analytical_xi_phases(:));
plot(omega, approx_xi_phases(:));


% Calcolo del coefficiente di smorzamento
% ==============================================================================

filename_numbers = [55:57, 60:61]; % Selezione dei 5 segnali migliori.
filenames = arrayfun(@(n) sprintf("lab2/data_45_%03d.csv", n), filename_numbers);

times = cell(length(filenames), 1);
signals = cell(length(filenames), 1);
coeffAng = zeros(length(filenames), 1);

tStep = 400e-6; % Step temporale = 400 μs.
VStep = 5;      % Step di tensione = 5 mV.

for i = 1:length(filenames)
    data = readtable(filenames(i), "NumHeaderLines", 9, "VariableNamingRule","preserve");

    time = data{:, 1} * tStep;
    signal = data{:, 2} * VStep;

    % Si fanno iniziare tutti i segnali all'istante del primo impatto e li si fa 
    % finire quando la loro ampiezza scende sotto un limite.
    firstIndex = find(signal == max(signal), 1, "last");    
    lastIndex = find(signal > 1000 * VStep, 1, "last");
        
    times{i} = time(firstIndex:end) - time(firstIndex);
    signals{i} = signal(firstIndex:end);

    time = time(firstIndex:lastIndex) - time(firstIndex);
    signal = signal(firstIndex:lastIndex);

    peakIndexes = diff(signal) == 0;

    signal = abs(signal);
    
    coeff = polyfit(time(peakIndexes), log(signal(peakIndexes)), 1);
    coeffAng(i) = coeff(1);
        
    %scatter(time(peakIndexes), log(signal(peakIndexes)));
    %fplot(@(x) coeff(1) * x + coeff(2), [0, 0.3], "--", "DisplayName", sprintf("%f", xi));
end

omega_n = 2 * pi * 136; % 136 Hz è la risonanza che non ci viene 
xis = -coeffAng ./ omega_n;
xi = mean(xis);

devStd = sqrt(1/(5-1) * sum((xis - xi).^2));

fprintf("xi = %f\n S_xi = %f\n", xi, devStd);


figure();
grid on;
hold on;
xlabel("Tempo [s]");
ylabel("Misura di deformazione [mV/V]")

fplot(@(x) VStep * 6767 * exp(-x * omega_n * xi), [0, 2], "r--");
fplot(@(x) -VStep * 6767 * exp(-x * omega_n * xi), [0, 2], "r--");

for i = 1:length(signals)
    plot(times{i}, signals{i});
end

legend([sprintf("Inviluppo corrispondente a \\xi = %f", xi)])

xlim([0, 1])


% Banda passante
% ==============================================================================

% Banda passante per dati sperimentali
% ------------------------------------------------------------------------------

% Ordinamento del vettore delle frequenze in modo crescente.
[frequency_sorted, sort_idx] = sort(frequency);
magnitudes_sorted = magnitudes(sort_idx);
phases_sorted = phases(sort_idx);

E_max = 3;
E_min = -3;

BP = [];
BP_indx = [];

for i = 1:length(frequency_sorted)
    if magnitudes_sorted(i) < E_max && magnitudes_sorted(i) > E_min
        BP = [BP; frequency_sorted(i)];
        BP_indx = [BP_indx;i];
    end
end

omega = linspace(log(0.1), log(500), 500);
omega = exp(omega);

figure();
hold on;
grid on;

title("Diagramma di Bode dell'ampiezza");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
xscale log;

scatter(frequency_sorted, magnitudes_sorted)
fplot(@(x) 3 * ones(size(x)), [min(frequency_sorted), max(frequency_sorted)], 'b--');
fplot(@(x) -3 * ones(size(x)), [min(frequency_sorted), max(frequency_sorted)], 'r--');

plot(BP(1), magnitudes_sorted(BP_indx(1)), 'p', 'MarkerSize', 14, ...
    'MarkerFaceColor', [0.4660 0.6740 0.1880], 'MarkerEdgeColor', 'k', ...
    'DisplayName', sprintf('Inizio BP (%.2f Hz)', BP(1)));

plot(BP(end), magnitudes_sorted(BP_indx(end)), 'p', 'MarkerSize', 14, ...
    'MarkerFaceColor', [0.8500 0.3250 0.0980], 'MarkerEdgeColor', 'k', ...
    'DisplayName', sprintf('Fine BP (%.2f Hz)', BP(end)));

legend('dati misurati', '+3dB', '-3dB', 'Inizio Banda Passante', 'Fine Banda Passante', 'Location', 'southwest')

% Banda passante della soluzione analitica
% ------------------------------------------------------------------------------

% Parametri del sistema
fN = 44.6996;
wN = 2*pi*fN;       
xi = 0.007048;      

omega_analitica = exp(linspace(log(0.1), log(500), 1000));
f_asse = omega_analitica / (2*pi);

a = 1;
b_2 = -(1 - 2*xi^2); 

% 1. Accuratezza all'1%
e_1 = 0.01;
c_1 = 1 - 1/((1+e_1)^2);
delta_4_1 = b_2^2 - a*c_1;
f_lim_1 = (wN * sqrt(-b_2 - sqrt(delta_4_1))) / (2*pi); 

% 2. Accuratezza al 5%
e_5 = 0.05;
c_5 = 1 - 1/((1+e_5)^2);
delta_4_5 = b_2^2 - a*c_5; 
f_lim_5 = (wN * sqrt(-b_2 - sqrt(delta_4_5))) / (2*pi);

% 3. Soglia a +3dB
c_3dB = 0.5;
delta_4_3db = b_2^2 - a*c_3dB;
f_lim_3dB = (wN * sqrt(-b_2 - sqrt(delta_4_3db))) / (2*pi); 

% 4. Banda passante di FASE
td_0 = 2*xi/wN; 
phi = @(w) -atan2((2*xi*w/wN), (1 - (w/wN).^2));
tolleranza_gradi = 1;

BP_fase_frequenze = [];
for w = omega_analitica
    fase_ideale_lineare = -td_0 * w;
    fase_reale = phi(w);
    errore_fase = abs(rad2deg(fase_ideale_lineare - fase_reale));
    
    if errore_fase < tolleranza_gradi
        BP_fase_frequenze = [BP_fase_frequenze, w/(2*pi)];
    end
end
f_lim_fase = max(BP_fase_frequenze);

% Stampa dei risultati
fprintf('Limiti di Banda Analitici del Sistema (Hz):\n');
fprintf('\tBanda utile (Accuratezza 1%%):  %.3f Hz\n', f_lim_1);
fprintf('\tBanda utile (Accuratezza 5%%):  %.3f Hz\n', f_lim_5);
fprintf('\tIntersezione soglia (+3dB):    %.3f Hz\n', f_lim_3dB);
fprintf('\tBanda passante di Fase (%d°):  %.3f Hz\n\n', tolleranza_gradi, f_lim_fase);

% Si ricava la risposta del sistema
sys = tf(1, [1/(wN^2), 2*xi/wN, 1]);
[mag_analitica, phase_analitica] = bode(sys, omega_analitica);

mag_db = 20 * log10(mag_analitica(:)); 

% Allineamento della fase analitica al range dei dati sperimentali [-360°, 0°]
phase_deg = phase_analitica(:);
phase_deg(phase_deg > 0) = phase_deg(phase_deg > 0) - 360; 

% Diagramma di bode completo
% ------------------------------------------------------------------------------

figure('Name', 'Verifica Modello Analitico', 'Color', 'w');
tiledlayout(2, 1, 'TileSpacing', 'compact'); 

% Modulo
ax1 = nexttile();
hold on; grid on;
xscale log;

title("Diagramma di Bode (Modello Analitico)");
ylabel("Rapporto di ampiezza [dB]");

plot(f_asse, mag_db, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Soluzione analitica');
plot(f_asse, 3 * ones(size(f_asse)), 'r--', 'LineWidth', 1.2, 'DisplayName', '+3 dB');
plot(f_lim_3dB, 3, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', ...
     'DisplayName', sprintf('Intersezione modulo (%.2f Hz)', f_lim_3dB));

legend('Location', 'southwest');
hold off;

% Fase
ax2 = nexttile();
hold on; grid on;
xscale log;

xlabel("Frequenza [Hz]");
ylabel("Sfasamento [°]");

fase_ideale_deg = rad2deg(-td_0 * omega_analitica);

plot(f_asse, phase_deg, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Fase analitica');
plot(f_asse, fase_ideale_deg, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Fase ideale lineare');

plot(f_asse, fase_ideale_deg + tolleranza_gradi, 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
plot(f_asse, fase_ideale_deg - tolleranza_gradi, 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');

fase_al_limite = interp1(f_asse, phase_deg, f_lim_fase);
plot(f_lim_fase, fase_al_limite, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', ...
     'DisplayName', sprintf('Limite linearità fase (%.2f Hz)', f_lim_fase));

ylim padded;
legend('Location', 'southwest');
hold off;

linkaxes([ax1, ax2], 'x');

% Calcolo della sensibilità
% ==============================================================================

banda_passante = [];
f_banda_passante = [];

sensibilita_lineare = deformation_magnitudes ./ force_magnitudes;

for i=1:length(frequency)
    if frequency(i)<=45 &&frequency(i)>=6
        f_banda_passante = [f_banda_passante;frequency(i)];
        banda_passante = [banda_passante;sensibilita_lineare(i)];
    end
end

S_med_lineare = mean(banda_passante);
S_var_lineare = var(banda_passante);
S_dev_lineare = sqrt(S_var_lineare);

t_critico = 2.201; %per un intervallo al 95%
inf_lineare= S_med_lineare - t_critico*S_dev_lineare/(sqrt(12));
sup_linare= S_med_lineare + t_critico*S_dev_lineare/(sqrt(12));

media_dB = 20*log10(S_med_lineare);
sup = 20*log10(sup_linare);
inf = 20*log10(inf_lineare);

figure();
hold on;
grid on;
title("Diagramma di Bode dell'ampiezza");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
xscale log;
scatter(frequency, magnitudes)
plot(omega, 20 * log10(analytical_magnitudes(:)));

fplot(@(x) media_dB*ones(size(x)), [min(omega), max(omega)],'k--', 'LineWidth', 1.2,'Color','b')
fplot(@(x) inf*ones(size(x)), [min(omega), max(omega)],'b')
fplot(@(x) sup*ones(size(x)), [min(omega), max(omega)],'b')

omega_col = omega(:);

legend('dati misurati', 'soluzione analitica','media della banda passante')
