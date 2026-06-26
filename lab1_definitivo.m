
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%                                                         %%%%%%%%%
%%%%%%%%%         LABORATORIO 1: CAMPAGNA DI MISURA STATICA       %%%%%%%%%
%%%%%%%%%                                                         %%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

                            
clear
clc
close all

%% Codice 
tic;
% --------------------------- Caricamento dati ----------------------------

% Provino in alluminio.
b_Al = 29.94 / 1000;    % Larghezza in m.
h_Al = 1.9 / 1000;      % Spessore in m.
l_Al = (155-27) / 1000; % Distanza tra estensimetro e punto di carico in m.
E_teorico_Al = 70e9;    % Modulo di Young teorico per l'Alluminio in Pa

% Quarto di ponte con provino in alluminio.
QP_Al = readtable("QB alluminio.csv", "VariableNamingRule", "preserve");
QP_Al(:, 4) = table(-1 * table2array(QP_Al(:, 4))); % Correzione deformazione misurata negativa.
QP_Al_freddo = QP_Al(1:40, :);
QP_Al_caldo = QP_Al(41:end, :);

% Mezzo ponte con provino in alluminio.
MP_Al = readtable("HB alluminio.csv", "VariableNamingRule", "preserve");
MP_Al = MP_Al(~isnan(table2array(MP_Al(:, 4))), :); % Rimozione valori di deformazione NaN (outlier).
MP_Al_freddo = MP_Al(1:32, :);
MP_Al_caldo = MP_Al(33:end, :);

% Provino in carbonio.
b_C = 31.4 / 1000;  % Larghezza in m.
h_C = 1.98 / 1000;  % Spessore in m.
l_C = 125 / 1000;   % Distanza tra estensimetro e punto di carico in m.

% Quarto di ponte con provino in carbonio.
QP_C = readtable("QB carbonio.csv", "VariableNamingRule", "preserve");
QP_C(:, 4) = table(-1 * table2array(QP_C(:, 4))); % Correzione deformazione misurata negativa.
QP_C_freddo = QP_C(1:33, :);
QP_C_caldo = QP_C(34:end, :);

% Mezzo ponte con provino in carbonio.
MP_C = readtable("HB carbonio.csv", "VariableNamingRule", "preserve");
MP_C = MP_C(~isnan(table2array(MP_C(:, 4))), :); % Rimozione valori di deformazione NaN (outlier).
MP_C_freddo = MP_C(1:32, :);
MP_C_caldo = MP_C(33:end, :);

% --- Calcolo di sigma, epsilon, E per ogni prova e per ogni materiale ----

materiali = ["Alluminio"; "Carbonio"];
prove = ["Quarto di ponte a freddo", "Quarto di ponte a caldo", ...
         "Mezzo ponte a freddo", "Mezzo ponte a caldo"];

% Matrici che hanno per righe i materiali e per colonne le prove.
tabelle = {
    QP_Al_freddo, QP_Al_caldo, MP_Al_freddo, MP_Al_caldo;
    QP_C_freddo, QP_C_caldo, MP_C_freddo, MP_C_caldo};

sigma_matrix = cell(2, 4);
epsilon_matrix = cell(2, 4);
epsilon_teorico_matrix = cell(1, 4); 

for i = 1:length(materiali)
    if i == 1   % Alluminio.
        b = b_Al;
        h = h_Al;
        l = l_Al;
    else        % Carbonio.
        b = b_C;
        h = h_C;
        l = l_C;
    end

    for j = 1:length(prove)
        tabella = tabelle{i, j};
        peso = table2array(tabella(:, 3)) / 1000;   % Pesi in kg.
        deformazione_V_V = table2array(tabella(:, 4)) * 1e-3;   % Deformazioni in V/V.
        
        M = peso * 9.81 * l;    % Momento applicato sull"estensimetro.
        k = 2.08;               % Gauge factor.
        J = b * h^3 / 12;       % Momento d"inerzia.

        epsilon = deformazione_V_V * 4 / k; % Deformazioni (quarto di ponte).
         
        sigma = M * h / (2 * J);            % Sforzi.
       
        if j == 3 || j == 4   % Mezzo ponte.
            epsilon = epsilon / 2;
        end

        sigma_matrix{i, j} = sigma;
        epsilon_matrix{i, j} = epsilon;

        if i == 1  % Calcolo della soluzione analitica per Alluminio
            epsilon_teorico = sigma/E_teorico_Al;
            epsilon_teorico_matrix{i, j} = epsilon_teorico_matrix;

        end 
    end
end

% Calcolo di E per ogni prova e per ogni materiale.
E_matrix = zeros(2, 4);
q_matrix = zeros(2, 4); 

