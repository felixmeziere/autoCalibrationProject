classdef TVM < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        name='TVM';
    end
    
    methods (Access = public)
       
        function [] = calculate_from_beats(obj, beats_simulation, good_freeway_link_mask)
            total_flow_in_each_link = sum(cell2mat(beats_simulation.outflow_veh),1); %sum over time
            obj.result_from_beats = sum(total_flow_in_each_link(1,good_freeway_link_mask)); %sum over links with working sensors
        end
        
        function [] = calculate_from_pems(obj, pems, mask)
            out=sum(sum(pems.flow_measurements(:,mask))); 
            obj.result_from_pems=out;
        end    
        
    end
end

