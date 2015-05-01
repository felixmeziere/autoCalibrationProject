classdef TVM < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        name='TVM';
        
    end
    
    methods (Access = public)
       
        function [result] = calculate_from_beats(obj, algoBox)
            result = sum(algoBox.beats_simulation.compute_performance(algoBox.good_mainline_mask_beats).tot_flux)*0.0001893935; %sum over time
            obj.result_from_beats = result;
        end
        
        function [result] = calculate_from_pems(obj, algoBox)
            all_lengths=algoBox.beats_simulation.scenario_ptr.get_link_lengths('us')*0.0001893935;
            good_lengths=zeros(1,sum(algoBox.good_mainline_mask_pems));
            for k=1:size(good_lengths,2)
                link_mask=ismember(algoBox.link_ids_beats,algoBox.link_ids_pems(1,k));
                is_mainline_mask=algoBox.good_mainline_mask_beats;
                if ~isempty(find(link_mask.*is_mainline_mask))
                    good_lengths(1,k)=all_lengths(1,logical(link_mask.*is_mainline_mask));
                end    
            end
            result =sum(sum(algoBox.pems.data.flw(:,algoBox.good_mainline_mask_pems).*repmat(good_lengths,size(algoBox.pems.data.flw,1),1),2)); %sum over time and links
            obj.result_from_pems= result;
        end    
        
    end
end