for i = 1:length(materiali)
    for j = 1:length(prove)
        p = polyfit(epsilon_matrix{i, j}, sigma_matrix{i, j}, 1);
        E_matrix(i, j) = p(1);
        q_matrix(i, j) = p(2);
    end
end

% -- Rappresentazione di sigma, epsilon per ogni prova con ogni materiale--

for i = 1:length(materiali)

    figure();
    hold on;
    grid on;
    title(sprintf("Grafico sforzo-deformazione, %s", materiali(i)));
    xlabel("Deformazione (\epsilon)");
    ylabel("Sforzo (\sigma) [Pa]");
    ylim([0, 3e7]);
    
    legenda = strings(length(prove));

    for j = 1:length(prove)
        scatter(epsilon_matrix{i, j}, sigma_matrix{i, j});

        legenda(j) = sprintf("%s (E = %f GPa)", prove(j), E_matrix(i, j) * 1e-9);
    end


    % Rette interpolanti.
    assi = gca;
    assi.ColorOrderIndex = 1;

    for j = 1:length(prove)
        intervallo = [min(epsilon_matrix{i, j}), max(epsilon_matrix{i, j})];
        fplot(@(x) E_matrix(i, j) * x + q_matrix(i, j), intervallo, ":");
    end

    
    if i == 1 % Alluminio
        h_teorico = fplot(@(x) E_teorico_Al * x, [0, 4*1e-4], 'k');
        legenda(9) = sprintf("Soluzione analitica (E = 70 GPa)");
    end

    legend(legenda);
    
end 

% Errori relativi percentuali sui moduli di Young per provino in alluminio.
er_qp_amb = abs(E_teorico_Al-E_matrix(1,1))/E_teorico_Al *100;
er_qp_ris = abs(E_teorico_Al-E_matrix(1,2))/E_teorico_Al *100;
er_hp_amb = abs(E_teorico_Al-E_matrix(1,3))/E_teorico_Al *100;
er_hp_ris = abs(E_teorico_Al-E_matrix(1,4))/E_teorico_Al *100;

% Deviazione std campionaria su E
E_medio_Al = mean(E_matrix(1,:));
E_medio_C = mean(E_matrix(2,:));
dev_E_Al = std(E_matrix(1,:));
dev_E_C = std(E_matrix(2,:));


% ----------- Curve di taratura per ogni prova e materiale ----------------

% In queste matrici vengono salvati i dati relativi alle regressioni lineari
% effettuate. 
m_matrix= zeros(2,4);
q_matrix= zeros(2,4);
n_matrix= zeros(2,4);
w_matrix= zeros(2,4); 
R_squared= zeros(2,4); 
er_max= zeros(2,4);

