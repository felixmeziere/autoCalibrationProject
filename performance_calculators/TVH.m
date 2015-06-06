classdef TVH < PerformanceCalculator
    %TVH Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        name='TVH';
        
    end
    
    methods (Access = public)

        function [obj] = TVH(algoBox)
            if (nargin~=1)
                error('You must enter an AlgorithmBox as argument of a performance calculator constructor.');
            elseif (algoBox.beats_loaded==1 && algoBox.pems.is_loaded==1)
            obj.algorithm_box=algoBox;
            else error('Beats simulation and PeMS data must be loaded first.')
            end
        end
        
        function [result] = calculate_from_beats(obj)
            dt_hr=obj.algorithm_box.beats_simulation.out_dt/3600;
            result = sum(obj.algorithm_box.beats_simulation.compute_performance(obj.algorithm_box.good_mainline_mask_beats).tot_veh)*dt_hr; %sum over time
            obj.result_from_beats = result;
            if (obj.result_from_pems~=0) && (obj.result_from_beats~=0)
                obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
                obj.error_in_percentage_history=[obj.error_in_percentage_history;obj.error_in_percentage];
            end
        end
        
        function [result] = calculate_from_pems(obj)
%             result =sum(sum(obj.algorithm_box.pems.data.occ(:,obj.algorithm_box.good_mainline_mask_pems))); %sum over time and links
%             obj.result_from_pems = result;
              dt_hr=obj.algorithm_box.beats_simulation.out_dt/3600;
              result = sum(obj.algorithm_box.normal_mode_bs.compute_performance(obj.algorithm_box.good_mainline_mask_beats).tot_veh)*dt_hr; %sum over time
              obj.result_from_pems = result;
              if (obj.result_from_pems~=0) && (obj.result_from_beats~=0)
                obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
              end
        end   
        
        function [h] = plot(obj,figureNumber)
            if (nargin<2)
                h=figure;
            else
                h=figure(figureNumber);
            end
            plot(obj.error_in_percentage_history);
%             p=[450,0,450,350];
%             set(h, 'Position', p);
            title('TVH error evolution (in percentage)');
            ylabel('TVH error in percentage');
            xlabel('Number of BEATS evaluations');            
        end  
    end
end

