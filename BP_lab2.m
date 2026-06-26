%%

% Ordina il vettore delle frequenze in modo crescente e ottieni gli indici di ordinamento
[frequency_sorted, sort_idx] = sort(frequency);

% Usa gli stessi indici per ordinare i rapporti di ampiezza (e le fasi, se ti servono)
magnitudes_sorted = magnitudes(sort_idx);
phases_sorted = phases(sort_idx); % Opzionale, per mantenere la consistenza cinematica

%% BANDA PASSANTE PER DATI SPERIMENTALI
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
f_asse = omega/(2*pi);

subplot(2,1,1)
figure();
hold on;
grid on;

title("Diagramma di Bode dell'ampiezza");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
xscale log;

scatter(frequency_sorted, magnitudes_sorted)
plot(f_asse, -3 * ones(length(f_asse), 1), 'r--', 'LineWidth', 1.2)
plot(f_asse,  3 * ones(length(f_asse), 1), 'r--', 'LineWidth', 1.2)

% Primo elemento: Stella Verde più grande
plot(BP(1), magnitudes_sorted(BP_indx(1)), 'p', 'MarkerSize', 14, ...
    'MarkerFaceColor', [0.4660 0.6740 0.1880], 'MarkerEdgeColor', 'k', ...
    'DisplayName', sprintf('Inizio BP (%.2f Hz)', BP(1)));

% Ultimo elemento: Stella Rossa/Arancione più grande
plot(BP(end), magnitudes_sorted(BP_indx(end)), 'p', 'MarkerSize', 14, ...
    'MarkerFaceColor', [0.8500 0.3250 0.0980], 'MarkerEdgeColor', 'k', ...
    'DisplayName', sprintf('Fine BP (%.2f Hz)', BP(end)));


% Configurazione della legenda
legend('dati misurati', '-3dB', '+3dB', 'Inizio Banda Passante', 'Fine Banda Passante', 'Location', 'southwest')

hold off;


%% --- CALCOLO DELLE BANDE DI LINEARITÀ E PASSANTE ---
fN = 44.6996;
wN = 2*pi*fN;% Pulsazione naturale in rad/s
xi = 0.007048;    % Smorzamento

% 1. Calcolo teorico della banda di accuratezza all'1% (e = 0.01)
e_1 = 0.01;
a = 1;
b_2 = -(1 - 2*xi^2); 
c_1 = 1 - 1/((1+e_1)^2);
delta_4_1 = b_2^2 - a*c_1;

w_lim_1 = wN * sqrt(-b_2 - sqrt(delta_4_1)); 

% 2. Calcolo teorico della banda di accuratezza al 5% (e = 0.05)
e_5 = 0.05;
c_5 = 1 - 1/((1+e_5)^2);
delta_4_5 = b_2^2 - a*c_5; 

w_lim_5 = wN * sqrt(-b_2 - sqrt(delta_4_5));

% 3. Calcolo teorico del punto di intersezione a +3dB (Adattato al secondo caso: a = 1)
% Poiché a = 1, il termine noto c per i +3dB (modulo lineare = sqrt(2)) vale esattamente 0.5
c_3dB = 0.5;
delta_4_3db = b_2^2 - a*c_3dB;

td = @(w) 2*xi/wN * (1 + (w/wN)^2)./((1 - (w/wN)^2)^2 + (2*xi*(w/wN))^2);

BP_fase = [];
phi = @(w) -atan((2*xi*w/wN)./(1 - (w/wN).^2));
for w = omega
    if abs(rad2deg(-td(w)*w - phi(w))) < 10
        BP_fase = [BP_fase w/(2*pi)];
    end
end

% Usiamo il segno MENO prima della radice del delta per trovare l'incontro in salita
w_3dB = wN * sqrt(-b_2 - sqrt(delta_4_3db)); 

% --- CONVERSIONE DA PULSAZIONE (rad/s) A FREQUENZA (Hz) ---
f_lim_1 = w_lim_1 / (2*pi);
f_lim_5 = w_lim_5 / (2*pi);
f_lim_3dB = w_3dB / (2*pi);

