classdef TVMpH < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        name='TVMpH';
        
    end
    
    methods (Access = public)
       
        function [result] = calculate_from_beats(obj, algoBox)
            result = sum(algoBox.beats_simulation.compute_performance(algoBox.good_mainline_mask_beats).tot_flux)*0.0001893935; %sum over time
            obj.result_from_beats = result;
        end
        
%         function [result] = calculate_from_pems(obj, algoBox) %assumes units aree in SI
%             good_lengths=algoBox.get_link_lengths_miles_pems(algoBox.good_mainline_mask_pems, algoBox.good_mainline_mask_beats);
%             result =sum(sum(algoBox.pems.data.flw(:,algoBox.good_mainline_mask_pems).*repmat(good_lengths,size(algoBox.pems.data.flw,1),1),2))/(algoBox.beats_parameters.DURATION/3600); %sum over time and links
%             obj.result_from_pems= result;
%         end    
        
        function [result] = calculate_from_pems(obj, algoBox)
            result = sum(algoBox.pems.bs.compute_performance(algoBox.good_mainline_mask_beats).tot_flux)*0.0001893935; %sum over time
            obj.result_from_pems = result;
        end
        
    end
end

