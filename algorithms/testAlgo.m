classdef testAlgo < algorithm
    
    properties
        someproperty
    end
    
    methods (Access = public)
        function [obj] = addsomething(obj, string)
            disp(string)
        end    
    end
    
end

