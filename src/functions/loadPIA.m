function pia = loadPIA(filename)

    if ~(ischar(filename) || ...
            (isstring(filename) && isscalar(filename)))
        error('loadPIA:NomeArquivoInvalido', ...
            'O nome do arquivo deve ser um vetor de caracteres ou uma string escalar.');
    end

    filename = char(filename);

    if isempty(strtrim(filename))
        error('loadPIA:NomeArquivoInvalido', ...
            'O nome do arquivo não pode estar vazio.');
    end

    [~, ~, extension] = fileparts(filename);

    if ~strcmpi(extension, '.pia')
        error('loadPIA:ExtensaoInvalida', ...
            'A extensão do arquivo deve ser .pia.');
    end

    [fid, message] = fopen(filename, 'r', 'n', 'UTF-8');

    if fid == -1
        error('loadPIA:ErroAoAbrirArquivo', ...
            'Não foi possível abrir o arquivo: %s', message);
    end

    fileCleanup = onCleanup(@() fclose(fid));

    sectionNames = {};
    sectionLines = {};
    currentSection = 0;

    while true
        line = fgetl(fid);

        if ~ischar(line)
            break;
        end

        line = strtrim(line);

        if isempty(line) || startsWith(line, '#') || ...
                startsWith(line, '%')
            continue;
        end

        if startsWith(line, '[') && endsWith(line, ']')
            sectionName = line(2:end-1);

            if any(strcmp(sectionNames, sectionName))
                error('loadPIA:SecaoDuplicada', ...
                    'Seção duplicada: [%s].', sectionName);
            end

            sectionNames{end + 1} = sectionName;
            sectionLines{end + 1} = {};
            currentSection = length(sectionNames);

        else
            if currentSection == 0
                error('loadPIA:FormatoInvalido', ...
                    'Conteúdo encontrado antes da primeira seção.');
            end

            sectionLines{currentSection}{end + 1} = line;
        end
    end

    clear fileCleanup;

    %% Seção System

    systemLines = getSection(sectionNames, sectionLines, 'System');

    name = readString(systemLines, 'Name');
    nInputs = readCount(systemLines, 'NumInputs');
    nOutputs = readCount(systemLines, 'NumOutputs');
    nRules = readCount(systemLines, 'NumRules');
    tnorm = readString(systemLines, 'TNorm');
    snorm = readString(systemLines, 'SNorm');

    pia = PIASystem(name);
    pia = pia.setNorm("tnorm", tnorm);
    pia = pia.setNorm("snorm", snorm);

    %% Seção Inputs

    for i = 1:nInputs
        sectionName = sprintf('Input%d', i);
        lines = getSection(sectionNames, sectionLines, sectionName);

        variableName = readString(lines, 'Name');
        range = readVector(lines, 'Range');
        nMFs = readCount(lines, 'NumMFs');

        pia = pia.addVariable("input", variableName, range);

        for j = 1:nMFs
            mfKey = sprintf('MF%d', j);
            [mfName, mfType, parameters] = readMF(lines, mfKey);

            pia = pia.addMF( ...
                "input", i, mfType, parameters, mfName);
        end
    end

    %% Seção Outputs

    for i = 1:nOutputs
        sectionName = sprintf('Output%d', i);
        lines = getSection(sectionNames, sectionLines, sectionName);

        variableName = readString(lines, 'Name');
        range = readVector(lines, 'Range');
        nMFs = readCount(lines, 'NumMFs');

        pia = pia.addVariable("output", variableName, range);

        for j = 1:nMFs
            mfKey = sprintf('MF%d', j);
            [mfName, mfType, parameters] = readMF(lines, mfKey);

            pia = pia.addMF( ...
                "output", i, mfType, parameters, mfName);
        end
    end

    %% Seção Rules

    ruleLines = getSection(sectionNames, sectionLines, 'Rules');

    if length(ruleLines) ~= nRules
        error('loadPIA:QuantidadeDeRegrasInvalida', ...
            'O valor de NumRules não corresponde à quantidade de regras.');
    end

    for i = 1:nRules
        parts = strsplit(ruleLines{i}, ',');

        if length(parts) ~= 2
            error('loadPIA:FormatoDeRegraInvalido', ...
                'Sintaxe inválida na regra %d.', i);
        end

        antecedent = parseVector(parts{1});
        consequent = parseVector(parts{2});

        pia = pia.addRule(antecedent, consequent);
    end

    %% Validação do sistema reconstruído

    pia.validate();

