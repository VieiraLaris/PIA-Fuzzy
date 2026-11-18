function options = plotPIAOptions(NameValueArgs)
    arguments
        NameValueArgs.InputIndex (1,2) double = [1 2]
        NameValueArgs.OutputIndex (1,1) double = 1
        NameValueArgs.NumGridPoints (1,1) double = 15
        NameValueArgs.ReferenceInputs double = []
    end

    options = NameValueArgs;
end