classdef PIAMembershipFunction
    properties (SetAccess = private)
        ID string
    end
    
    properties
        Name string
        Type string
        Parameters double
    end
    
    methods
        function obj = PIAMembershipFunction(id, name, type, parameters)
            obj.ID = id;
            obj.Name = name;
            obj.Type = type;
            obj.Parameters = parameters;
        end
        
        function obj = updateID(obj, id)
            obj.ID = id;
        end
    end
end