clear;
clc;
close all;

%% Configuracoes do teste

nRep    = 100;
nWarmUp = 10;

pontos = [ 10  20;
           30  70;
           40  60;
           60  80 ];

%% Metodos de inferencia

metodos = {'PIA', 'Mamdani', 'Sugeno'};

avaliar = { @inferenciaPIA, ...
            @inferenciaMamdani, ...
            @inferenciaSugeno };

nPontos = size(pontos, 1);
tempos  = zeros(nRep, numel(metodos), nPontos);

%% Benchmark de inferencia

for m = 1:numel(metodos)
    f = avaliar{m};

    for p = 1:nPontos
        x = pontos(p, :);

        % Aquecimento
        for w = 1:nWarmUp
            f(x);
        end

        % Medicao do tempo
        for r = 1:nRep
            t = tic;
            f(x);
            tempos(r, m, p) = toc(t) * 1000;
        end
    end
end

%% Resultados por ponto

mediaPorPonto  = squeeze(mean(tempos, 1))';
desvioPorPonto = squeeze(std(tempos, 0, 1))';

fprintf('\nTempo de inferencia (ms), %d repeticoes por avaliacao\n\n', nRep);

for p = 1:nPontos
    fprintf('Ponto [%g %g]\n', pontos(p, 1), pontos(p, 2));

    for m = 1:numel(metodos)
        fprintf('  %-8s  media = %8.4f ms | desvio-padrao = %8.4f ms\n', ...
            metodos{m}, mediaPorPonto(p, m), desvioPorPonto(p, m));
    end
end

%% Resumo geral

fprintf('\nResumo geral\n');

resumo = table('Size', [numel(metodos) 3], ...
    'VariableTypes', {'string', 'double', 'double'}, ...
    'VariableNames', {'Metodo', 'Media_ms', 'Desvio_ms'});

for m = 1:numel(metodos)
    t = reshape(tempos(:, m, :), [], 1);

    resumo(m, :) = {string(metodos{m}), mean(t), std(t)};
end

disp(resumo);

%% Comparacao das saidas

fprintf('\nResultados das inferencias\n\n');

for p = 1:nPontos
    x = pontos(p, :);

    fprintf('Entradas [Agua = %g, Sol = %g]\n', x(1), x(2));

    for m = 1:numel(metodos)
        resultado = avaliar{m}(x);

        fprintf('  %-8s  Saida = %.6f\n', ...
            metodos{m}, resultado);
    end

    fprintf('\n');
end