classdef PIASystem
    properties
        Name string
        Inputs PIAVariable = PIAVariable.empty
        Outputs PIAVariable = PIAVariable.empty
        Rules PIARule = PIARule.empty
        TNorm = 'prod'
        SNorm = 'max'
    end

    properties (Access = private)
        InputCounter = 0
        OutputCounter = 0
        RuleCounter = 0
    end

    methods
        function obj = PIASystem(name)
            obj.Name = name;
        end

        %% VARIÁVEIS (INPUT/OUTPUT)

        function obj = addVariable(obj, variableType, name, range)
            type = PIASystem.normalizeType(variableType);
            prop = PIASystem.propName(type);
            counter = PIASystem.counterName(type);

            candidate = obj;
            candidate.(counter) = candidate.(counter) + 1;
            id = type + "_" + string(candidate.(counter));

            newVar = PIAVariable(id, name, range);
            candidate.(prop)(end + 1) = newVar;

            [candidate, proceed] = candidate.confirmRuleBaseDiscard();
            if ~proceed
                return;
            end
            obj = candidate;
        end

        function obj = updateVariable(obj, variableType, index, options)
            arguments
                obj
                variableType
                index (1,1) double {mustBeInteger, mustBePositive}
                options.Name = ""
                options.Range = []
            end

            type = PIASystem.normalizeType(variableType);
            prop = PIASystem.propName(type);

            obj.(prop)(index);

            hasName = ~isempty(options.Name) && strlength(string(options.Name)) > 0;
            hasRange = ~isempty(options.Range);
            if ~hasName && ~hasRange
                error('PIASystem:NoUpdateFields', ...
                    'Informe pelo menos um campo para atualizar: Name e/ou Range.');
            end

            if hasName
                obj.(prop)(index).Name = options.Name;
            end
            if hasRange
                obj.(prop)(index).Range = options.Range;
            end
        end

        function obj = deleteVariable(obj, variableType, index)
            type = PIASystem.normalizeType(variableType);
            prop = PIASystem.propName(type);

            obj.(prop)(index);   % valida o índice

            candidate = obj;
            candidate.(prop)(index) = [];
            candidate = candidate.updateVariableIDs(type);

            [candidate, proceed] = candidate.confirmRuleBaseDiscard();
            if ~proceed
                return;
            end
            obj = candidate;
        end

        %% MEMBERSHIP FUNCTIONS

        function obj = addMF(obj, variableType, variableIndex, type, parameters, name)
            vType = PIASystem.normalizeType(variableType);
            prop = PIASystem.propName(vType);
            candidate = obj;

            variable = candidate.(prop)(variableIndex);
            candidate.(prop)(variableIndex) = ...
                variable.addMF(name, type, parameters);

            [candidate, proceed] = candidate.confirmRuleBaseDiscard();
            if ~proceed
                return;
            end
            obj = candidate;
        end

        function obj = updateMF(obj, variableType, variableIndex, mfIndex, options)
            arguments
                obj
                variableType
                variableIndex (1,1) double {mustBeInteger, mustBePositive}
                mfIndex (1,1) double {mustBeInteger, mustBePositive}
                options.Name = ""
                options.Type = ""
                options.Parameters = []
            end

            vType = PIASystem.normalizeType(variableType);
            prop = PIASystem.propName(vType);
            candidate = obj;

            variable = candidate.(prop)(variableIndex);
            currentMF = variable.MembershipFunctions(mfIndex);

            name = currentMF.Name;
            type = currentMF.Type;
            parameters = currentMF.Parameters;

            hasName = ~isempty(options.Name) && strlength(string(options.Name)) > 0;
            hasType = ~isempty(options.Type) && strlength(string(options.Type)) > 0;
            hasParameters = ~isempty(options.Parameters);
            if ~hasName && ~hasType && ~hasParameters
                error('PIASystem:NoUpdateFields', ...
                    ['Informe pelo menos um campo para atualizar: ' ...
                     'Name, Type e/ou Parameters.']);
            end

            if hasName
                name = options.Name;
            end
            if hasType
                type = options.Type;
            end
            if hasParameters
                parameters = options.Parameters;
            end

            candidate.(prop)(variableIndex) = ...
                variable.updateMF(mfIndex, name, type, parameters);

            obj = candidate;
        end

        function obj = deleteMF(obj, variableType, variableIndex, mfIndex)
            vType = PIASystem.normalizeType(variableType);
            prop = PIASystem.propName(vType);
            candidate = obj;

            variable = candidate.(prop)(variableIndex);
            candidate.(prop)(variableIndex) = variable.deleteMF(mfIndex);

            [candidate, proceed] = candidate.confirmRuleBaseDiscard();
            if ~proceed
                return;
            end
            obj = candidate;
        end

        %% RULES

        function obj = addRule(obj, antecedent, consequent)
            obj.RuleCounter = obj.RuleCounter + 1;
            id = "rule_" + string(obj.RuleCounter);

            rule = PIARule(id, antecedent, consequent);
            obj.Rules(end + 1) = rule;
        end

        function obj = updateRule(obj, index, options)
            arguments
                obj
                index (1,1) double {mustBeInteger, mustBePositive}
                options.Antecedent = []
                options.Consequent = []
            end

            obj.Rules(index);
            hasAntecedent = ~isempty(options.Antecedent);
            hasConsequent = ~isempty(options.Consequent);
            if ~hasAntecedent && ~hasConsequent
                error('PIASystem:NoUpdateFields', ...
                    ['Informe pelo menos um campo para atualizar: ' ...
                     'Antecedent e/ou Consequent.']);
            end

            if hasAntecedent
                obj.Rules(index).Antecedent = options.Antecedent;
            end
            if hasConsequent
                obj.Rules(index).Consequent = options.Consequent;
            end
        end

        function obj = deleteRule(obj, index)
            obj.Rules(index) = [];
            obj = obj.updateRuleIDs();
        end

        %% VALIDATION

        function validate(obj)
            PIAValidator.validate(obj);
        end

        %% NORMS

        function obj = setNorm(obj, normType, norm)
            switch lower(string(normType))
                case "tnorm"
                    PIAValidator.checkTNorm(norm);
                    obj.TNorm = norm;
                case "snorm"
                    PIAValidator.checkSNorm(norm);
                    obj.SNorm = norm;
                otherwise
                    error('PIASystem:InvalidNormType', ...
                        'O tipo de norma deve ser "tnorm" ou "snorm".');
            end
        end
    end

    %% MÉTODOS PRIVADOS
    
    methods (Static, Access = private)

        function type = normalizeType(variableType)
            type = lower(string(variableType));
            if ~ismember(type, ["input", "output"])
                error('PIASystem:InvalidVariableType', ...
                    'O tipo de variável deve ser "input" ou "output".');
            end
        end

        function name = propName(type)
            name = upper(extractBefore(type, 2)) + extractAfter(type, 1) + "s";
        end

        function name = counterName(type)
            name = upper(extractBefore(type, 2)) + extractAfter(type, 1) + "Counter";
        end
    end

    methods (Access = private)

        function obj = updateVariableIDs(obj, variableType)
            type = PIASystem.normalizeType(variableType);
            prop = PIASystem.propName(type);
            counter = PIASystem.counterName(type);

            for i = 1:numel(obj.(prop))
                obj.(prop)(i) = obj.(prop)(i).updateID(type + "_" + string(i));
            end
            obj.(counter) = numel(obj.(prop));
        end

        function [obj, proceed] = confirmRuleBaseDiscard(obj)
            proceed = true;
            if isempty(obj.Rules)
                return;
            end

            choice = questdlg( ...
                ['Esta alteração exige descartar a base de regras ' ...
                 'existente. Deseja continuar?'], ...
                'Confirmar alteração', ...
                'Continuar', 'Cancelar', 'Cancelar');

            if ~strcmp(choice, 'Continuar')
                proceed = false;
                return;
            end

            obj.Rules = PIARule.empty;
            obj.RuleCounter = 0;
            msgbox('A base de regras foi descartada.', ...
                'Base de regras descartada');
        end

        function obj = updateRuleIDs(obj)
            for i = 1:length(obj.Rules)
                obj.Rules(i) = obj.Rules(i).updateID("rule_" + string(i));
            end
            obj.RuleCounter = length(obj.Rules);
        end
    end
end