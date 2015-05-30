classdef TVH < PerformanceCalculator
    %TVH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = protected)
        
        name='TVH';
        
    end
    
    methods (Access = public)

        function [result] = calculate_from_beats(obj, algoBox)
            dt_hr=algoBox.beats_parameters.OUTPUT_DT/3600;
            result = sum(algoBox.beats_simulation.compute_performance(algoBox.good_mainline_mask_beats).tot_veh)*dt_hr; %sum over time
            obj.result_from_beats = result;
            if (obj.result_from_pems~=[] && obj.result_from_beats~=[])
                obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
            end
        end
        
        function [result] = calculate_from_pems(obj, algoBox)
%             result =sum(sum(algoBox.pems.data.occ(:,algoBox.good_mainline_mask_pems))); %sum over time and links
%             obj.result_from_pems = result;
              dt_hr=algoBox.beats_parameters.OUTPUT_DT/3600;
              result = sum(algoBox.beats_simulation.compute_performance(algoBox.good_mainline_mask_beats).tot_veh)*dt_hr; %sum over time
              obj.result_from_pems = result;
              if (obj.result_from_pems~=[] && obj.result_from_beats~=[])
                obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
              end
        end    
        
    end
end

