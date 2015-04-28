classdef DailyExitFlow < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        name='Daily exit flow';
        
    end
    
    methods (Access = public)
       
        function [result] = calculate_from_beats(obj, algoBox)
            result=sum(algoBox.beats_simulation.outflow_veh{1,1}(:,logical(algoBox.mainline_mask_beats.*algoBox.sink_mask_beats)),1); %sum over time
            obj.result_from_beats = result;
        end
        
        function [result] = calculate_from_pems(obj, pems, mask_pems, link_length_miles)
            result =sum(sum(pems.data.flw(:,mask_pems))); %sum over time and links
            obj.result_from_pems= result;
        end    
        
    end
end

