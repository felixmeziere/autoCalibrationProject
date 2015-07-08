classdef TVH < PerformanceCalculator

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
            all_lengths=obj.algorithm_box.beats_simulation.scenario_ptr.get_link_lengths('us');
            good_link_lengths=all_lengths(obj.algorithm_box.good_mainline_mask_beats);
            result = sum(sum(obj.algorithm_box.beats_simulation.density_veh{1,1}(:,obj.algorithm_box.good_mainline_mask_beats),1)./good_link_lengths,2)*dt_hr; %sum over time
            obj.result_from_beats = result;
        end
        
        function [result] = calculate_from_pems(obj)
%             kilometers_per_miles=1.609344;
            dt_hr=1/12;
            result=sum(sum(obj.algorithm_box.pems.data.dty(:,obj.algorithm_box.good_mainline_mask_pems)))*dt_hr;%*kilometers_per_miles; %sum over time and links
            obj.result_from_pems = result;
        end   
        
        function [error,error_in_percentage] = calculate_error(obj)
             error=obj.norm.calculate(obj.result_from_beats,obj.result_from_pems);
             error_in_percentage=sign(error)*100*obj.norm.calculate(error./obj.result_from_pems,0);
             obj.error=error;
             obj.error_in_percentage=error_in_percentage;
             obj.error_history(end+1,1)=error;
             obj.error_in_percentage_history(end+1,1)=error_in_percentage;
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
            legend(['Current error : ',num2str(obj.error_in_percentage),'%']);
            legend BOXOFF
        end  
    end
end

