filename_numbers = [55:57, 60:61]; % Selezione dei 5 segnali migliori.
filenames = arrayfun(@(n) sprintf("lab2/data_45_%03d.csv", n), filename_numbers);

times = cell(length(filenames), 1);
signals = cell(length(filenames), 1);
coeffAng = zeros(length(filenames), 1);

tStep = 400e-6; % Step temporale = 400 μs.
VStep = 5;      % Step di tensione = 5 mV.

for i = 1:length(filenames)
    data = readtable(filenames(i), "NumHeaderLines", 9, "VariableNamingRule","preserve");

    time = data{:, 1} * tStep;
    signal = data{:, 2} * VStep;

    % Si fanno iniziare tutti i segnali all'istante del primo impatto e li si fa 
    % finire quando la loro ampiezza scende sotto un limite.
    firstIndex = find(signal == max(signal), 1, "last");    
    lastIndex = find(signal > 1000 * VStep, 1, "last");
        
    times{i} = time(firstIndex:end) - time(firstIndex);
    signals{i} = signal(firstIndex:end);

    time = time(firstIndex:lastIndex) - time(firstIndex);
    signal = signal(firstIndex:lastIndex);

    peakIndexes = diff(signal) == 0;

    signal = abs(signal);
    
    coeff = polyfit(time(peakIndexes), log(signal(peakIndexes)), 1);
    coeffAng(i) = coeff(1);
        
    %scatter(time(peakIndexes), log(signal(peakIndexes)));
    %fplot(@(x) coeff(1) * x + coeff(2), [0, 0.3], "--", "DisplayName", sprintf("%f", xi));
end

omega_n = 2 * pi * 136; % 136 Hz è la risonanza che non ci viene 
xis = -coeffAng ./ omega_n;
xi = mean(xis);

fprintf("xi = %f", xi);


figure();
grid on;
hold on;
xlabel("Tempo [s]");
ylabel("Misura di deformazione [mV/V]")

fplot(@(x) VStep * 6767 * exp(-x * omega_n * xi), [0, 2], "r--");
fplot(@(x) -VStep * 6767 * exp(-x * omega_n * xi), [0, 2], "r--");

for i = 1:length(signals)
    plot(times{i}, signals{i});
end

legend([sprintf("Inviluppo corrispondente a \\xi = %f", xi)])

xlim([0, 1])
