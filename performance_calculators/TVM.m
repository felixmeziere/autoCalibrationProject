classdef TVM < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='TVM';
    end
    
    methods (Access = public)
       
        function [] = calculate_from_beats(obj, BS, good_freeway_link_mask)
            tot_flux = BS.compute_performance.tot_flux(good_freeway_link_mask,:);
            out=sum(tot_flux);
            obj.result_from_beats=out;
        end
        
        function [] = calculate_from_pems(obj, pems, mask)
            out=sum(sum(pems.flw(:,mask)));
            obj.result_from_pems=out;
        end    
        
    end
end

