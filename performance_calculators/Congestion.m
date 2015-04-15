classdef Congestion < PerformanceCalculator
    %Congestion Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        name='Congestion';
    end
    
    methods (Access = public)
        
        function [out] = calculate_from_beats(obj, BS)
            
        end
        
        function [obj] = calculate_from_pems(obj, Pems)
        end    
        
    end
end

