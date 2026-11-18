function saida = inferenciaMamdani(x)

%% Configuração das funções de pertinência

mfAgua = [ 0 20 38;
    20 38 56;
    38 66 66 ];

mfSol = [ 0 30 60;
    30 60 90;
    60 95 95 ];

mfSaida = [ 0   0   0.2;
    0.1 0.5 0.9;
    0.8 1   1   ];

%% Base de regras

regras = [1 1 2;
    1 2 2;
    1 3 1;
    2 1 3;
    2 2 3;
    2 3 2;
    3 1 1;
    3 2 1;
    3 3 1];

%% Universo de discurso da saída

universoSaida = linspace(0, 1, 101);

%% 1. Fuzzificação

muAgua = zeros(1, 3);
muSol  = zeros(1, 3);

for i = 1:3
    muAgua(i) = trimfLocal(x(1), mfAgua(i, :));
    muSol(i)  = trimfLocal(x(2), mfSol(i, :));
end

%% 2. Inferência das regras

nRegras = size(regras, 1);

ativacoes = zeros(nRegras, 1);

for r = 1:nRegras

    indiceAgua = regras(r, 1);
    indiceSol  = regras(r, 2);

    ativacoes(r) = min( ...
        muAgua(indiceAgua), ...
        muSol(indiceSol));

end

%% 3. Implicação e agregação

agregado = zeros(size(universoSaida));

for r = 1:nRegras

    indiceSaida = regras(r, 3);

    mu = trimfLocal(universoSaida, ...
        mfSaida(indiceSaida, :));

    implicada = min(mu, ativacoes(r));

    agregado = max(agregado, implicada);

end

%% 4. Defuzzificação: centroide

denominador = sum(agregado);

if denominador == 0
    saida = NaN;
else
    saida = sum(universoSaida .* agregado) / denominador;
end

end


%% Função de pertinência triangular

function mu = trimfLocal(x, parametros)

a = parametros(1);
b = parametros(2);
c = parametros(3);

mu = zeros(size(x));

if a == b
    mu(x <= b) = 1;
else
    idx = x >= a & x <= b;
    mu(idx) = (x(idx) - a) / (b - a);
end

if b == c
    mu(x >= b) = 1;
else
    idx = x >= b & x <= c;
    mu(idx) = max(mu(idx), (c - x(idx)) / (c - b));
end

mu = max(0, min(1, mu));

end