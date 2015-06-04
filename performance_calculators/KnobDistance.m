classdef KnobDistance < PerformanceCalculator

    
    properties
        
        name='Knob distance'
        
    end
    
    methods
        
        function [obj] = KnobDistance(algoBox)
            obj.algorithm_box=algoBox;
        end    
        
        function [result] = calculate_from_beats(obj)
            
        end    
            
        function [result] = calculate_from_pems    
        end
        
        function [] = plot(obj,figureNumber)
        end
    end
    
end

