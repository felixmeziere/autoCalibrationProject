classdef TVH < PerformanceCalculator
    %TVH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        name='TVH';
        
    end
    
    methods (Access = public)

        function [result] = calculate_from_beats(obj, algoBox)
            result = sum(algoBox.beats_simulation.compute_performance(algoBox.good_mainline_mask_beats).tot_veh); %sum over time
            obj.result_from_beats = result; 
        end
        
%         function [result] = calculate_from_pems(obj, algoBox)
%             result =sum(sum(algoBox.pems.data.occ(:,algoBox.good_mainline_mask_pems))); %sum over time and links
%             obj.result_from_pems = result;
%         end    

        function [result] = calculate_from_pems(obj, algoBox)
            result = sum(algoBox.pems.bs.compute_performance(algoBox.good_mainline_mask_beats).tot_veh); %sum over time
            obj.result_from_pems = result; 
        end
        
    end
end