for i = 1:length(materiali)
 for j = 1:length(prove)

        tabella = tabelle{i, j};
        peso = (table2array(tabella(:, 3)) / 1000)* 9.81;   % Forza in N.
        def = table2array(tabella(:, 4)) * 1e-3;   % Deformazioni in V/V.

        if i == 1 && j == 1 % Alluminio.
            
            figure('Name', 'Analisi Cicli di Taratura - QP Alluminio a Temperatura ambiente');

            subplot(1,3,1);
            plot(peso(1:11), def(1:11), 'r-o'); axis square;
            grid on; title('Ciclo 1: Carico-Scarico');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            % subplot(2,2,2);
            % plot(peso(11:19), def(11:19), 'g-o');
            % grid on; title('Ciclo 2: Carico-Scarico');
            % xlabel('Massa [kg]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(19:29), def(19:29), 'b-o'); axis square;
            grid on; title('Ciclo 2: Carico-Scarico');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(29:40), def(29:40), 'c-o'); axis square;
            grid on; title('Ciclo 3: Carico-Scarico');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            [p, S, t1, t2, residui] = plots_modello(peso, def);


        elseif i == 1 && j == 2

            figure('Name', 'Analisi Cicli di Taratura - QP Alluminio riscaldato');

            subplot(1,3,1);
            plot(peso(1:11), def(1:11), 'r-o'); axis square;
            grid on; title('Ciclo 1');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(11:21), def(11:21), 'g-o');
            axis square;
            grid on; title('Ciclo 2');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(21:32), def(21:32), 'b-o'); axis square;
            grid on; title('Ciclo 3');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');
           
            [p, S, t1, t2, residui] = plots_modello(peso, def);

        elseif i==1 && j==3
            figure('Name', 'Analisi Cicli di Taratura - MP Alluminio a temperatura ambiente');

            subplot(1,3,1);
            plot(peso(1:10), def(1:10), 'r-o'); axis square;
            grid on; title('Ciclo 1');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(10:20), def(10:20), 'g-o');
            axis square;
            grid on; title('Ciclo 2');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(20:32), def(20:32), 'b-o'); axis square;
            grid on; title('Ciclo 3');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            [p, S, t1, t2, residui] = plots_modello(peso, def);

        elseif i==1 && j==4
            figure('Name', 'Analisi Cicli di Taratura  - MP Alluminio riscaldato');

            subplot(1,3,1);
            plot(peso(1:11), def(1:11), 'r-o'); axis square;
            grid on; title('Ciclo 1');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(11:21), def(11:21), 'g-o');
            axis square;
            grid on; title('Ciclo 2');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(21:33), def(21:33), 'b-o'); axis square;
            grid on; title('Ciclo 3');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            [p, S, t1, t2, residui] = plots_modello(peso, def);

        end 

        if i == 2 && j == 1 %Carbonio. 
            
            figure('Name', 'Analisi Cicli di Taratura  - QP Carbonio a Temperatura ambiente');

            subplot(1,3,1);
            plot(peso(1:11), def(1:11), 'r-o'); axis square;
            grid on; title('Ciclo 1');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(11:21), def(11:21), 'g-o');  axis square;
            grid on; title('Ciclo 2');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(21:33), def(21:33), 'b-o'); axis square;
            grid on; title('Ciclo 3');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            [p, S, t1, t2, residui] = plots_modello(peso, def);

        elseif i == 2 && j == 2

            figure('Name', 'Analisi Cicli di Taratura  - QP Carbonio riscaldato');

            subplot(1,3,1);
            plot(peso(1:11), def(1:11), 'r-o'); axis square;
            grid on; title('Ciclo 1');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(11:21), def(11:21), 'g-o');
            axis square;
            grid on; title('Ciclo 2');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(21:33), def(21:33), 'b-o'); axis square;
            grid on; title('Ciclo 3');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            [p, S, t1, t2, residui] = plots_modello(peso, def);

        elseif i==2 && j==3
            figure('Name', 'Analisi Cicli di Taratura  - MP Carbonio a temperatura ambiente');

            subplot(1,3,1);
            plot(peso(1:11), def(1:11), 'r-o'); axis square;
            grid on; title('Ciclo 1');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(11:21), def(11:21), 'g-o');
            axis square;
            grid on; title('Ciclo 2');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(21:32), def(21:32), 'b-o'); axis square;
            grid on; title('Ciclo 3');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            [p, S, t1, t2, residui] = plots_modello(peso, def);

        elseif i==2 && j==4
            figure('Name', 'Analisi Cicli di Taratura  - MP Carbonio riscaldato');

            subplot(1,3,1);
            plot(peso(1:11), def(1:11), 'r-o'); axis square;
            grid on; title('Ciclo 1');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,2);
            plot(peso(11:21), def(11:21), 'g-o');
            axis square;
            grid on; title('Ciclo 2');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

            subplot(1,3,3);
            plot(peso(21:33), def(21:33), 'b-o'); axis square;
            grid on; title('Ciclo 3');
            xlabel('Forza [N]'); ylabel('\DeltaV/V [-]');

           [p, S, t1, t2, residui] = plots_modello(peso, def);

        end 
        
        m_matrix(i,j) = p(1);
        q_matrix(i,j) = p(2);

        n_matrix(i,j) = t1; 
        w_matrix(i,j) = t2; 

        R_squared(i,j) = S.rsquared;
        
        er_max(i,j) = max(abs(residui));
 end 

end


% Variazioni percentuali tra i parametri ricavati a freddo e quelli a caldo

FS = 0.35*9.81; % Fondo Scala della misurazione. [N]

vn_Al_QP = ((n_matrix(1,2)-n_matrix(1,1))*((FS-w_matrix(1,1))/n_matrix(1,1))) *100 / FS ;
vw_Al_QP = (w_matrix(1,2)-w_matrix(1,1)) * 100 /FS;

vn_Al_MP = ((n_matrix(1,4)-n_matrix(1,3))*((FS-w_matrix(1,3))/n_matrix(1,3))) *100 / FS ;
vw_Al_MP = (w_matrix(1,4)-w_matrix(1,3)) * 100 /FS;

vn_C_QP = ((n_matrix(2,2)-n_matrix(2,1))*((FS-w_matrix(2,1))/n_matrix(2,1))) *100 / FS ;
vw_C_QP = (w_matrix(2,2)-w_matrix(2,1)) * 100 /FS;

vn_C_MP = ((n_matrix(2,4)-n_matrix(2,3))*((FS-w_matrix(2,3))/n_matrix(2,3))) *100 / FS ;
vw_C_MP = (w_matrix(2,4)-w_matrix(2,3)) * 100 /FS;


% -------------------------------------------------------------------------
% Deformazione Termica teorica
% Questi calcoli sono effettuati per la configurazione QP a caldo

