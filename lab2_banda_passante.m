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
