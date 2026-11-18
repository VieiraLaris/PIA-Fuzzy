function saida = inferenciaPIA(x)

validateattributes(x, {'numeric'}, ...
    {'vector', 'numel', 2, 'real', 'finite'});

nvar = 2;
nse = [3 3];

membfcn_in = [1 1 1 1 1 1];

param_in = [0 20 38 inf;
    20 38 56 inf;
    38 66 66 inf;
    0 30 60 inf;
    30 60 90 inf;
    60 95 95 inf];

% Definicao da saida
nss = 3;

membfcn_out = [1 1 1];

lim_search_out = [0 1];

param_out = [0 0.01 0.02 inf;
    0.49 0.5 0.51 inf;
    0.98 0.99 1 inf];

% Base de regras
% A segunda variavel (Sol) varia primeiro.
rb = [2 3 1 2 3 2 1 2 1];

% Normas de inferencia
tnorm = 'prod';
snorm = 'max';

% Configuracao da relacao crescente/decrescente
nat = fuzzyconfig(nvar, nse, rb);

% Calcula a inferencia
resultado = fuzzyout(x, nvar, nse, param_in, ...
    membfcn_in, nss, param_out, membfcn_out, rb, nat, ...
    tnorm, snorm);

% Limita a saida ao intervalo definido
saida = lim_out(resultado, lim_search_out);

end