clc
clearvars
close all

%% Mezzo ponte per fibra di carbonio 

b = 31.4 / 1000;        % Larghezza del provino in m.
h = 1.98 / 1000;         % Spessore del provino in m.
l = 125/ 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('HB carbonio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V = table2array(data(:, 4)).*1e-3;         % Deformazioni in mV/V



M = pesi * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon = (2/k)*mV_V; 

sigma = M.*((0.5*h)/J);

E= sigma./epsilon;
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

plot(epsilon(2:10),sigma(2:10), 'o');
grid on; 


%% Quarto ponte per fibra di carbonio 

b = 31.4 / 1000;        % Larghezza del provino in m.
h = 1.98 / 1000;         % Spessore del provino in m.
l = 125/ 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('QB carbonio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V = table2array(data(:, 4)).*1e-3;         % Deformazioni in V/V



M = pesi * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon = (4/k)*mV_V; 
sigma = M.*((0.5*h)/J);

E = -sigma./epsilon;
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

plot(epsilon(2:10),sigma(2:10), 'o');
grid on; 



%% Mezzo ponte per fibra di alluminio

b = 20.9 / 1000;        % Larghezza del provino in m.
h = 1.9 / 1000;         % Spessore del provino in m.
l = (155-27) / 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('HB alluminio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V = table2array(data(:, 4).*1e-3);         % Deformazioni in mV/V



M = pesi * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon = (2/k)*mV_V; 
sigma = M.*((0.5*h)/J);

E = sigma./epsilon;
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

plot(epsilon(2:10),sigma(2:10), 'o');
grid on; 


%% Quarto ponte per alluminio
% nota quando abbiamo fatto il quarto di ponte avevamo l'estensimetro giù
% quindi abbiamo misurato le fibre compresse :| per questo il modulo di Young viene
% negativo 

b = 20.9 / 1000;        % Larghezza del provino in m.
h = 1.9 / 1000;         % Spessore del provino in m.
l = (155-27) / 1000;    % Distanza tra estensimetro e punto di carico in m.

data = readtable('QB alluminio.csv', 'VariableNamingRule', 'preserve');

n = table2array(data(:, 1));            % Numero della misura.
temperature = table2array(data(:, 2));  % Temperature in C°.
pesi = table2array(data(:, 3)) / 1000;  % Pesi in kg.
mV_V = table2array(data(:, 4).*1e-3);         % Deformazioni in mV/V



M = pesi * 9.81 * l;
k = 2.08;
J = b * h^3 / 12;

epsilon = (4/k)*mV_V; 
sigma = M.*((0.5*h)/J);

E = -sigma./epsilon;
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

plot(-epsilon(2:10),sigma(2:10), 'o');
grid on; 