% Stampa i risultati in console
fprintf('--- Limiti di Banda del Sistema in Frequenza (Hz) ---\n');
fprintf('Banda utile (Accuratezza 1%%): %.3f Hz\n', f_lim_1);
fprintf('Banda utile (Accuratezza 5%%): %.3f Hz\n', f_lim_5);
fprintf('Intersezione soglia (+3dB): %.3f Hz\n\n', f_lim_3dB);

% Generazione asse frequenze per la curva analitica
omega = exp(linspace(log(0.1), log(500), 500));
f_asse = omega / (2*pi);

% Calcolo della risposta analitica del sistema per il confronto
sys = tf(1, [1/(wN^2), 2*xi/wN, 1]);
[mag_analitica, ~] = bode(sys, omega);
mag_db = 20 * log10(mag_analitica(:)); 

figure('Color', 'w');
tiledlayout(1, 1);
ax = nexttile();
hold on;
grid on;
ax.XMinorGrid = 'on';
ax.YMinorGrid = 'on';

title("Diagramma di Bode dell'ampiezza");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
xscale log;

%1. Plot della curva analitica
plot(f_asse, mag_db, 'b-', 'LineWidth', 1.2, 'DisplayName', 'Soluzione analitica');

% 2. Linea di soglia costante a +3dB
plot(f_asse, 3 * ones(size(f_asse)), 'r--', 'LineWidth', 1.2, 'DisplayName', '+3 dB');

