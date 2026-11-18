clear;
clc;
close all;

numGridPoints = 30;
outputIndex   = 1;

[pia, mamdani, sugeno] = criarSistemasVioletas();

%% Gráficos das variáveis
plotarVariaveis = true;

if plotarVariaveis
    figure('Name', 'TEMP - MFs Água');
    plotmf(mamdani, 'input', 1);
    title('Água (ml)');

    figure('Name', 'TEMP - MFs Sol');
    plotmf(mamdani, 'input', 2);
    title('Sol (min)');

    figure('Name', 'TEMP - MFs Vitalidade');
    plotmf(mamdani, 'output', 1);
    title('Vitalidade');
end

%% Gráficos das superfícies de saída
figure('Name', 'Mamdani - Violetas');
gensurf(mamdani, [1 2], outputIndex, [numGridPoints numGridPoints]);
title('Sistema Mamdani');

figure('Name', 'Sugeno - Violetas');
gensurf(sugeno, [1 2], outputIndex, [numGridPoints numGridPoints]);
title('Sistema Sugeno');

opcoes = plotPIAOptions();
opcoes.InputIndex    = [1 2];
opcoes.OutputIndex   = outputIndex;
opcoes.NumGridPoints = numGridPoints;

plotPIA(pia, opcoes);

function [pia, mamdani, sugeno] = criarSistemasVioletas()

    %% PIA
    pia = PIASystem("Vitalidade");
    pia = setNorm(pia, "tnorm", 'prod');
    pia = setNorm(pia, "snorm", 'max');

    pia = addVariable(pia, "input",  "Água", [0 66]);
    pia = addVariable(pia, "input",  "Sol", [0 95]);
    pia = addVariable(pia, "output", "Vitalidade", [0 1]);

    pia = addMF(pia, "input", 1, "trimf", [-0.1 0 26], "pequena");
    pia = addMF(pia, "input", 1, "trimf", [22 33 44], "média");
    pia = addMF(pia, "input", 1, "trimf", [38 66 66.1], "grande");

    pia = addMF(pia, "input", 2, "trimf", [-0.1 0 35], "pequeno");
    pia = addMF(pia, "input", 2, "trimf", [30 46.25 62.5], "médio");
    pia = addMF(pia, "input", 2, "trimf", [60 95 95.1], "grande");
    
    pia = addMF(pia, "output", 1, "trimf", [0 0 0.2], "ruim");
    pia = addMF(pia, "output", 1, "trimf", [0.1 0.5 0.9], "média");
    pia = addMF(pia, "output", 1, "trimf", [0.8 1 1], "boa");

    pia = addRule(pia, [1 1], 2);
    pia = addRule(pia, [1 2], 2);
    pia = addRule(pia, [1 3], 1);

    pia = addRule(pia, [2 1], 3);
    pia = addRule(pia, [2 2], 3);
    pia = addRule(pia, [2 3], 2);

    pia = addRule(pia, [3 1], 1);
    pia = addRule(pia, [3 2], 1);
    pia = addRule(pia, [3 3], 1);

    %% Base de regras dos FIS
    regrasFis = [1 1 2 1 1;
                 1 2 2 1 1;
                 1 3 1 1 1;
                 2 1 3 1 1;
                 2 2 3 1 1;
                 2 3 2 1 1;
                 3 1 1 1 1;
                 3 2 1 1 1;
                 3 3 1 1 1];

    %% Mamdani
    mamdani = mamfis('Name', 'Violeta_Mamdani', ...
        'AndMethod', 'min', 'OrMethod', 'max', ...
        'ImplicationMethod', 'min', 'AggregationMethod', 'max', ...
        'DefuzzificationMethod', 'centroid');

    mamdani = addInput(mamdani, [0 66], 'Name', 'Água');
    
    mamdani = addMF(mamdani, 'Água', 'trimf', [0 0 26], 'Name', 'pequena');
    mamdani = addMF(mamdani, 'Água', 'trimf', [22 33 44], 'Name', 'média');
    mamdani = addMF(mamdani, 'Água', 'trimf', [38 66 66], 'Name', 'grande');

    mamdani = addInput(mamdani, [0 95], 'Name', 'Sol');
    
    mamdani = addMF(mamdani, 'Sol', 'trimf', [0 0 35], 'Name', 'pequeno');
    mamdani = addMF(mamdani, 'Sol', 'trimf', [30 46.25 62.5], 'Name', 'médio');
    mamdani = addMF(mamdani, 'Sol', 'trimf', [60 95 95], 'Name', 'grande');

    mamdani = addOutput(mamdani, [0 1], 'Name', 'Vitalidade');
    mamdani = addMF(mamdani, 'Vitalidade', 'trimf', [0 0 0.2], 'Name', 'ruim');
    mamdani = addMF(mamdani, 'Vitalidade', 'trimf', [0.1 0.5 0.9], 'Name', 'média');
    mamdani = addMF(mamdani, 'Vitalidade', 'trimf', [0.8 1 1], 'Name', 'boa');

    mamdani = addRule(mamdani, regrasFis);

    %% Sugeno
    sugeno = sugfis('Name', 'Violeta_Sugeno', 'AndMethod', 'min');

    sugeno = addInput(sugeno, [0 66], 'Name', 'Água');
  
    sugeno = addMF(sugeno, 'Água', 'trimf', [0 0 26], 'Name', 'pequena');
    sugeno = addMF(sugeno, 'Água', 'trimf', [22 33 44], 'Name', 'média');
    sugeno = addMF(sugeno, 'Água', 'trimf', [38 66 66], 'Name', 'grande');

    sugeno = addInput(sugeno, [0 95], 'Name', 'Sol');

    sugeno = addMF(sugeno, 'Sol', 'trimf', [0 0 35], 'Name', 'pequeno');
    sugeno = addMF(sugeno, 'Sol', 'trimf', [30 46.25 62.5], 'Name', 'médio');
    sugeno = addMF(sugeno, 'Sol', 'trimf', [60 95 95], 'Name', 'grande');

    sugeno = addOutput(sugeno, [0 1], 'Name', 'Vitalidade');
    sugeno = addMF(sugeno, 'Vitalidade', 'constant', 0.2, 'Name', 'ruim');
    sugeno = addMF(sugeno, 'Vitalidade', 'constant', 0.5, 'Name', 'média');
    sugeno = addMF(sugeno, 'Vitalidade', 'constant', 0.8,  'Name', 'boa');

    sugeno = addRule(sugeno, regrasFis);
end