classdef TVM < PerformanceCalculator
    %TVMSim Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        
        name='TVM';
        
    end

    methods (Access = public)
       
        function [obj] = TVM(algoBox)
            if (nargin~=1)
                error('You must enter an AlgorithmBox as argument of a performance calculator constructor.');
            elseif (algoBox.beats_loaded==1 && algoBox.pems.is_loaded==1)
            obj.algorithm_box=algoBox;
            else error('Beats simulation and PeMS data must be loaded first.')
            end
        end
        
        function [result] = calculate_from_beats(obj) %unit in SI
            dt_hr=obj.algorithm_box.beats_simulation.out_dt/3600;
            result = sum(obj.algorithm_box.beats_simulation.compute_performance(obj.algorithm_box.good_mainline_mask_beats).tot_flux)*dt_hr; %sum over time
            obj.result_from_beats = result;
        end
        
        function [result] = calculate_from_pems(obj) 
            all_lengths=obj.algorithm_box.beats_simulation.scenario_ptr.get_link_lengths('us');
            link_ids=unique(obj.algorithm_box.pems.link_ids,'stable');
            count=1;
%             selected_ids_mask=zeros(1,93);
            for k=1:size(link_ids,2)
                link_mask=ismember(obj.algorithm_box.link_ids_beats,link_ids(1,k));
                if any(link_mask.*obj.algorithm_box.good_mainline_mask_beats)
%                 flag=1;
%                 i=1;
%                 while flag
%                     if obj.algorithm_box.pems.link_ids(1,i)==link_ids(1,k)
%                         selected_ids_mask(1,i)=1;
%                         flag=0;
%                     else
%                         i=i+1;
%                     end    
%                 end    
                    good_lengths(1,count)=all_lengths(link_mask);
                    count=count+1;
                end
            end
%             selected_ids_mask=logical(selected_ids_mask);
            result=sum(sum(obj.algorithm_box.pems.data.flw_in_veh(:,obj.algorithm_box.good_mainline_mask_pems,obj.algorithm_box.current_day),1).*good_lengths,2); %sum over time and links
            obj.result_from_pems=result;
        end    
        
        function [error,error_in_percentage] = calculate_error(obj)
             error=obj.norm.calculate(obj.result_from_beats,obj.result_from_pems);
             error_in_percentage=sign(error)*100*obj.norm.calculate(error./obj.result_from_pems,0);
             obj.error=error;
             obj.error_in_percentage=error_in_percentage;
             obj.error_history(end+1,1)=error;
             obj.error_in_percentage_history=[obj.error_in_percentage_history;obj.error_in_percentage];
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
            title('TVM error evolution (in percentage)');
            ylabel('TVM error in percentage');
            xlabel('Number of BEATS evaluations');
            legend(['Current error : ',num2str(obj.error_in_percentage),'%']);
            legend BOXOFF
        end    
        
    end
end

