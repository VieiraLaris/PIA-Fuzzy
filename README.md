# PIA-Fuzzy

Este repositório é destinado ao desenvolvimento de uma toolbox para sistemas fuzzy baseada no método PIA, desenvolvida como parte do meu Trabalho de Conclusão de Curso (TCC), sob orientação do professor Bruno Luiz Pereira, da Universidade de Brasília (UnB).

## Estrutura do Projeto

```text
src/
├── core/                          # Classes do sistema PIA
│   ├── PIAMembershipFunction.m
│   ├── PIARule.m
│   ├── PIASystem.m
│   ├── PIAValidator.m
│   └── PIAVariable.m
│
├── engine/                        # Funções responsáveis pelo processamento do método PIA
│   ├── contr_var.m
│   ├── degmem.m
│   ├── fuzzyconfig.m
│   ├── fuzzyout.m
│   ├── lim_out.m
│   └── location.m
│
├── functions/                     # Funções auxiliares
│   ├── loadPIA.m
│   ├── plotPIA.m
│   ├── plotPIAOptions.m
│   ├── runPIA.m
│   └── savePIA.m
│
├── tests/                         # Scripts de teste manuais
│   ├── inferenciaMamdani.m
│   ├── inferenciaPIA.m
│   ├── inferenciaSugeno.m
│   ├── testQualitative.m
│   └── testQuantitative.m
│
└── setupPIA.m                     # Função de setup (PATH)
```

## Execução

Para utilizar a toolbox, entre na pasta `src`.
Configure o MATLAB Path executando:

```matlab
setupPIA
```

Depois, um sistema PIA pode ser criado utilizando `PIASystem`:

```matlab
pia = PIASystem("Nome do Sistema");
```

## Resumo dos Comandos

### Sistema

| Comando              | Descrição                                        |
| -------------------- | ------------------------------------------------ |
| `PIASystem("nome")`  | Cria um novo sistema PIA                         |
| `setupPIA()`         | Configura os caminhos necessários para a toolbox |
| `setNorm(pia, "tnorm", norma)` | Define a t-norma (operador AND): `'min'` ou `'prod'` (padrão: `'prod'`) |
| `setNorm(pia, "snorm", norma)` | Define a s-norma (operador OR): `'max'` ou `'sum'` (padrão: `'max'`)   |

### Variáveis de Entrada e de Saída

| Comando                                     | Descrição                                              |
| ------------------------------------------- | ------------------------------------------------------ |
| `addVariable(pia, "tipo", "nome", range)`   | Adiciona uma variável (`"tipo"` é `"input"` ou `"output"`) |
| `updateVariable(pia, "tipo", indice, Name="nome", Range=range)` | Atualiza o nome e/ou o intervalo da variável (informe pelo menos um) |
| `deleteVariable(pia, "tipo", indice)`       | Remove uma variável                                    |

### Funções de Pertinência

| Comando                                                         | Descrição                          |
| --------------------------------------------------------------- | ---------------------------------- |
| `addMF(pia, "tipo", id, "tipoMF", parametros, "nome")`          | Adiciona uma função de pertinência |
| `updateMF(pia, "tipo", id, idMF, Name="nome", Type="tipoMF", Parameters=parametros)` | Atualiza uma função de pertinência (informe pelo menos um dos campos) |
| `deleteMF(pia, "tipo", id, idMF)`                               | Remove uma função de pertinência   |

Nesses comandos, `"tipo"` é `"input"` ou `"output"`, `id` é o índice da variável e `idMF` é o índice da função de pertinência. Os tipos de função de pertinência suportados são `"trimf"` (3 parâmetros), `"trapmf"` (4 parâmetros) e `"gaussmf"` (média e desvio padrão).

### Descarte da Base de Regras

Adicionar ou remover uma variável (`addVariable`, `deleteVariable`) ou uma função de pertinência (`addMF`, `deleteMF`) invalida a base de regras. Se o sistema já tiver regras, uma janela pede a confirmação: ao continuar, a base de regras é descartada; ao cancelar (ou fechar a janela), a alteração não é feita. Atualizar nome, intervalo, tipo ou parâmetros (`updateVariable`, `updateMF`) não descarta as regras.

### Regras

| Comando                                       | Descrição                     |
| --------------------------------------------- | ----------------------------- |
| `addRule(pia, antecedent, consequent)`        | Adiciona uma regra ao sistema |
| `updateRule(pia, indice, Antecedent=vetor, Consequent=vetor)` | Atualiza uma regra (informe pelo menos um dos campos) |
| `deleteRule(pia, indice)`                     | Remove uma regra              |

### Execução