alpha_Al = 2.3e-5; % Coefficiente di dilatazione termica dell'alluminio. [1/°C]
Delta_T = 1.6; % Variazione di temperatura. [°C]

epsilon_t_misurata = -1 * epsilon_matrix{1,2}(1);
epsilon_t_teorica_Al = alpha_Al * Delta_T;
er_t_Al = abs(epsilon_t_teorica_Al - epsilon_t_misurata)/epsilon_t_teorica_Al;

% Deformazione Assiale massima 

def_qp_Al_max = max(epsilon_matrix{1,1});
def_mp_Al_max = max(epsilon_matrix{1,3});
epsilon_ass_Al = def_qp_Al_max - def_mp_Al_max;

perc_su_fless_Al = (epsilon_ass_Al/def_mp_Al_max)*100;
perc_su_tot_Al = (epsilon_ass_Al/def_qp_Al_max)*100;

def_qp_C_max = max(epsilon_matrix{2,1});
def_mp_C_max = max(epsilon_matrix{2,3});
epsilon_ass_C = def_mp_C_max - def_qp_C_max;

perc_su_fless_C = (epsilon_ass_C/def_mp_C_max)*100;
perc_su_tot_C = (epsilon_ass_C/def_qp_C_max)*100;


% ----- Incertezze relative al Modulo di Young trovato per le prove -------

% Incertezze tipo relative alle lunghezze, gauge factor e misure lette da
% centrlina 

uL = 0.29/1000; 
ub = 0.0029/1000;
uh = 0.0029/1000;
uk_k = 1/100;
uDeltaV_V_V = 1/1000;

% Alluminio
uE_Al = sqrt((uL/l_Al)^2 + (ub/b_Al)^2 + (2*uh/h_Al)^2 + (uk_k)^2 + (uDeltaV_V_V)^2);

UE_Al_qf = 1.96 * uE_Al * E_matrix(1,1); 
UE_Al_qc = 1.96 * uE_Al * E_matrix(1,2); 
UE_Al_mf = 1.96 * uE_Al * E_matrix(1,3); 
UE_Al_mc = 1.96 * uE_Al * E_matrix(1,4); 

% Carbonio 
uE_C = sqrt((uL/l_C)^2 + (ub/b_C)^2 + (2*uh/h_C)^2 + (uk_k)^2 + (uDeltaV_V_V)^2); 

UE_C_qf = 1.96 * uE_C * E_matrix(2,1); 
UE_C_qc = 1.96 * uE_C * E_matrix(2,2); 
UE_C_mf = 1.96 * uE_C * E_matrix(2,3); 
UE_C_mc = 1.96 * uE_C * E_matrix(2,4); 

toc
%% FUNCTIONS 
% Questa sezione contiene le funzioni chimate durante l'esecuzione del
% codice.
function [p, S, t1, t2, residui] = plots_modello(peso, def)

% Questa funzione calcola i parametri della regressione lineare per il modello
% metrologico e, tramite la sua inversione, ricava la legge di taratura.
% Inoltre, genera i grafici del modello diretto e del modello inverso.
%
% INPUTS
% peso = vettore contenente le forze peso applicate ai provini [N]
% def = vettore contenente le deformazioni registrate da centralina [V/V]
%
% OUTPUTS
% p = vettore che contiene i coefficienti di regressione lineare del modello
% metrologico 
% S = struttura che contiene i parametri di bontà della regressione 
% t1 = coefficiente angolare del modello metrologico inverso
% t2 = intercetta all'ordinata del modello metrologico inverso

            figure('Name','Modello metrologico');
           
            [p, S]=polyfit(peso,def,1);
            def_fitted = polyval(p,peso);
            residui = def - def_fitted; 

            subplot(1,2,1);
            plot(peso, def_fitted, 'b'); hold on;
            plot(peso, def, 'om'); grid on;
            xlabel('Forza [N]');
            ylabel('\DeltaV/V [-]');
            legend('Retta interpolante', 'Dati', 'Location', 'best');

            subplot(1,2,2);
            scatter(peso, residui); grid on;
            xlabel('Forza [N]');
            ylabel('Deviazione \DeltaV/V [-]');

            t1 = 1/p(1);
            t2 = - p(2)/p(1);
            forze_fitted = t1 * def + t2; 
            residui = peso - forze_fitted; 
           
            figure('Name',' Inversione Modello metrologico');

            subplot(1,2,1);
            plot(def, forze_fitted, 'b'); hold on;
            plot(def, peso, 'om'); grid on;
            ylabel('Forza [N]');
            xlabel('\DeltaV/V [-]');
            legend('Retta interpolante', 'Dati', 'Location', 'best');

            subplot(1,2,2);
            scatter(def, residui); grid on;
            ylabel('Deviazione Forza [N]');
            xlabel('\DeltaV/V [-]');

end 

