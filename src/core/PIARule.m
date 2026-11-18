classdef PIARule
    properties (SetAccess = private)
        ID string
    end
    
    properties
        Antecedent double
        Consequent double
    end
    
    methods
        function obj = PIARule(id, antecedent, consequent)
            obj.ID = id;
            obj.Antecedent = antecedent;
            obj.Consequent = consequent;
        end

        function obj = updateID(obj, id)
            obj.ID = id;
        end
    end
end