% 3. Punto in cui finisce la BP
plot(f_lim_3dB, 3, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', 'DisplayName', 'Incontro analitica e +3dB');

% Regolazione dei limiti degli assi sui tuoi dati reali
xlim([0.1, 500]);
ylim([min(magnitudes_sorted) - 5, max(magnitudes_sorted) + 5]);

% Configurazione della legenda
legend('Location', 'southwest');
hold off;

%% ORDINAMENTO DEI DATI
[frequency_sorted, sort_idx] = sort(frequency);
magnitudes_sorted = magnitudes(sort_idx);
phases_sorted = phases(sort_idx);

%% BANDA PASSANTE SPERIMENTALE 
E_max = 3;
E_min = -3;
BP_sperimentale = [];
BP_indx = [];

% Calcolo BP
for i = 1:length(frequency_sorted)
    if magnitudes_sorted(i) < E_max && magnitudes_sorted(i) > E_min
        BP_sperimentale = [BP_sperimentale; frequency_sorted(i)];
        BP_indx = [BP_indx; i];
    end
end

% Generazione dell'asse frequenze pulito per le curve analitiche
omega_analitica = exp(linspace(log(0.1), log(500), 1000));
f_asse = omega_analitica / (2*pi);

figure('Name', 'Banda Passante Sperimentale', 'Color', 'w');
hold on; grid on;
title("Diagramma di Bode dell'ampiezza (Dati Sperimentali)");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
set(gca, 'XScale', 'log');

scatter(frequency_sorted, magnitudes_sorted, 35, 'filled', 'MarkerFaceColor', [0 0.4470 0.7410]);
plot(f_asse, -3 * ones(length(f_asse), 1), 'r--', 'LineWidth', 1.2);
plot(f_asse,  3 * ones(length(f_asse), 1), 'r--', 'LineWidth', 1.2);

if ~isempty(BP_sperimentale)
    plot(BP_sperimentale(1), magnitudes_sorted(BP_indx(1)), 'p', 'MarkerSize', 14, ...
        'MarkerFaceColor', [0.4660 0.6740 0.1880], 'MarkerEdgeColor', 'k');
    plot(BP_sperimentale(end), magnitudes_sorted(BP_indx(end)), 'p', 'MarkerSize', 14, ...
        'MarkerFaceColor', [0.8500 0.3250 0.0980], 'MarkerEdgeColor', 'k');
    legend('Dati misurati', '-3dB', '+3dB', ...
           sprintf('Inizio BP Sp. (%.2f Hz)', BP_sperimentale(1)), ...
           sprintf('Fine BP Sp. (%.2f Hz)', BP_sperimentale(end)), 'Location', 'southwest');
else
    legend('Dati misurati', '-3dB', '+3dB', 'Location', 'southwest');
end
hold off;

%% --- PARAMETRI DEL SISTEMA ---
fN = 44.6996;
wN = 2*pi*fN;       
xi = 0.007048;      
tolleranza_gradi = 10; 

% Asse frequenze analitico
omega_analitica = exp(linspace(log(0.1), log(500), 1000));
f_asse = omega_analitica / (2*pi);

%% --- CALCOLO DELLE BANDE PASSANTI ANALITICHE ---
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
fprintf('--- Limiti di Banda Analitici del Sistema (Hz) ---\n');
fprintf('Banda utile (Accuratezza 1%%):  %.3f Hz\n', f_lim_1);
fprintf('Banda utile (Accuratezza 5%%):  %.3f Hz\n', f_lim_5);
fprintf('Intersezione soglia (+3dB):    %.3f Hz\n', f_lim_3dB);
fprintf('Banda passante di Fase (%d°):  %.3f Hz\n\n', tolleranza_gradi, f_lim_fase);

%% --- ESTRAZIONE RISPOSTA DEL SISTEMA ---
sys = tf(1, [1/(wN^2), 2*xi/wN, 1]);
[mag_analitica, phase_analitica] = bode(sys, omega_analitica);

mag_db = 20 * log10(mag_analitica(:)); 

% Allineamento della fase analitica al range dei dati sperimentali [-360°, 0°]
phase_deg = phase_analitica(:);
phase_deg(phase_deg > 0) = phase_deg(phase_deg > 0) - 360; 

%% --- GENERAZIONE DIAGRAMMA DI BODE COMPLETO ---
figure('Name', 'Verifica Modello Analitico', 'Color', 'w');
tiledlayout(2, 1, 'TileSpacing', 'compact'); 

% PANNELLO 1: MODULO
ax1 = nexttile();
hold on; grid on;
ax1.XMinorGrid = 'on'; ax1.YMinorGrid = 'on';
set(ax1, 'XScale', 'log');

title("Diagramma di Bode (Modello Analitico)");
ylabel("Rapporto di ampiezza [dB]");

plot(f_asse, mag_db, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Soluzione analitica');
plot(f_asse, 3 * ones(size(f_asse)), 'r--', 'LineWidth', 1.2, 'DisplayName', '+3 dB');
plot(f_lim_3dB, 3, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', ...
     'DisplayName', sprintf('Intersezione modulo (%.2f Hz)', f_lim_3dB));

xlim([0.1, 500]);
ylim([min(magnitudes_sorted) - 5, max(magnitudes_sorted) + 5]);
legend('Location', 'southwest');
hold off;

% PANNELLO 2: FASE
ax2 = nexttile();
hold on; grid on;
ax2.XMinorGrid = 'on'; ax2.YMinorGrid = 'on';
set(ax2, 'XScale', 'log');

xlabel("Frequenza [Hz]");
ylabel("Sfasamento [°]");

% Calcolo curve di fase
fase_ideale_deg = rad2deg(-td_0 * omega_analitica);

% Plot delle curve principali
plot(f_asse, phase_deg, 'b-', 'LineWidth', 1.5, 'DisplayName', 'Fase analitica');
plot(f_asse, fase_ideale_deg, 'k--', 'LineWidth', 1.2, 'DisplayName', 'Fase ideale lineare');

% Plot dei limiti di tolleranza della fase (Linee sottili per pulizia visiva)
plot(f_asse, fase_ideale_deg + tolleranza_gradi, 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
plot(f_asse, fase_ideale_deg - tolleranza_gradi, 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');

% Evidenzia il punto limite sulla retta
fase_al_limite = interp1(f_asse, phase_deg, f_lim_fase);
plot(f_lim_fase, fase_al_limite, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r', ...
     'DisplayName', sprintf('Limite linearità fase (%.2f Hz)', f_lim_fase));

xlim([0.1, 500]);
ylim([-370, 10]); 
yticks(-360:90:0); 
legend('Location', 'southwest');
hold off;

% Sincronizzazione dello zoom sui due grafici
linkaxes([ax1, ax2], 'x');
