classdef TVM < performanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess=private)
        result_from_beats
        result_from_pems
    end
    
    methods (Access = public)
       
        function [out] = calculate_from_beats(obj, BS)
            tot_flux = BS.compute_performance.tot_flux;
            out=sum(tot_flux);
            obj.result_from_beats=out;
        end
        
        function [obj] = calculate_from_pems(obj, Pems)
            tot_flux = Pems.compute_performance.tot_flux;
            out=sum(tot_flux);
            obj.result_from_pems=out;
        end    
        
    end
end

