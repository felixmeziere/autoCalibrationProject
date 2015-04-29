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
        
        function [result] = calculate_from_pems(obj, pems, mask_pems, link_length_miles)
            result =sum(sum(pems.data.occ(:,mask_pems).*repmat(link_length_miles,size(pems.data.flw,1),1),2)); %sum over time and links
            obj.result_from_pems = result;
        end    
        
    end
end

