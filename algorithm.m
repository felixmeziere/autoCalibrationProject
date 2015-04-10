classdef (Abstract) algorithm < handle
    %algorithm Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract, Constant)
        parameters_required
        parameters_optional
        result_format
        algo
    end
    
    properties (Access = public)
        parameters=struct;
        knobs
    end
    
    properties (SetAccess = private)
        result
    end    
    
    methods (Access = public)
        function [result] = run_algorithm(obj) 
            result=eval(evalf(obj.algo,obj.parameters));
            obj.result = result;
        end
    end
    
end

