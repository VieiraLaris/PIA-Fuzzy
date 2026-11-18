function plotPIA(pia, options)

    if nargin < 2 || isempty(options)
        options = plotPIAOptions();
    end

    if ~isa(pia, 'PIASystem')
        error('plotPIA:InvalidSystem', ...
            'O primeiro argumento deve ser um objeto PIASystem.');
    end

    if ~isstruct(options)
        error('plotPIA:InvalidOptions', ...
            'As opções devem ser fornecidas por plotPIAOptions.');
    end

    nInputs = numel(pia.Inputs);
    nOutputs = numel(pia.Outputs);

    if nInputs < 2
        error('plotPIA:InsufficientInputs', ...
            'O sistema deve possuir pelo menos duas entradas.');
    end

    if nOutputs < 1
        error('plotPIA:NoOutputs', ...
            'O sistema deve possuir pelo menos uma saída.');
    end

    defaults = plotPIAOptions();

    optionNames = fieldnames(options);

    for i = 1:numel(optionNames)
        if ~isfield(defaults, optionNames{i})
            error('plotPIA:UnknownOption', ...
                'Opção desconhecida: %s.', optionNames{i});
        end
    end

    fields = fieldnames(defaults);

    for i = 1:numel(fields)
        if ~isfield(options, fields{i})
            options.(fields{i}) = defaults.(fields{i});
        end
    end

    inputIndex = options.InputIndex;
    outputIndex = options.OutputIndex;
    numGridPoints = options.NumGridPoints;

    if ~isnumeric(inputIndex) || ~isreal(inputIndex) || ...
            numel(inputIndex) ~= 2 || ...
            any(~isfinite(inputIndex)) || ...
            any(inputIndex ~= fix(inputIndex)) || ...
            numel(unique(inputIndex)) ~= 2 || ...
            any(inputIndex < 1) || any(inputIndex > nInputs)

        error('plotPIA:InvalidInputIndex', ...
            'InputIndex deve conter dois índices válidos e distintos.');
    end

    if ~isnumeric(outputIndex) || ~isreal(outputIndex) || ...
            ~isscalar(outputIndex) || ~isfinite(outputIndex) || ...
            outputIndex ~= fix(outputIndex) || ...
            outputIndex < 1 || outputIndex > nOutputs

        error('plotPIA:InvalidOutputIndex', ...
            'OutputIndex deve indicar uma saída válida.');
    end

    if ~isnumeric(numGridPoints) || ~isreal(numGridPoints) || ...
            ~isscalar(numGridPoints) || ~isfinite(numGridPoints) || ...
            numGridPoints < 2 || numGridPoints ~= fix(numGridPoints)

        error('plotPIA:InvalidGridPoints', ...
            'NumGridPoints deve ser um inteiro maior ou igual a 2.');
    end

    if isempty(options.ReferenceInputs)
        referenceInputs = zeros(1, nInputs);

        for i = 1:nInputs
            range = pia.Inputs(i).Range;
            referenceInputs(i) = mean(range);
        end
    else
        referenceInputs = options.ReferenceInputs;

        if ~isnumeric(referenceInputs) || ...
                ~isreal(referenceInputs) || ...
                ~isvector(referenceInputs) || ...
                numel(referenceInputs) ~= nInputs || ...
                any(~isfinite(referenceInputs))

            error('plotPIA:InvalidReferenceInputs', ...
                'ReferenceInputs deve conter um valor válido para cada entrada.');
        end

        referenceInputs = reshape(referenceInputs, 1, []);
    end

    for i = 1:nInputs
        range = pia.Inputs(i).Range;

        if ~isnumeric(range) || numel(range) ~= 2 || ...
                any(~isfinite(range)) || range(1) >= range(2)

            error('plotPIA:InvalidRange', ...
                'Intervalo inválido para a entrada %d.', i);
        end

        if ~ismember(i, inputIndex) && ...
                (referenceInputs(i) < range(1) || ...
                 referenceInputs(i) > range(2))

            error('plotPIA:ReferenceOutOfRange', ...
                'Valor de referência fora do intervalo da entrada %d.', i);
        end
    end

    xRange = pia.Inputs(inputIndex(1)).Range;
    yRange = pia.Inputs(inputIndex(2)).Range;

    xValues = linspace(xRange(1), xRange(2), numGridPoints);
    yValues = linspace(yRange(1), yRange(2), numGridPoints);

    [X, Y] = meshgrid(xValues, yValues);

    Z = zeros(numGridPoints, numGridPoints);

    for i = 1:numGridPoints
        for j = 1:numGridPoints

            inputValues = referenceInputs;

            inputValues(inputIndex(1)) = xValues(i);
            inputValues(inputIndex(2)) = yValues(j);

            result = runPIA(pia, inputValues);

            if ~isnumeric(result) || ...
                    numel(result) < outputIndex || ...
                    ~isfinite(result(outputIndex))

                error('plotPIA:InvalidResult', ...
                    'A inferência retornou um resultado inválido.');
            end

            Z(j, i) = result(outputIndex);
        end
    end

    figure;

    surf(X, Y, Z);
    axis tight;
    view(-37.5, 30);

    grid on;

    xlabel(pia.Inputs(inputIndex(1)).Name);
    ylabel(pia.Inputs(inputIndex(2)).Name);
    zlabel(pia.Outputs(outputIndex).Name);

    title("Sistema PIA");

end