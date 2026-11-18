classdef PIAVariable
    properties (SetAccess = private)
        ID string
        MFCounter = 0
    end

    properties
        Name string
        Range double
        MembershipFunctions PIAMembershipFunction = PIAMembershipFunction.empty
    end

    methods
        function obj = PIAVariable(id, name, range)
            obj.ID = id;
            obj.Name = name;
            obj.Range = range;
        end

        function obj = addMF(obj, name, type, parameters)
            obj.MFCounter = obj.MFCounter + 1;
            id = "mf_" + string(obj.MFCounter);

            mf = PIAMembershipFunction(id, name, type, parameters);
            obj.MembershipFunctions(end + 1) = mf;
        end

        function obj = updateMF(obj, index, name, type, parameters)
            obj.MembershipFunctions(index).Name = name;
            obj.MembershipFunctions(index).Type = type;
            obj.MembershipFunctions(index).Parameters = parameters;
        end

        function obj = deleteMF(obj, index)
            obj.MembershipFunctions(index) = [];
            obj = obj.updateMFIDs();
        end

        function obj = updateID(obj, id)
            obj.ID = id;
        end
    end

    methods (Access = private)
        function obj = updateMFIDs(obj)
            for i = 1:length(obj.MembershipFunctions)
                obj.MembershipFunctions(i) = ...
                    obj.MembershipFunctions(i).updateID( ...
                    "mf_" + string(i));
            end

            obj.MFCounter = length(obj.MembershipFunctions);
        end
    end
end