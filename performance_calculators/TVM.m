classdef TVM < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='TVM';
    end
    
    methods (Access = public)
       
        function [out] = calculate_from_beats(obj, BS)
            tot_flux = BS.compute_performance.tot_flux;
            out=sum(tot_flux);
            obj.result_from_beats=out;
        end
        
        function [out] = calculate_from_pems(obj, pems)
            tot_flux = pems.compute_performance.tot_flux;
            out=sum(tot_flux);
            obj.result_from_pems=out;
        end    
        
    end
end

