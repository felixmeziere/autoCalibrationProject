classdef L2 < ErrorCalculator
    %UNTITLED21 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='L2';
    end
    
    methods (Access = public)
        
        function [obj] = L1error(beatsPerformance, pemsPerformance)
            obj.calculate(beatsPerformance, pemsPerformance)
        end    
        function [result] = calculate(obj, beatsPerformance, pemsPerformance)
            result = norm(beatsPerformance-pemsPerformance,2);
            obj.result = result;
        end    
    end
end

