classdef TVH < PerformanceCalculator
    %TVH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='TVH';
    end
    
    methods (Access = public)

        function [out] = calculate_from_beats(obj, BS, good_sensors_mask)
            tot_veh = BS.compute_performance.tot_veh;
            out=sum(tot_veh);
            obj.result_from_beats=out;
        end
        
        function [obj] = calculate_from_pems(obj, Pems)
            tot_veh = Pems.compute_performance.tot_veh;
            out=sum(tot_veh);
            obj.result_from_pems=out;
        end    
        
    end
end

