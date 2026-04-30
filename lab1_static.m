b = 20.9 / 1000;        % Larghezza del provino in m.
h = 1.9 / 1000;         % Spessore del provino in m.
l = (155-27) / 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('lab1/HB alluminio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V = table2array(data(:, 4));         % Deformazioni in mV/V

E = calcolaE(b, h, l, pesi, mV_V, "Mezzo");
scatter(pesi, E)


function E = calcolaE(b, h, l_estensimetro, pesi, mV_V, tipo_ponte)
gauge_factor = 2.08;
J = b * h^3 / 12;

M = pesi * 9.81 * l_estensimetro;

E = M ./ mV_V / 1000 * (gauge_factor * h) / J;

if tipo_ponte == "Mezzo"
    E = E / 4;
elseif tipo_ponte == "Quarto"
    E = E / 8;
end
end
