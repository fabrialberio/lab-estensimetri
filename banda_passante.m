%% calcolo sensibilità

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

media_dB = 20*log10(S_med_lineare)
sup = 20*log10(sup_linare)
inf = 20*log10(inf_lineare)


figure();
hold on;
grid on;
title("Diagramma di Bode dell'ampiezza");
xlabel("Frequenza [Hz]");
ylabel("Rapporto di ampiezza [dB]");
xscale log;
scatter(frequency, magnitudes)
plot(omega, 20 * log10(analytical_magnitudes(:)));
plot(omega,media_dB*ones(length(omega)),'k--', 'LineWidth', 1.2,'Color','b')

plot(omega,sup*ones(length(omega)),'b')
plot(omega,inf*ones(length(omega)),'b')

omega_col = omega(:);

x_fill = [omega_col; flipud(omega_col)]; 
y_fill = [sup * ones(size(omega_col)); inf * ones(size(omega_col))];

h_area = fill(x_fill, y_fill, [0.85, 0.90, 1.0], ... 
             'FaceAlpha', 0.5, ...
             'EdgeColor', 'none', ...
             'HandleVisibility', 'off');

legend('dati misurati', 'soluzione analitica','media della banda passante')

% figure();
% hold on;
% grid on;
% 
% % Impostazione scala logaritmica (asse X)
% ax = gca;
% ax.XScale = 'log';
% 
% title("Diagramma di Bode dell'ampiezza");
% xlabel("Frequenza [Hz]");
% ylabel("Rapporto di ampiezza [dB]");
% 
% % Definiamo i vettori X e Y per il poligono di fill
% % X va da sinistra a destra (per sup) e poi torna da destra a sinistra (per inf)
% x_fill = [omega(:); flipud(omega(:))]; 
% y_fill = [sup * ones(size(omega(:))); inf * ones(size(omega(:)))];
% 
% % Disegna l'area evidenziata
% % 'FaceAlpha' regola la trasparenza (0 = trasparente, 1 = opaco)
% h_area = fill(x_fill, y_fill, [0.85 0.95 0.85], ... 
%              'FaceAlpha', 0.4, ...
%              'EdgeColor', 'none', ...
%              'HandleVisibility', 'off'); % Nasconde l'area dalla legenda principale
% 
% % Linee dei limiti (opzionali, tratteggiate sottili)
% plot(omega, sup * ones(size(omega)), 'g:', 'LineWidth', 1);
% plot(omega, inf * ones(size(omega)), 'g:', 'LineWidth', 1);
% 
% % Grafici principali
% scatter(frequency, magnitudes, 'filled');
% plot(omega, 20 * log10(analytical_magnitudes(:)), 'r', 'LineWidth', 1.5);
% plot(omega, S_med * ones(size(omega)), 'g', 'LineWidth', 1.5);
% 
% % Legenda aggiornata
% legend('Dati misurati', 'Soluzione analitica', 'Sensibilità strumento (Media)');