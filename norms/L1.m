classdef L1 < Norm
    %UNTITLED20 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='L1';
    end
    
    methods (Access = public)

        function [result] = calculate(obj, beatsPerformance, pemsPerformance)
            result = norm(sum(beatsPerformance-pemsPerformance,2),1);
            obj.result = result;
        end
        
    end
    
end

