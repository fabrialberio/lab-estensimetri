clc
clearvars
close all
%% 

filename = sprintf('data_45_062.csv');

data = readtable(filename, "NumHeaderLines", 9, "VariableNamingRule","preserve");

t = data{:,1};
signal = data{:, 2};

figure(1)
plot(t, signal); 

% cerco i picchi:
peaks = [];
peak_index=[];

for i = 4000 : 5500
    if signal(i) > signal(i-1) && signal(i) > signal(i+1) && signal(i) > 0
        peaks(end+1) = signal(i); 
        peak_index(end+1) = i;  
        
    end
end


figure(2)
plot(peak_index, peaks, 'o' );

Ts=400 * 1e-6;

% interpolo
y = log(peaks);

p = polyfit(peak_index*Ts,y,1);

omega_n = 2 * pi * 136; %136 è la risonanza che non ci viene 

ci = -p(1)/omega_n; 