| Comando                         | Descrição                                                                 |
| ------------------------------- | ------------------------------------------------------------------------- |
| `runPIA(pia, input)`            | Valida o sistema, prepara os dados e retorna a saída                      |

### Salvar e Carregar

| Comando                    | Descrição                                      |
| -------------------------- | ---------------------------------------------- |
| `savePIA(pia, "arquivo")`  | Salva o sistema PIA em um arquivo              |
| `loadPIA("arquivo")`       | Carrega um sistema PIA salvo e o retorna       |

### Visualização

| Comando                                | Descrição                                              |
| -------------------------------------- | ------------------------------------------------------ |
| `plotPIAOptions()`              | Retorna a estrutura de opções com os valores padrão    |
| `plotPIA(pia)`                  | Plota a superfície de resposta com as opções padrão    |
| `plotPIA(pia, options)`         | Plota a superfície de resposta com as opções informadas |

Opções de `plotPIA`:

| Opção             | Descrição                                                                                      |
| ----------------- | ---------------------------------------------------------------------------------------------- |
| `InputIndex`      | Vetor com os índices das duas entradas dos eixos X e Y                                         |
| `OutputIndex`     | Índice da saída plotada no eixo Z                                                              |
| `NumGridPoints`   | Número de pontos da grade em cada eixo (inteiro maior ou igual a 2)                            |
| `ReferenceInputs` | Valores fixos das demais entradas, quando o sistema tem mais de duas. Se vazio, usa o ponto médio do intervalo de cada entrada |

## Exemplo de Uso

Um sistema PIA pode ser criado utilizando `PIASystem`:

```matlab
pia = PIASystem("Vitalidade");
```

A t-norma e a s-norma são definidas com `setNorm`:

```matlab
pia = setNorm(pia, "tnorm", 'prod');
pia = setNorm(pia, "snorm", 'max');
```

As entradas e saídas podem ser adicionadas com `addVariable`:

```matlab
pia = addVariable(pia, "input", "Água", [0 66]);
pia = addVariable(pia, "input", "Sol", [0 95]);

pia = addVariable(pia, "output", "Vitalidade", [0 1]);
```

As funções de pertinência das entradas podem ser adicionadas com `addMF`:

```matlab
% Água
pia = addMF(pia, "input", 1, "trimf", [0 20 38], "pequena");
pia = addMF(pia, "input", 1, "trimf", [20 38 56], "média");
pia = addMF(pia, "input", 1, "trimf", [38 66 66], "grande");

% Sol
pia = addMF(pia, "input", 2, "trimf", [0 30 60], "pequeno");
pia = addMF(pia, "input", 2, "trimf", [30 60 90], "médio");
pia = addMF(pia, "input", 2, "trimf", [60 95 95], "grande");
```

As funções de pertinência da saída também podem ser adicionadas com `addMF`:

```matlab
pia = addMF(pia, "output", 1, "trimf", [0 0 0.2], "baixa");
pia = addMF(pia, "output", 1, "trimf", [0.1 0.5 0.9], "média");
pia = addMF(pia, "output", 1, "trimf", [0.8 1 1], "alta");
```

As regras são adicionadas utilizando `addRule`. O primeiro vetor indica a função de pertinência de cada entrada, e o segundo, a da saída:

```matlab
pia = addRule(pia, [1 1], 2);
pia = addRule(pia, [1 2], 2);
pia = addRule(pia, [1 3], 1);
pia = addRule(pia, [2 1], 3);
pia = addRule(pia, [2 2], 3);
pia = addRule(pia, [2 3], 2);
pia = addRule(pia, [3 1], 1);
pia = addRule(pia, [3 2], 1);
pia = addRule(pia, [3 3], 1);
```

Variáveis, funções de pertinência e regras já criadas podem ser alteradas com os comandos `update`, informando apenas os campos que mudam:

```matlab
pia = updateVariable(pia, "input", 1, Name="Água (mm)");
pia = updateMF(pia, "input", 1, 2, Parameters=[18 38 58]);
pia = updateRule(pia, 1, Consequent=3);
```

Por fim, o sistema pode ser executado com `runPIA`, informando os valores das entradas:

```matlab
saida = runPIA(pia, [50 70]);
```

A superfície de resposta pode ser plotada com `plotPIA`:

```matlab
plotPIA(pia);
```

Para escolher as entradas, a saída e a resolução da grade:

```matlab
options = plotPIAOptions();
options.InputIndex = [1 2];
options.OutputIndex = 1;
options.NumGridPoints = 30;

plotPIA(pia, options);
```

O sistema pode ser salvo em um arquivo com `savePIA`:

```matlab
savePIA(pia, "vitalidade.pia");
```

Depois, ele pode ser carregado novamente com `loadPIA`:

```matlab
pia = loadPIA("vitalidade.pia");
```
