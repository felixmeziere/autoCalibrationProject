classdef (Abstract) algorithm < handle
    %UNTITLED24 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Abstract, Constant)
        parameters_required
        parameters_optional
        result_format
        algo
    end
    
    properties (Abstract, Access = public)
        parameters
    end
    
    properties
        result
    end    
    
    methods (Access = public)
        function [result] = run_algorithm(obj, parameters) 
            result=obj.algo(parameters);
            obj.result = result;
        end    
    end
    
end

