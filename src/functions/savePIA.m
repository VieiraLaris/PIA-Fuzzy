function savePIA(pia, filename)

    if ~isa(pia, 'PIASystem')
        error('savePIA:SistemaInvalido', ...
            'O primeiro argumento deve ser um objeto PIASystem.');
    end

    if ~(ischar(filename) || ...
            (isstring(filename) && isscalar(filename)))
        error('savePIA:NomeArquivoInvalido', ...
            'O nome do arquivo deve ser um vetor de caracteres ou uma string escalar.');
    end

    filename = char(filename);

    if isempty(strtrim(filename))
        error('savePIA:NomeArquivoInvalido', ...
            'O nome do arquivo não pode estar vazio.');
    end

    [~, ~, extension] = fileparts(filename);

    if isempty(extension)
        filename = [filename '.pia'];

    elseif ~strcmpi(extension, '.pia')
        error('savePIA:ExtensaoInvalida', ...
            'A extensão do arquivo deve ser .pia.');
    end

    pia.validate();

    [fid, message] = fopen(filename, 'w', 'n', 'UTF-8');

    if fid == -1
        error('savePIA:ErroAoAbrirArquivo', ...
            'Não foi possível abrir o arquivo: %s', message);
    end

    fileCleanup = onCleanup(@() fclose(fid));

    %% Seção System

    fprintf(fid, '[System]\n');
    fprintf(fid, 'Name=%s\n', quoteString(pia.Name));
    fprintf(fid, 'NumInputs=%d\n', length(pia.Inputs));
    fprintf(fid, 'NumOutputs=%d\n', length(pia.Outputs));
    fprintf(fid, 'NumRules=%d\n', length(pia.Rules));
    fprintf(fid, 'TNorm=%s\n', quoteString(pia.TNorm));
    fprintf(fid, 'SNorm=%s\n\n', quoteString(pia.SNorm));

    %% Seção Inputs

    for i = 1:length(pia.Inputs)
        variable = pia.Inputs(i);

        fprintf(fid, '[Input%d]\n', i);
        fprintf(fid, 'Name=%s\n', quoteString(variable.Name));
        fprintf(fid, 'Range=%s\n', formatVector(variable.Range));
        fprintf(fid, 'NumMFs=%d\n', ...
            length(variable.MembershipFunctions));

        for j = 1:length(variable.MembershipFunctions)
            mf = variable.MembershipFunctions(j);

            fprintf(fid, 'MF%d=%s:%s,%s\n', ...
                j, ...
                quoteString(mf.Name), ...
                quoteString(mf.Type), ...
                formatVector(mf.Parameters));
        end

        fprintf(fid, '\n');
    end

    %% Seção Outputs

    for i = 1:length(pia.Outputs)
        variable = pia.Outputs(i);

        fprintf(fid, '[Output%d]\n', i);
        fprintf(fid, 'Name=%s\n', quoteString(variable.Name));
        fprintf(fid, 'Range=%s\n', formatVector(variable.Range));
        fprintf(fid, 'NumMFs=%d\n', ...
            length(variable.MembershipFunctions));

        for j = 1:length(variable.MembershipFunctions)
            mf = variable.MembershipFunctions(j);

            fprintf(fid, 'MF%d=%s:%s,%s\n', ...
                j, ...
                quoteString(mf.Name), ...
                quoteString(mf.Type), ...
                formatVector(mf.Parameters));
        end

        fprintf(fid, '\n');
    end

    %% Seção Rules

    fprintf(fid, '[Rules]\n');

    for i = 1:length(pia.Rules)
        rule = pia.Rules(i);

        antecedent = strtrim(sprintf('%g ', rule.Antecedent));
        consequent = strtrim(sprintf('%g ', rule.Consequent));

        fprintf(fid, '%s, %s\n', antecedent, consequent);
    end

    clear fileCleanup;

    edit(filename);
end

function result = quoteString(value)
    value = char(string(value));
    value = strrep(value, '''', '''''');
    result = ['''' value ''''];

end

function result = formatVector(values)
    result = mat2str(double(values(:)'), 15);
end