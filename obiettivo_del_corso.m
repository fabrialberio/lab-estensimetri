%% Obiettivo del corso!! Lo dice MATTEO!!

figure();
hold on;

xlabel("Peso [kg]");
ylabel("Deformazione [-]");

scatter(pesi(1:33), epsilon(1:33));

epsilon_anal = M * h / (2 * E * J); % Deformazione calcolata analiticamente.

plot(pesi(1:33), epsilon_anal(1:33));

%% Obiettivo del CORSO PER DAVVERO!!!!!!

figure();
hold on;

xlabel("Peso [kg]");
ylabel("\DeltaV/V [mV/V]");

scatter(pesi(1:33), mV_V(1:33));

mV_V_anal = M * k * h / (8 * E * J); % Deformazione in mV/V calcolata analiticamente.

plot(pesi(1:33), mV_V_anal(1:33));
