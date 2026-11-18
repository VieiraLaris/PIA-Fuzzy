classdef PIAValidator
    methods (Static)

        function validate(system)
            PIAValidator.checkTNorm(system.TNorm);
            PIAValidator.checkSNorm(system.SNorm);
            PIAValidator.validateVariables(system.Inputs);
            PIAValidator.validateVariables(system.Outputs);
            PIAValidator.validateRules(system);
        end

        function checkTNorm(tnorm)
            if ~ismember(tnorm, {'min', 'prod'})
                error('PIASystem:InvalidTNorm', 'T-norma inválida.');
            end
        end

        function checkSNorm(snorm)
            if ~ismember(snorm, {'max', 'sum'})
                error('PIASystem:InvalidSNorm', 'S-norma inválida.');
            end
        end
    end

    methods (Static, Access = private)

        function validateVariables(variables)
            for i = 1:numel(variables)
                variable = variables(i);

                if strlength(strtrim(string(variable.Name))) == 0
                    error('PIASystem:InvalidVariableName', ...
                        'A variável %d possui nome vazio.', i);
                end

                range = variable.Range;
                if numel(range) ~= 2 || ~isreal(range) || ...
                        any(~isfinite(range)) || range(1) >= range(2)
                    error('PIASystem:InvalidVariableRange', ...
                        'A variável "%s" possui intervalo inválido.', ...
                        variable.Name);
                end

                for j = 1:numel(variable.MembershipFunctions)
                    PIAValidator.validateMF( ...
                        variable.MembershipFunctions(j), variable);
                end
            end
        end

        function validateMF(mf, variable)
            range = variable.Range;
            params = mf.Parameters;

            if strlength(strtrim(string(mf.Name))) == 0
                error('PIASystem:InvalidMFName', ...
                    'Uma MF da variável "%s" possui nome vazio.', ...
                    variable.Name);
            end

            switch string(mf.Type)
                case "trimf"
                    expectedParams = 3;
                case "trapmf"
                    expectedParams = 4;
                case "gaussmf"
                    expectedParams = 2;
                otherwise
                    error('PIASystem:InvalidMFType', ...
                        'Tipo de MF inválido: "%s".', mf.Type);
            end

            if numel(params) ~= expectedParams || ...
                    ~isreal(params) || any(~isfinite(params))
                error('PIASystem:InvalidMFParameters', ...
                    'Parâmetros inválidos na MF "%s".', mf.Name);
            end

            switch string(mf.Type)
                case "trimf"
                    validParams = params(1) <= params(2) && ...
                        params(2) <= params(3);
                    positions = params;
                case "trapmf"
                    validParams = params(1) <= params(2) && ...
                        params(2) <= params(3) && ...
                        params(3) <= params(4);
                    positions = params;
                case "gaussmf"
                    % params(1) = sigma; params(2) = centro
                    validParams = params(1) > 0;
                    positions = params(2);
            end

            if ~validParams
                error('PIASystem:InvalidMFParameters', ...
                    'Os parâmetros da MF "%s" são incompatíveis.', ...
                    mf.Name);
            end

            if any(positions < range(1)) || any(positions > range(2))
                error('PIASystem:MFOutsideRange', ...
                    ['A MF "%s" possui posições fora do ' ...
                     'intervalo da variável "%s".'], ...
                    mf.Name, variable.Name);
            end
        end

        function validateRules(system)
            antecedentIDs = struct( ...
                'Count', 'PIASystem:InvalidAntecedentCount', ...
                'Invalid', 'PIASystem:InvalidAntecedent');
            antecedentMsgs = struct( ...
                'Count', 'A regra %s deve possuir %d antecedentes.', ...
                'Invalid', 'Antecedente inválido na regra %s, entrada "%s".');

            consequentIDs = struct( ...
                'Count', 'PIASystem:InvalidConsequentCount', ...
                'Invalid', 'PIASystem:InvalidConsequent');
            consequentMsgs = struct( ...
                'Count', 'A regra %s deve possuir %d consequentes.', ...
                'Invalid', 'Consequente inválido na regra %s, saída "%s".');

            for i = 1:numel(system.Rules)
                rule = system.Rules(i);
                PIAValidator.validateRuleReferences(rule, ...
                    rule.Antecedent, system.Inputs, ...
                    antecedentIDs, antecedentMsgs);
                PIAValidator.validateRuleReferences(rule, ...
                    rule.Consequent, system.Outputs, ...
                    consequentIDs, consequentMsgs);
            end
        end

        function validateRuleReferences(rule, values, variables, ids, msgs)
            if numel(values) ~= numel(variables)
                error(ids.Count, msgs.Count, rule.ID, numel(variables));
            end

            for j = 1:numel(variables)
                indexMF = values(j);
                nMFs = numel(variables(j).MembershipFunctions);
                if ~isfinite(indexMF) || indexMF < 1 || ...
                        indexMF ~= fix(indexMF) || indexMF > nMFs
                    error(ids.Invalid, msgs.Invalid, ...
                        rule.ID, variables(j).Name);
                end
            end
        end
    end
end