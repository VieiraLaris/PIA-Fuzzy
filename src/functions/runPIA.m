function outputValues = runPIA(pia, inputValues)

    % pia.validate();

    numInputs = length(pia.Inputs);
    numInputMFs = zeros(1, numInputs);

    for inputIndex = 1:numInputs
        numInputMFs(inputIndex) = ...
            length(pia.Inputs(inputIndex).MembershipFunctions);
    end

    inputMFParameters = [];
    inputMFTypes = [];

    for inputIndex = 1:numInputs
        for mfIndex = 1:numInputMFs(inputIndex)
            membershipFunction = ...
                pia.Inputs(inputIndex).MembershipFunctions(mfIndex);

            inputMFParameters = ...
                [inputMFParameters; membershipFunction.Parameters];

            if membershipFunction.Type == "trimf"
                inputMFTypes = [inputMFTypes 1];

            elseif membershipFunction.Type == "trapmf"
                inputMFTypes = [inputMFTypes 2];

            elseif membershipFunction.Type == "gaussmf"
                inputMFTypes = [inputMFTypes 3];
            end
        end
    end

    numOutputs = length(pia.Outputs);
    outputValues = zeros(1, numOutputs);

    numRules = length(pia.Rules);

    for ruleIndex = 1:numRules
        if length(pia.Rules(ruleIndex).Consequent) ~= numOutputs
            error('A regra %s deve possuir um consequente para cada saída.', ...
                pia.Rules(ruleIndex).ID);
        end
    end

    if numRules ~= prod(numInputMFs)
        error(['A base de regras deve ter %d regras (uma por combinação de ' ...
            'funções de pertinência), mas possui %d.'], ...
            prod(numInputMFs), numRules);
    end

    ruleIndexWeights = [1 cumprod(numInputMFs(1:end-1))];
    ruleIndices = zeros(1, numRules);

    for ruleIndex = 1:numRules
        antecedent = pia.Rules(ruleIndex).Antecedent;

        if numel(antecedent) ~= numInputs || ...
                any(antecedent < 1) || ...
                any(antecedent > numInputMFs(:)') || ...
                any(antecedent ~= fix(antecedent))
            error('O antecedente da regra %s é inválido.', ...
                pia.Rules(ruleIndex).ID);
        end

        ruleIndices(ruleIndex) = ...
            1 + sum((antecedent(:)' - 1) .* ruleIndexWeights);
    end

    if numel(unique(ruleIndices)) ~= numRules
        error(['Há regras com antecedentes repetidos: cada combinação deve ' ...
            'aparecer exatamente uma vez.']);
    end

    for outputIndex = 1:numOutputs
        numOutputMFs = ...
            length(pia.Outputs(outputIndex).MembershipFunctions);

        outputMFParameters = [];
        outputMFTypes = [];

        for mfIndex = 1:numOutputMFs
            membershipFunction = ...
                pia.Outputs(outputIndex).MembershipFunctions(mfIndex);

            outputMFParameters = ...
                [outputMFParameters; membershipFunction.Parameters];

            if membershipFunction.Type == "trimf"
                outputMFTypes = [outputMFTypes 1];

            elseif membershipFunction.Type == "trapmf"
                outputMFTypes = [outputMFTypes 2];

            elseif membershipFunction.Type == "gaussmf"
                outputMFTypes = [outputMFTypes 3];
            end
        end

        ruleBase = zeros(1, numRules);

        for ruleIndex = 1:numRules
            ruleBase(ruleIndices(ruleIndex)) = ...
                pia.Rules(ruleIndex).Consequent(outputIndex);
        end

        ruleDirectionMatrix = fuzzyconfig( ...
            numInputs, numInputMFs, ruleBase);

        outputValues(outputIndex) = lim_out( ...
            fuzzyout(inputValues, numInputs, numInputMFs, ...
                inputMFParameters, inputMFTypes, ...
                numOutputMFs, outputMFParameters, outputMFTypes, ...
                ruleBase, ruleDirectionMatrix, pia.TNorm, pia.SNorm), ...
            pia.Outputs(outputIndex).Range);
    end

end
