classdef DailyEntranceFlow < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        name='Daily entrance flow';
        
    end
    
    methods (Access = public)
       
        function [result] = calculate_from_beats(obj, algoBox)
        % return total vehicles that went by over the day
            result=sum(algoBox.beats_simulation.inflow_veh{1,1}(:,logical(algoBox.mainline_mask_beats.*algoBox.source_mask_beats)),1); %sum over time
            obj.result_from_beats = result;
        end
        
        function [result] = calculate_from_pems(obj, algoBox)
            result =sum(algoBox.pems.data.flw(:,logical(algoBox.mainline_mask_pems.*algoBox.sink_mask_pems))); %sum over time
            obj.result_from_pems= result;
        end    
        
    end
end