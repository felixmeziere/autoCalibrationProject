classdef KnobsDistance < PerformanceCalculator

    
    properties (Constant)
        
        name='Knobs distance'
        
    end
    
    methods
        
        function [obj] = KnobsDistance(algoBox)
            obj.algorithm_box=algoBox;
        end    
        
        function [result] = calculate_from_beats(obj)
            knobs=obj.algorithm_box.knobs;
            if (knobs.isnaive_boundaries)
                result=0;
                obj.result_from_beats=0;
                obj.result_from_pems=0;
                obj.error_in_percentage=0;
                obj.error_in_percentage_history=[obj.error_in_percentage_history;0];
                warning('Knob boundaries are naively set so KnobsDistance is irrelevant.');
            else    
                result=mean(knobs.current_value,2);
                good_indices_mask=ones(size(result,1),1);
                knob_groups_to_project_error=0;
                for i=1:size(knobs.knob_groups_to_project)
                    indices=knobs.knob_group_indices{i};
                    good_indices_mask(indices,1)=0;
                    number_knobs=size(indices,1);
                    knob_group_flow=knobs.constraint_equations_coeffs{i}*knobs.current_value(indices);
                    diff=knob_group_flow-knobs.knob_group_flow_differences(knobs.knob_groups_to_project(i));
                    result(indices,1)=diff/(number_knobs);
                    result(indices,1)=result(indices,1)./transpose(knobs.constraint_equations_coeffs{i});
                    knob_groups_to_project_error=knob_groups_to_project_error+100*abs(diff)/knobs.knob_group_flow_differences(knobs.knob_groups_to_project(i));
                end    
                good_indices_mask=logical(good_indices_mask);
                result=result*100;
                obj.result_from_beats=result;
                good_diff=obj.result_from_beats(good_indices_mask)-obj.result_from_pems(good_indices_mask);
                obj.error_in_percentage=100*sum((abs(good_diff))./obj.result_from_pems(good_indices_mask));
                obj.error_in_percentage=(obj.error_in_percentage+knob_groups_to_project_error)/size(obj.algorithm_box.knobs.link_ids,1);
                obj.error_in_percentage_history=[obj.error_in_percentage_history;obj.error_in_percentage];
            end    
        end    
            
        function [result] = calculate_from_pems(obj)    
            if (knobs.isnaive_boundaries)
                result=nan;
                obj.result_from_beats=0;
                obj.result_from_pems=result;
                obj.error_in_percentage=0;
                obj.error_in_percentage_history=[obj.error_in_percentage_history;0];
                warning('Knob boundaries are naively set so KnobsDistance is irrelevant.');
            else  
                result=obj.algorithm_box.knobs.perfect_values*100;  
                obj.result_from_pems=result;
            end 
        end
        
        function [h] = plot(obj,figureNumber)
            if (nargin<2)
                h=figure;
            else
                h=figure(figureNumber);
            end
            plot(obj.error_in_percentage_history);
%             p=[900,0,450,350];
%             set(h, 'Position', p);
            title('Knobs distance from perfect value error evolution (average of percentages)');
            ylabel('Knobs distance error in percentage');
            xlabel('Number of BEATS evaluations');            
            
        end  
    end
    
end

