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

subplot(2,1,1)
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
