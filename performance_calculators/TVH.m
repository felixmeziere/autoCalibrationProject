classdef TVH < PerformanceCalculator
    %TVH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='TVH';
    end
    
    methods (Access = public)

        function [] = calculate_from_beats(obj, BS, good_freeway_link_mask)
            tot_veh = BS.compute_performance.tot_veh(good_freeway_link_mask,:);
            out=sum(tot_veh);
            obj.result_from_beats=out;
        end
        
        function [] = calculate_from_pems(obj, pems, mask)
            out=sum(sum(pems.occ(:,mask)));
            obj.result_from_pems=out;
        end    
        
    end
end

