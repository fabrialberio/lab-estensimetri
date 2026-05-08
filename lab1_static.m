%% Dati

% Provino in alluminio.
b_Al = 29.94 / 1000;    % Larghezza in m.
h_Al = 1.9 / 1000;      % Spessore in m.
l_Al = (155-27) / 1000; % Distanza tra estensimetro e punto di carico in m.

% Quarto di ponte con provino in alluminio.
QP_Al = readtable("lab1/QB alluminio.csv", "VariableNamingRule", "preserve");
QP_Al(:, 4) = table(-1 * table2array(QP_Al(:, 4))); % Correzione deformazione misurata negativa.
QP_Al_freddo = QP_Al(1:40, :);
QP_Al_caldo = QP_Al(41:end, :);

% Mezzo ponte con provino in alluminio.
MP_Al = readtable("lab1/HB alluminio.csv", "VariableNamingRule", "preserve");
MP_Al = MP_Al(~isnan(table2array(MP_Al(:, 4))), :); % Rimozione valori di deformazione NaN (outlier).

% Provino in carbonio.
b_C = 31.4 / 1000;  % Larghezza in m.
h_C = 1.98 / 1000;  % Spessore in m.
l_C = 125 / 1000;   % Distanza tra estensimetro e punto di carico in m.

% Quarto di ponte con provino in carbonio.
QP_C = readtable("lab1/QB carbonio.csv", "VariableNamingRule", "preserve");
QP_C(:, 4) = table(-1 * table2array(QP_C(:, 4))); % Correzione deformazione misurata negativa.
QP_C_freddo = QP_C(1:33, :);
QP_C_caldo = QP_C(34:end, :);

% Mezzo ponte con provino in carbonio.
MP_C = readtable("lab1/HB carbonio.csv", "VariableNamingRule", "preserve");
MP_C = MP_C(~isnan(table2array(MP_C(:, 4))), :); % Rimozione valori di deformazione NaN (outlier).

%% Calcolo di sigma, epsilon, E per ogni prova e per ogni materiale

materiali = ["Alluminio"; "Carbonio"];
prove = ["Quarto di ponte a freddo", "Quarto di ponte a caldo", "Mezzo ponte"];

% Matrici che hanno per righe i materiali e per colonne le prove.
tabelle = {
    QP_Al_freddo, QP_Al_caldo, MP_Al;
    QP_C_freddo, QP_C_caldo, MP_Al};

sigma_matrix = cell(2, 3);
epsilon_matrix = cell(2, 3);

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
        peso = table2array(tabella(:, 3)) / 1000;               % Pesi in kg.
        deformazione_V_V = table2array(tabella(:, 4)) * 1e-3;   % Deformazioni in V/V.

        M = peso * 9.81 * l;    % Momento applicato sull"estensimetro.
        k = 2.08;               % Gauge factor.
        J = b * h^3 / 12;       % Momento d"inerzia.

        epsilon = deformazione_V_V * 4 / k; % Deformazioni (quarto di ponte).
        sigma = M * h / (2 * J);            % Sforzi.

        if j == 3   % Mezzo ponte.
            epsilon = epsilon / 2;
        end

        sigma_matrix{i, j} = sigma;
        epsilon_matrix{i, j} = epsilon;
    end
end

% Calcolo di E per ogni prova e per ogni materiale.
E_matrix = zeros(2, 3);
q_matrix = zeros(2, 3); % Matrice dei valori di "sbilanciamento" del ponte (intercette della retta interpolante).

for i = 1:length(materiali)
    for j = 1:length(prove)
        p = polyfit(epsilon_matrix{i, j}, sigma_matrix{i, j}, 1);
        E_matrix(i, j) = p(1);
        q_matrix(i, j) = p(2);
    end
end

%% Rappresentazione di sigma, epsilon per ogni prova e ogni materiale

for i = 1:length(materiali)
    figure();
    hold on;
    grid on;
    title(sprintf("Grafico sforzo-deformazione, %s", materiali(i)));
    xlabel("Deformazione (\epsilon)");
    ylabel("Sforzo (\sigma)");
    ylim([0, 3e7]);
    
    legenda = strings(length(prove));

    for j = 1:length(prove)
        scatter(epsilon_matrix{i, j}, sigma_matrix{i, j});

        legenda(j) = sprintf("%s (E = %f)", prove(j), E_matrix(i, j) * 1e-9);
    end

    % Rette interpolanti.
    assi = gca;
    assi.ColorOrderIndex = 1;

    for j = 1:length(prove)
        intervallo = [min(epsilon_matrix{i, j}), max(epsilon_matrix{i, j})];
        fplot(@(x) E_matrix(i, j) * x + q_matrix(i, j), intervallo, ":");
    end

    legend(legenda);
end
