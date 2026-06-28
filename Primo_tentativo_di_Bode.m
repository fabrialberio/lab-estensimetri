% Primo tentativo di Bode 
clc
clearvars
close all

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
    filename = sprintf('lab2_renamed/%gHz.csv', freqs(i));
    
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
    filename = sprintf('lab2_renamed/%gHz.csv', freqs(i));
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
% ------------------------------------------------------------------------------

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

