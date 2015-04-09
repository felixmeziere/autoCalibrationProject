classdef congestion < performanceCalculator
    %Congestion Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        result_from_beats
        result_from_pems
    end
    
    methods (Access = public)
        
        function [out] = calculate_from_beats(obj, BS)
            
        end
        
        function [obj] = calculate_from_pems(obj, Pems)
        end    
        
    end
end

