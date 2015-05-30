classdef TVM < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        
        name='TVM';
        
    end
    
    methods (Access = public)
       
        function [result] = calculate_from_beats(obj, algoBox) %compute TVM on beats output on monitored mainline links. units in SI.
            dt_hr=algoBox.beats_parameters.OUTPUT_DT/3600;
            result = sum(algoBox.beats_simulation.compute_performance(algoBox.good_mainline_mask_beats).tot_flux)*dt_hr; %sum over time
            obj.result_from_beats = result;
            if (obj.result_from_pems~=[] && obj.result_from_beats~=[])
                obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
            end
        end
        
        function [result] = calculate_from_pems(obj, algoBox) %compute TVM on pems data on monitored mainline links
%             meters_per_mile = 1609.34;
%             all_lengths=algoBox.beats_simulation.scenario_ptr.get_link_lengths('si')/meters_per_mile;
%             good_lengths=zeros(1,sum(algoBox.good_mainline_mask_pems));    
%             link_ids_pems=unique(algoBox.link_ids_pems);
%             i=1;
%             for k=1:size(link_ids_pems,2)
%                 link_mask=ismember(algoBox.link_ids_beats,link_ids_pems(1,k));
%                 if sum(link_mask.*algoBox.good_mainline_mask_beats)==1
%                     good_lengths(1,i)=all_lengths(1,link_mask);
%                     i=i+1;
%                 end
%             end
%             result =sum(sum(algoBox.pems.data.flw(:,algoBox.good_mainline_mask_pems).*repmat(good_lengths,size(algoBox.pems.data.flw,1),1),2)); %sum over time and links
%             obj.result_from_pems=result;

              dt_hr=algoBox.beats_parameters.OUTPUT_DT/3600;
              result = sum(algoBox.beats_simulation.compute_performance(algoBox.good_mainline_mask_beats).tot_flux)*dt_hr; %sum over time
              obj.result_from_pems = result;
              if (obj.result_from_pems~=[] && obj.result_from_beats~=[])
                obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
              end
        end    
        
    end
end

