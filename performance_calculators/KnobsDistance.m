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
                result=result;
                obj.result_from_beats=result;
            end    
        end    
            
        function [result] = calculate_from_pems(obj) 
            if (obj.algorithm_box.knobs.isnaive_boundaries)
                result=0;
                obj.result_from_beats=0;
                obj.result_from_pems=result;
                obj.error_in_percentage=0;
                obj.error_in_percentage_history=[obj.error_in_percentage_history;0];
                warning('Knob boundaries are naively set so KnobsDistance is irrelevant.');
            else  
                result=obj.algorithm_box.knobs.perfect_values;  
                obj.result_from_pems=result;
            end 
        end
        
        function [error, error_in_percentage] = calculate_error(obj)
            knobs=obj.algorithm_box.knobs;
            number_knob_groups=size(knobs.knob_groups,2);
            knob_group_error_vector=zeros(number_knob_groups,1);
            for i=1:number_knob_groups
                indices=knobs.knob_group_indices{i};
                knob_group_flow=knobs.constraint_equations_coeffs{i}*obj.result_from_beats(indices);
                knob_group_error_vector(i,1)=knob_group_flow-knobs.knob_group_flow_differences(i);
            end    
            error=obj.norm.calculate(knob_group_error_vector,0);
            error_in_percentage=obj.norm.calculate(100*knob_group_error_vector./transpose(knobs.knob_group_flow_differences),0)/number_knob_groups;
            obj.error=error;
            obj.error_in_percentage=error_in_percentage;
            obj.error_history(end+1,1)=error;
            obj.error_in_percentage_history=[obj.error_in_percentage_history;error_in_percentage];
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
            legend(['Current error : ',num2str(obj.error_in_percentage),'%']);
            legend BOXOFF
        end  
    end
    
end

