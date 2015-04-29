classdef Congestion < PerformanceCalculator
    %Congestion Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        name='Congestion';
    end
    
    methods (Access = public)
        
        function [result] = calculate_from_beats(obj,algoBox)
            
        end
        
        function [result] = calculate_from_pems(obj, pems, mask)
        end    
        
    end
end

