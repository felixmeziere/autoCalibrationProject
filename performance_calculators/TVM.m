classdef TVM < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='TVM';
    end
    
    methods (Access = public)
       
        function [] = calculate_from_beats(obj, beats_simulation, good_freeway_link_mask)
            obj.result_from_beats= sum(beats_simulation.compute_performance(good_freeway_link_mask).tot_flux); %sum over time
        end
        
        function [] = calculate_from_pems(obj, pems, mask_pems, link_length_miles)
            obj.result_from_pems=sum(sum(pems.data.flw(:,mask_pems).*repmat(link_length_miles,size(pems.data.flw,1),1),2)); 
        end    
        
    end
end

