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
        
        function [result] = calculate_from_beats(obj) %compute TVM on beats output on monitored mainline links. units in SI.
            dt_hr=obj.algorithm_box.beats_simulation.out_dt/3600;
            result = sum(obj.algorithm_box.beats_simulation.compute_performance(obj.algorithm_box.good_mainline_mask_beats).tot_flux)*dt_hr; %sum over time
            obj.result_from_beats = result;
            if (obj.result_from_pems~=0) && (obj.result_from_beats~=0)
                obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
                obj.error_in_percentage_history=[obj.error_in_percentage_history;obj.error_in_percentage];
            end
        end
        
        function [result] = calculate_from_pems(obj) %compute TVM on pems data on monitored mainline links
            all_lengths=obj.algorithm_box.beats_simulation.scenario_ptr.get_link_lengths('us');
            link_ids=unique(obj.algorithm_box.pems.link_ids,'stable');
            count=1;
            for k=1:size(link_ids,2)
                link_mask=ismember(obj.algorithm_box.link_ids_beats,link_ids(1,k));
                if any(link_mask.*obj.algorithm_box.good_mainline_mask_beats)
                    good_lengths(1,count)=all_lengths(link_mask);
                    count=count+1;
                end
            end
            result=sum(sum(obj.algorithm_box.pems.data.flw_in_veh(:,obj.algorithm_box.good_mainline_mask_pems,obj.algorithm_box.current_day).*repmat(good_lengths,size(obj.algorithm_box.pems.data.flw,1),1),2)); %sum over time and links
            obj.result_from_pems=result;
        end    
        
        function [h] = plot(obj,figureNumber)
%             if (nargin<2)
%                 h=figure;
%             else
%                 h=figure(figureNumber);
%             end
%             plot(obj.error_in_percentage_history);
% %             p=[900,0,450,350];
% %             set(h, 'Position', p);
%             title('TVM error evolution (in percentage)');
%             ylabel('TVM error in percentage');
%             xlabel('Number of BEATS evaluations');            
        end    
    end
end

