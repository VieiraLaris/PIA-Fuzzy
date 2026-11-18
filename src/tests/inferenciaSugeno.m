function saida = inferenciaSugeno(x)

validateattributes(x, {'numeric'}, ...
    {'vector', 'numel', 2, 'real', 'finite'});

agua = x(1);
sol  = x(2);

mfAgua = [0 20 38;
    20 38 56;
    38 66 66];

mfSol = [0 30 60;
    30 60 90;
    60 95 95];

muAgua = zeros(1, 3);
muSol  = zeros(1, 3);

for i = 1:3
    muAgua(i) = trimfLocal(agua, mfAgua(i, :));
    muSol(i)  = trimfLocal(sol, mfSol(i, :));
end

% Base de regras:
regras = [1 1 2;
    1 2 2;
    1 3 1;
    2 1 3;
    2 2 3;
    2 3 2;
    3 1 1;
    3 2 1;
    3 3 1];

% Constantes de saida (Sugeno de ordem zero)
constantes = [0.2 0.5 0.8];

% Calcula as ativacoes e as saidas ponderadas
ativacoes = zeros(1, size(regras, 1));
valoresSaida = zeros(1, size(regras, 1));

for i = 1:size(regras, 1)
    idxAgua = regras(i, 1);
    idxSol  = regras(i, 2);
    idxSaida = regras(i, 3);

    ativacoes(i) = muAgua(idxAgua) * muSol(idxSol);

    valoresSaida(i) = constantes(idxSaida);
end

somaAtivacoes = sum(ativacoes);

if somaAtivacoes == 0
    error('Nenhuma regra foi ativada para os valores informados.');
end

saida = sum(ativacoes .* valoresSaida) / somaAtivacoes;

end


function mu = trimfLocal(x, parametros)
% Calcula o grau de pertinencia de uma funcao triangular.

a = parametros(1);
b = parametros(2);
c = parametros(3);

if x < a || x > c
    mu = 0;
elseif x == b
    mu = 1;
elseif x < b
    if a == b
        mu = 1;
    else
        mu = (x - a) / (b - a);
    end
else
    if b == c
        mu = 1;
    else
        mu = (c - x) / (c - b);
    end
end

end