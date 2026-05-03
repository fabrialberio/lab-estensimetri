clc
clearvars
close all

%% Mezzo ponte per fibra di carbonio 

b = 31.38 / 1000;        % Larghezza del provino in m.
h = 2.04 / 1000;         % Spessore del provino in m.
l = 125/ 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('HB carbonio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V_hc = table2array(data(:, 4)).*1e-3;         % Deformazioni in mV/V



M = pesi * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon_hc = (2/k)*mV_V_hc; 

sigma_hc = M.*((0.5*h)/J);

E= sigma_hc./epsilon_hc;
sum=0; 
n=0; 
for i=1:length(E)
    if E(i)~=0 && ~isnan(E(i))
        sum=sum+E(i); 
        n=n+1; 
    end 
end
media=sum/n; 
disp("E per carbonio a mezzo ponte :"); disp(media); 



%% Quarto ponte per fibra di carbonio 

b = 31.4 / 1000;        % Larghezza del provino in m.
h = 1.98 / 1000;         % Spessore del provino in m.
l = 125/ 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('QB carbonio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V_qc = -table2array(data(:, 4)).*1e-3;         % Deformazioni in V/V



M = pesi * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon_qc = (4/k)*mV_V_qc; 
sigma_qc = M.*((0.5*h)/J);

E_qc = sigma_qc./epsilon_qc;
sum=0; 
n=0; 
for i=1:length(E)
    if E(i)~=0 && ~isnan(E(i))
        sum=sum+E(i); 
        n=n+1; 
    end 
end
media=sum/n; 
disp("E per carbonio a quarto ponte:"); disp(media); 

%% plot carbonio ciclo 1 di carico
figure(1);
plot(epsilon_qc(1:6),sigma_qc(1:6));
hold on;
plot(epsilon_hc(1:6), sigma_hc(1:6));
hold on; 
plot(epsilon_qc(34:39), sigma_qc(34:39));
hold on; 
plot(epsilon_hc(34:39), sigma_hc(34:39)); 

xlabel('deformazione');
ylabel('sforzo');
legend('quarto ponte a T=22.1', 'mezzo ponte a T=22.1','quarto ponte T=23.4°C', ...
    'mezzo ponte T=23.4°C','Location','southeast');
grid on; 

%% plot carbonio ciclo 2 di carico
figure(2); 
plot(epsilon_qc(11:16),sigma_qc(11:16));
hold on;
plot(epsilon_hc(11:16), sigma_hc(11:16));
hold on; 
plot(epsilon_qc(44:49), sigma_qc(44:49));
hold on; 
plot(epsilon_hc(44:49), sigma_hc(44:49)); 

xlabel('deformazione');
ylabel('sforzo');
legend('quarto ponte a T=22.1', 'mezzo ponte a T=22.1','quarto ponte T=23.4°C', ...
    'mezzo ponte T=23.4°C','Location','southeast');
grid on; 

%% compensazione termica ?
figure(3); 
plot(pesi(34:39),epsilon_hc(34:39), 'r-', 'DisplayName', 'hb carbonio a T=23.4');
hold on;
plot(pesi(34:39),epsilon_hc(1:6) , 'b-', 'DisplayName', 'hb carbonio a T=22.1');
hold on; 
plot(pesi(34:39), epsilon_qc(34:39), 'g-', 'DisplayName', 'qb carbonio a T=23.4');
hold on; 
plot(pesi(34:39), epsilon_qc(1:6), '-', 'DisplayName', 'qb carbonio a T=22.1');
xlabel('peso [Kg]');
ylabel('deformazioni [-]');
legend('show', 'Location','southeast');
grid on;

%% Mezzo ponte per fibra di alluminio

b = 29.94 / 1000;        % Larghezza del provino in m.
h = 1.9 / 1000;         % Spessore del provino in m.
l = (155-27) / 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('HB alluminio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi_ha = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V = table2array(data(:, 4).*1e-3);         % Deformazioni in mV/V



M = pesi_ha * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon_ha = (2/k)*mV_V; 
sigma_ha = M.*((0.5*h)/J);

E = sigma_ha./epsilon_ha;
sum=0; 
n=0; 
for i=1:length(E)
    if E(i)~=0 && ~isnan(E(i))
        sum=sum+E(i); 
        n=n+1; 
    end 
end
media=sum/n; 
disp("E per alluminio a mezzo:"); disp(media); 

plot(epsilon_ha(2:10),sigma_ha(2:10), 'o');
grid on; 


%% Quarto ponte per alluminio
% nota quando abbiamo fatto il quarto di ponte avevamo l'estensimetro giù
% quindi abbiamo misurato le fibre compresse :| per questo il modulo di Young viene
% negativo compenso con il - 

b = 29.94 / 1000;        % Larghezza del provino in m.
h = 1.9 / 1000;         % Spessore del provino in m.
l = (155-27) / 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('QB alluminio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi_qa = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V = -table2array(data(:, 4).*1e-3);         % Deformazioni in mV/V



M = pesi_qa * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon_qa = (4/k)*mV_V; 
sigma_qa = M.*((0.5*h)/J);

E = sigma_qa./epsilon_qa;
sum=0; 
n=0; 
for i=1:length(E)
    if E(i)~=0 && ~isnan(E(i))
        sum=sum+E(i); 
        n=n+1; 
    end 
end
media=sum/n; 
disp("E per alluminio a quarto:"); disp(media); 

plot(epsilon_qa(2:10),sigma_qa(2:10), 'o');
grid on; 
%% compensazione termica ?
figure(3); 
plot(pesi_ha(44:49),epsilon_ha(44:49), 'r-', 'DisplayName', 'hb alluminio a T=23.7');
hold on;
plot(pesi_ha(44:49),epsilon_ha(11:16) , 'b-', 'DisplayName', 'hb alluminio a T=22.1');
hold on; 
plot(pesi_qa(19:24), epsilon_qa(51:56), 'g-', 'DisplayName', 'qb alluminio a T=23.7');
hold on; 
plot(pesi_qa(19:24), epsilon_qa(19:24), '-', 'DisplayName', 'qb alluminio a T=22.1');
xlabel('peso [Kg]');
ylabel('deformazioni [-]');
legend('show', 'Location','southeast');
grid on;


