clc
clearvars
close all

%% modulo 
 
freqs = [0.3,0.4,0.5,0.6,0.7,0.8,0.9,...
    1,2,3,4,5,6,7,8,9,10,15,20,25,30,35,40,45,50,55,60,65,70,...
    80,90,100,110,120,130,140,150,160,170,180,190,200,210,220,...
    230,240,250,260,270,280,290,300]; 

amp_def = zeros(size(freqs));
amp_forza = zeros(size(freqs));
rapporto= zeros(size(freqs));

%% prova plot per vedere se è sinusoide 
filename = sprintf('50Hz.csv');

data_prova = readtable(filename, 'NumHeaderLines', 9, 'VariableNamingRule','preserve');

tempo = data_prova{:,1}; % nota: non è il tempo la prima colonna 
v_def = data_prova{:,2};
v_forza = data_prova{:,3};

figure(1) 
plot(tempo, v_def); 
figure(2)
plot(tempo, v_forza); 


%%

for i = 1:length(freqs)
    filename = sprintf('%gHz.csv', freqs(i));
    
    if isfile(filename)
        % leggiamo i dati saltando le 9 righe di intestazione
        % 'VariableNamingRule', 'preserve' serve per evitare errori con i nomi colonne
        data = readtable(filename, 'NumHeaderLines', 9, 'VariableNamingRule', 'preserve');
        
        % estraggo le colonne(Ch1 = Deformazione, Ch2 = Forza)
        v_def = data{:,2} * (5*1e3); 
        v_forza = data{:,3};
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

% plot bode : modulo 
amp_dB = 20 * log10(rapporto);
figure('Name', 'Bode: modulo ');
semilogx(freqs, amp_dB, 'o-');
grid on;
xlabel('Frequenza (Hz)');
ylabel('Modulo');


%% fase 

fasi = zeros(size(freqs));

for i = 1:length(freqs)
    filename = sprintf('%gHz.csv', freqs(i));
    if isfile(filename)
        data = readtable(filename, 'NumHeaderLines', 9);
        F= data{:, 3} - mean(data{:, 3}); % forza centrata
        D= data{:, 2} - mean(data{:, 2}); % feformazione centrata (bilancio a mano)
        
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

%Diagramma di Fase
figure('Name','Bode: Fase');
semilogx(freqs, fasi, '-or', 'LineWidth', 1.5);
grid on;
xlabel('Frequenza [Hz]');
ylabel('Fase [gradi]');


%% conslusione: hp di fallimento
% probabilmente i nostri dati sono fallati, perchè dove è la risonanza? 
% forse lo shaker non era vincolato bene ?
% forse il rumore a 100hz che ci hanno detto che c'era ci ha annulato la
% risonanza, spiegherebbe perchè a bassi hz ho ampiezze più alte ?
% forse aggiungendo i 25 chili sul tavolo abbiamo abbassato il rumore del
% tavolo a un livello che ha disturbato la misura?


%% analiticamente 
E = 70 * 1e9; % modulo alluminio 
b = 18.60 * 1e-3; 
h = 2.02 * 1e-3;
l = 111.34 * 1e-3; 
rho_al = 2700;  
coeff_c = 0.2357; 
% gemini dice che è il coefficiente da applicare per la trave a sbalzo
% essendo che questa massa non è concentrata ma distribuita (Cantilever)

J = b * h^3 / 12; 

k = (3*E*J)/(l^3); 

M = coeff_c * rho_al * l * b * h; %? 

fn = sqrt(k/M)/(2*pi); 