end


function lines = getSection(names, contents, sectionName)
    index = find(strcmp(names, sectionName), 1);

    if isempty(index)
        error('loadPIA:SecaoNaoEncontrada', ...
            'A seção obrigatória [%s] não foi encontrada.', sectionName);
    end

    lines = contents{index};
end


function value = getProperty(lines, key)
    pattern = ['^\s*' regexptranslate('escape', key) ...
        '\s*=\s*(.*?)\s*$'];

    for i = 1:length(lines)
        token = regexp(lines{i}, pattern, 'tokens', 'once');

        if ~isempty(token)
            value = token{1};
            return;
        end
    end

    error('loadPIA:PropriedadeNaoEncontrada', ...
        'A propriedade obrigatória "%s" não foi encontrada.', key);
end


function value = readString(lines, key)
    raw = getProperty(lines, key);

    token = regexp(raw, '^''((?:''''|[^''])*)''$', ...
        'tokens', 'once');

    if isempty(token)
        error('loadPIA:StringInvalida', ...
            'A propriedade "%s" deve estar entre aspas simples.', key);
    end

    value = strrep(token{1}, '''''', '''');
    value = string(value);
end


function value = readCount(lines, key)
    raw = getProperty(lines, key);
    value = str2double(raw);

    if ~isscalar(value) || ~isfinite(value) || ...
            value < 0 || value ~= fix(value)
        error('loadPIA:ContagemInvalida', ...
            'A propriedade "%s" deve ser um número inteiro não negativo.', key);
    end
end


function values = readVector(lines, key)
    raw = getProperty(lines, key);

    if isempty(regexp(raw, '^\s*\[.*\]\s*$', 'once'))
        error('loadPIA:VetorInvalido', ...
            'A propriedade "%s" deve utilizar colchetes.', key);
    end

    values = parseVector(raw);

    if isempty(values) || any(~isfinite(values))
        error('loadPIA:VetorInvalido', ...
            'A propriedade "%s" contém valores numéricos inválidos.', key);
    end
end


function values = parseVector(raw)
    raw = strrep(raw, '[', ' ');
    raw = strrep(raw, ']', ' ');
    raw = strrep(raw, ',', ' ');

    values = sscanf(raw, '%f')';

    normalized = regexprep(raw, ...
        '[+\-]?(?:\d+\.?\d*|\.\d+)(?:[eEdD][+\-]?\d+)?', '');

    if ~isempty(regexp(normalized, '[^\s]', 'once'))
        error('loadPIA:VetorInvalido', ...
            'Vetor numérico inválido: %s', raw);
    end
end


function [name, type, parameters] = readMF(lines, key)
    raw = getProperty(lines, key);

    pattern = ['^\s*''((?:''''|[^''])*)''\s*:\s*' ...
        '''([^'']+)''\s*,\s*(\[.*\])\s*$'];

    token = regexp(raw, pattern, 'tokens', 'once');

    if isempty(token)
        error('loadPIA:FormatoDeMFInvalido', ...
            'Definição inválida para a função de pertinência %s.', key);
    end

    name = string(strrep(token{1}, '''''', ''''));
    type = string(token{2});
    parameters = parseVector(token{3});

    if isempty(parameters) || any(~isfinite(parameters))
        error('loadPIA:ParametrosDeMFInvalidos', ...
            'Parâmetros inválidos para a função de pertinência %s.', key);
    end
end