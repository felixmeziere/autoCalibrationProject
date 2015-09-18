classdef Knobs < handle
    
   %Required for loading from xls :
    
    %    -> knobs.link_ids | [link_id#1;link_id#2;...;link_id#n]
    %    -> knobs.force_manual_knob_boundaries | [0] or [1] DEFAULT:0
    %    -> knobs.isnaive_boundaries | [0] or [1] DEFAULT:0
    %    -> pems.monitored_source_sink_uncertainty | [fraction of one]
    %       e.g.:0.02 for 2%. DEFAULT:0 NOT REQUIRED IF is_uncertainty_for_monitored_ramps==0
    
    %    -> knobs.boundaries_min | [kb#1;...;kb#n] NOT REQUIRED IF force_manual_knob_boundaries==0. 
    %    -> knobs.boundaries_max | [kb#1;...;kb#n] NOT REQUIRED IF force_manual_knob_boundaries==0. 

    
    properties (SetAccess = ?AlgorithmBox)
        
        %generalities
        is_loaded=0; %indicates if the object is ready.
        
        
        %PROPERTIES FOR UNMONITORED RAMPS
        %selecting.........................................................
        link_ids=0; % The unmonitored ramp link ids in Beats scenario order. (nx1) vector.
        linear_link_ids % same in linear order
        demand_ids %corresponding demand ids in obj.link_ids order.
        
        %boundaries........................................................ 
        boundaries_min %(nx1) vector of minimums for the algorithm (in obj.link_ids order)
        boundaries_max %(nx1) vector of maximums for the algorithm
        naive_boundaries_min %(nx1) vector of naive minimums for the algorithm (in obj.link_ids order). If not changed manually, they are zero.
        naive_boundaries_max %(nx1) vector of naive maximums for the algorithm (in obj.link_ids order). If not changed manually, they are [link's FD max capacity*number of lanes]/[max value of the link's demand template]

        %values............................................................
        current_value=[]; % current value of the knobs (to know what the beats output corresponds to).
        knobs_history=[]; % column log consecutive values of the knobs during last run. Each knob is a column (same order as obj.link_ids).
        knobs_genmean_history=nan; % consecutive values of the knobs during last run in "mean of each generation" format.
        zeroten_knobs_history=[]; %same as before with a unique 0-10 scale for all knobs
        zeroten_knobs_genmean_history=nan; %same as before with a unique 0-10 scale for all knobs
        perfect_values %for the knobs in a single-knob group, value prescribed by the nearby PeMS mainline sensors.

        
        
        
        %PROPERTIES FOR MONITORED RAMPS IF UNCERTAINTY.....................
        %monitored ramps uncertainty handling..............................
        monitored_ramp_link_ids=[]; %properties are same as above
        monitored_ramp_knob_boundaries_min=nan;        
        monitored_ramp_knob_boundaries_max=nan;
        monitored_ramp_knobs_history
        monitored_ramp_zeroten_knobs_history
        monitored_ramp_knobs_genmean_history=nan;
        monitored_ramp_zeroten_knobs_genmean_history=nan;
         
    end
    
    properties (Hidden, SetAccess = ?AlgorithmBox)
        
        algorithm_box@AlgorithmBox

        %selecting.........................................................
        knob_sensor_map %mask in beats scenario format : -1
        knob_groups %(1xp) cell array. Each cell is a knob group and therefore contains a (dx1) vector of link ids pointing at the links of the knob group.
        knob_group_indices %same as before with corresponding indices in obj.link_ids instead of link ids.
        knob_groups_to_project %indices of multiple-knob groups in obj.knob_groups.
        knob_group_to_project_indices %obj.knob_group_indices(obj.knob_groups_to_project).
        nKnobs=0; %number of knobs (=length(obj.link_ids))

        
        %boundaries........................................................
        force_manual_knob_boundaries=0; % 1 if knob boundaries are set manually, 0 if they are set to [link's FD max capacity*number of lanes]/[max value of the link's demand template].
        isnaive_boundaries=0; %1 if use naive boundaries as boundaries for the algorithm

        %values............................................................
        knob_group_flow_differences %flow that should be brought by the knobs of each knob group to match the flow prescribed by PeMS nearby mainline sensors.
        constraint_equations_coeffs %constraint equation coefficients of each knob group (for projection).
        current_preGroupProjection_value=[]; %value of the knobs before multiple-knob group projection.
        current_preTVMProjection_value=[]; %value of the knobs after multiple-knob group projection and before TVM projection.
        sum_of_templates %sum of the templates of the knob links in obj.link_ids order
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Constructing                                                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        function [obj] = Knobs(algoBox) %constructor that connects the object with AlgorithmBox.
            obj.algorithm_box=algoBox;
        end    
        
        function [] = run_assistant(obj) % set the ids of the knobs to tune and their boundaries in the command window.
            if (obj.algorithm_box.beats_loaded==1 && obj.algorithm_box.pems.is_loaded==1)
                obj.is_loaded=0;
                obj.link_ids=[];
                demand2link=obj.algorithm_box.beats_simulation.scenario_ptr.get_demandprofile_link_map;
                bad_sources=obj.algorithm_box.link_ids_beats(1,logical(~obj.algorithm_box.good_source_mask_beats.*obj.algorithm_box.source_mask_beats));
                bad_sources=demand2link(ismember(demand2link(:,2),bad_sources),:);
                bad_sinks=obj.algorithm_box.link_ids_beats(1,logical(~obj.algorithm_box.good_sink_mask_beats.*obj.algorithm_box.sink_mask_beats));
                bad_sinks=demand2link(ismember(demand2link(:,2), bad_sinks),:);
                obj.algorithm_box.is_uncertainty_for_monitored_ramps=-1;
                while obj.algorithm_box.is_uncertainty_for_monitored_ramps~=0 && obj.algorithm_box.is_uncertainty_for_monitored_ramps~=1
                    obj.algorithm_box.is_uncertainty_for_monitored_ramps=input(['Would you like to consider uncertainty on monitored sources and sinks ? (yes=1, no=0): ']);
                end    
                if obj.algorithm_box.is_uncertainty_for_monitored_ramps
                    obj.algorithm_box.monitored_source_sink_uncertainty=input(['Enter PeMS data uncertainty for monitored sources and sinks (e.g. 0.05): ']);
                end    
                numberOfKnobs=size(bad_sources,1)+size(bad_sinks,1);
                numberMissingKnobs=numberOfKnobs+1;
                while numberMissingKnobs>numberOfKnobs
                    numberMissingKnobs = input(strcat(['Among the ', num2str(numberOfKnobs), ' sources and sinks without sensors, how many knobs have to be tuned ? :']));
                end    
                disp(['List of sources (on-ramps or interconnects) without working sensor demand ids and corresponding link ids : ']);
                disp(' ');
                disp(['Demand Id :','     ', 'Link Id :']);
                disp(' ');
                disp(bad_sources);
                disp(' ');
                disp(['List of sinks (off-ramps or interconnects) without working sensor demand ids and corresponding link ids : ']);
                disp(' ');
                disp(['Demand Id :','     ', 'Link Id :']);                                
                disp(' ');
                disp(bad_sinks);
                disp('Link Id (again, for copy-paste) :');
                disp(' ');
                disp([bad_sources(:,2); bad_sinks(:,2)]);
                disp('You can directly select and copy-paste several at a time from the second list which contains only the link ids.');
                for i=1:numberMissingKnobs
                    obj.link_ids(i,1)=input(strcat(['knob ', num2str(i),' link id :']));
                end
                obj.set_demand_ids;
                obj.ask_for_knob_boundaries;
                obj.is_loaded=1;
            else
                error('Beats simulation and PeMS data must be loaded first in AlgorithmBox.');
            end    
        end

        function [] = ask_for_knob_boundaries(obj) % set the knob boundaries in the command window.
            if (obj.link_ids~=0)
                mode='';
                while (~strcmp(mode,'auto') && ~strcmp(mode,'manual'))
                    mode=input('How should the knob boundaries be set ? (auto/manual)','s');
                end    
                if (strcmp(mode,'auto'))
                    obj.isnaive_boundaries=2;
                    while (obj.isnaive_boundaries~=0 && obj.isnaive_boundaries~=1)
                        obj.isnaive_boundaries=input(['Should the knobs be naively set (i.e. leading to potentially absurd daily flows) ? yes =1, no=0 : ']);
                    end
                    if ~obj.isnaive_boundaries
                        obj.algorithm_box.additive_uncertainty=input(['What is the local uncertainty on mainline sensors ? (Additive uncertainty, will set a minimum width for the boundaries): ']);
                    end    
                    obj.set_auto_knob_boundaries(obj.isnaive_boundaries,1);
                elseif (strcmp(mode,'manual'))     
                    obj.boundaries_max=[];
                    obj.boundaries_min=[];
                    for i=1:obj.nKnobs
                        obj.boundaries_min(i,1)=input(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' minimum : ']);
                        obj.boundaries_max(i,1)=input(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' maximum : ']);
                    end
                else     
                end
            else
                error('The knobs to tune ids : obj.link_ids has to be set first.');
            end
            obj.is_loaded=1;
            obj.algorithm_box.ask_for_starting_point;
        end    

   
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Plot functions (to refactor, some have bugs)                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public) %names of the methods are explicit
    
        function [] = plot_zeroten_knobs_history(obj,figureNumber, evaluation_number, with_legend)
            n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end    
            obj.plot_knobs(figureNumber,evaluation_number, obj.zeroten_knobs_history, '[0-10] knobs evolution','[0-10] knobs values', with_legend);
        end 
        
        function [] = plot_zeroten_knobs_genmean_history(obj,figureNumber, evaluation_number, with_legend)
            n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end       
            obj.plot_knobs(figureNumber,evaluation_number, obj.zeroten_knobs_genmean_history, '[0-10] knobs generation mean evolution','[0-10] knobs values', with_legend);
        end 
        
        function [] = plot_knobs_history(obj,figureNumber, evaluation_number, with_legend)
            n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end       
            obj.plot_knobs(figureNumber,evaluation_number, obj.knobs_history, 'knobs evolution','knobs values', with_legend);
        end 
        
        function [] = plot_knobs_genmean_history(obj,figureNumber, evaluation_number, with_legend)
            n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end       
            obj.plot_knobs(figureNumber,evaluation_number, obj.zeroten_knobs_genmean_history, 'knobs generation mean evolution','knobs values', with_legend);
        end 
        
        function [] = plot_knob_history(obj,knob_link_id,figureNumber)
            if (nargin<3)
                h=figure;
            else
                h=figure(figureNumber);
            end
            index=find(obj.link_ids==knob_link_id);
            if size(index,1)==0
                index=find(obj.monitored_ramp_link_ids==knob_link_id);
            end    
            plot(obj.knobs_history(:,index));
            number=num2str(find(obj.linear_link_ids==knob_link_id));
            title(['Knob ',number,' (',num2str(knob_link_id),') evolution']);
            xlabel('Number of BEATS evaluations');
            ylabel('Knob values');  
        end  
        
        function [] = plot_monitored_ramp_zeroten_knobs_history(obj,figureNumber, evaluation_number, with_legend)
            n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end       
            obj.plot_knobs(figureNumber,evaluation_number, obj.monitored_ramp_zeroten_knobs_history, '[0-10] knobs evolution','[0-10] knobs values', with_legend);      
        end 

        function [] = plot_monitored_ramp_knobs_history(obj,figureNumber, evaluation_number, with_legend)
           n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end       
            obj.plot_knobs(figureNumber,evaluation_number, obj.monitored_ramp_knobs_history, '[0-10] knobs evolution','[0-10] knobs values', with_legend);             
        end 
        
        function [] = plot_monitored_ramp_knobs_genmean_history(obj,figureNumber, evaluation_number, with_legend)
            n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end       
            obj.plot_knobs(figureNumber,evaluation_number, obj.monitored_ramp_knobs_genmean_history, '[0-10] knobs evolution','[0-10] knobs values', with_legend);           
        end 
        
        function [] = plot_monitored_ramp_zeroten_knobs_genmean_history(obj,figureNumber, evaluation_number, with_legend)
           n=nargin;
            if n<2
                figureNumber=0;
            end    
            if n<3
                evaluation_number=0;
            end    
            if n<4
                with_legend=0;
            end       
            obj.plot_knobs(figureNumber,evaluation_number, obj.monitored_ramp_zeroten_knobs_genmean_history, '[0-10] knobs evolution','[0-10] knobs values', with_legend);            
        end 

                
    end    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Privates                                                           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = ?AlgorithmBox) %supposed to be private but public for debug reasons
        
        function [] = set_auto_knob_boundaries(obj, isnaive, is_assistant) %sets the knob boundaries, knob groups, perfect values etc.
            if (nargin<3)
                is_assistant=0;
            end
            for i=1:obj.nKnobs    
                maxTemplateValue=max(obj.algorithm_box.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(obj.link_ids(i)).demand);       
                lanes=obj.algorithm_box.beats_simulation.scenario_ptr.get_link_byID(obj.link_ids(i)).ATTRIBUTE.lanes;
                FDcapacity=obj.algorithm_box.beats_simulation.scenario_ptr.get_fds_with_linkIDs(obj.link_ids(i)).capacity*lanes;
                obj.boundaries_min(i,1)=0;
                obj.boundaries_max(i,1)=FDcapacity/maxTemplateValue;
            end
            if (nargin<2 || isnaive~=1)
                obj.naive_boundaries_min=obj.boundaries_min;
                obj.naive_boundaries_max=obj.boundaries_max;
                obj.set_knob_groups;
                obj.set_knob_group_flow_differences;
                obj.set_auto_knob_boundaries_refined(is_assistant);
                disp('Refined knob boundaries set automatically :');
            else
                disp('Naive knob boundaries set automatically :');
            end
            if (size(obj.algorithm_box.error_function,1)~=0)
                obj.algorithm_box.error_function.calculate_pc_from_pems;
            end    
            for i=1:size(obj.link_ids)
                disp(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' minimum : ',num2str(obj.boundaries_min(i,1))]);
                disp(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' maximum : ',num2str(obj.boundaries_max(i,1))]);
            end
            if obj.algorithm_box.is_uncertainty_for_monitored_ramps
                obj.monitored_ramp_knob_boundaries_min(1:size(obj.monitored_ramp_link_ids,1),1)=1-obj.algorithm_box.monitored_source_sink_uncertainty;        
                obj.monitored_ramp_knob_boundaries_max(1:size(obj.monitored_ramp_link_ids,1),1)=1+obj.algorithm_box.monitored_source_sink_uncertainty;
                disp('UNCERTAINTY FOR MONITORED RAMPS TAKEN INTO ACCOUNT.');
            end    
        end

        %utilities.........................................................
        function []=set_demand_ids(obj) % sets obj.demand_profile_ids, obj.sum_of_templates and obj.linear_link_ids.
            obj.demand_ids=[];
            obj.nKnobs=size(obj.link_ids,1);
            for i=1:obj.nKnobs
                dps=obj.algorithm_box.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(obj.link_ids);
                obj.demand_ids(i,1)=dps(i).id;
                obj.sum_of_templates(i,1)=obj.algorithm_box.get_sum_of_template_in_veh(obj.link_ids(i,1));
            end
            obj.linear_link_ids=obj.algorithm_box.linear_link_ids(ismember(obj.algorithm_box.linear_link_ids,obj.link_ids));
        end
        
        %functions to refine the auto boundaries to realistic ones, taking 
        %local monitored flows for each knob into account..................
        
        function [] = set_knob_groups(obj) 
            knob_sensor_map=zeros(size(obj.algorithm_box.linear_link_ids));
            knob_sensor_map(ismember(obj.algorithm_box.linear_link_ids,obj.algorithm_box.link_ids_beats(logical(obj.algorithm_box.good_source_mask_beats+obj.algorithm_box.good_sink_mask_beats))))=0.5;
            knob_sensor_map(ismember(obj.algorithm_box.linear_link_ids,obj.algorithm_box.link_ids_beats(obj.algorithm_box.good_mainline_mask_beats)))=1;
            knob_sensor_map(ismember(obj.algorithm_box.linear_link_ids,obj.link_ids))=-1;
            obj.knob_sensor_map=knob_sensor_map;
            last_monitored_is_mainline=1;
            index=1;
            subindex=1;
            knob_groups=cell(1,obj.nKnobs);
            for i=1:size(knob_sensor_map,2)
                if knob_sensor_map(i)==1
                    if last_monitored_is_mainline==0
                        index=index+1;
                        subindex=1;
                        last_monitored_is_mainline=1;
                    end    
                elseif knob_sensor_map(i)==-1
                    last_monitored_is_mainline=0;
                    array=cell2mat(knob_groups{1,index});
                    array(subindex,1)=obj.algorithm_box.linear_link_ids(i);
                    knob_groups{1,index}=num2cell(array);
                    subindex=subindex+1;
                end                    
            end
            obj.knob_groups=knob_groups(1,1:index-1);
            for i=1:size(knob_groups,2)
                for j=1:size(knob_groups{i},1)
                    obj.knob_group_indices{1,i}(j,1)=find(obj.link_ids==cell2mat(obj.knob_groups{i}(j,1)));
                end
            end    
        end %sets the knob groups in obj.knob_groups 
        
        function [monitored_closer_mainline_source,monitored_closer_mainline_sink]= get_monitored_segment_for_knob_group(obj, knob_group) %knob_group:column of link ids which are in the same knob group (e.g. : obj.knob_groups{2}). Get the two closest monitored mainline link ids : one just before the first knob ramp and one just after the last knob ramp.
            first_knob_index=find(obj.algorithm_box.linear_link_ids==knob_group{1,1});
            last_knob_index=find(obj.algorithm_box.linear_link_ids==knob_group{size(knob_group,1),1});
            is_monitored_mainline_link=0;  
            i=1;
            while (is_monitored_mainline_link==0)
                if (obj.knob_sensor_map(last_knob_index+i)==1)
                    is_monitored_mainline_link=1;
                end    
                monitored_closer_mainline_sink=obj.algorithm_box.linear_link_ids(last_knob_index+i);
                i=i+1;
            end
            is_monitored_mainline_link=0;
            i=-1;
            while(is_monitored_mainline_link==0)
                if (obj.knob_sensor_map(first_knob_index+i)==1)
                    is_monitored_mainline_link=1;
                end    
                monitored_closer_mainline_source=obj.algorithm_box.linear_link_ids(first_knob_index+i);
                i=i-1;
            end    
        end %for a 

        function [local_flow_difference] = get_unmonitored_flow_difference(obj, monitored_source_mainline_link_id, monitored_sink_mainline_link_id)
            source_index=find(obj.algorithm_box.linear_link_ids==monitored_source_mainline_link_id);
            sink_index=find(obj.algorithm_box.linear_link_ids==monitored_sink_mainline_link_id);
            local_segment_link_ids=obj.algorithm_box.linear_link_ids(1,source_index:sink_index);
            all_monitored_onramps=obj.algorithm_box.link_ids_beats(logical(obj.algorithm_box.good_source_mask_beats.*~obj.algorithm_box.mainline_mask_beats));
            all_monitored_offramps=obj.algorithm_box.link_ids_beats(logical(obj.algorithm_box.good_sink_mask_beats.*~obj.algorithm_box.mainline_mask_beats));
            local_monitored_sources(1,1)=monitored_source_mainline_link_id;
            number_local_monitored_sources=sum(ismember(local_segment_link_ids,all_monitored_onramps))+1;
            local_monitored_sources(1,2:number_local_monitored_sources)=local_segment_link_ids(ismember(local_segment_link_ids,all_monitored_onramps));
            local_monitored_sinks=local_segment_link_ids(ismember(local_segment_link_ids,all_monitored_offramps));
            local_monitored_sinks(1,end+1)=monitored_sink_mainline_link_id;
            local_flow_difference=0;
            for i=1:size(local_monitored_sources,2)
                column_mask_in_pems_data=logical(ismember(obj.algorithm_box.pems.link_ids,local_monitored_sources(1,i)).*obj.algorithm_box.good_sensor_mask_pems);
                local_flow_difference=local_flow_difference+sum(obj.algorithm_box.pems.data.flw_in_veh(:,column_mask_in_pems_data,obj.algorithm_box.current_day),1);
            end
            for i=1:size(local_monitored_sinks,2)
                column_mask_in_pems_data=logical(ismember(obj.algorithm_box.pems.link_ids,local_monitored_sinks(1,i)).*obj.algorithm_box.good_sensor_mask_pems);
                local_flow_difference=local_flow_difference-sum(obj.algorithm_box.pems.data.flw_in_veh(:,column_mask_in_pems_data,obj.algorithm_box.current_day),1);
            end   
       end  %get the flow that the knobs between the two input mainline links should bring.
                        
        function [knob_group_flow_differences] = set_knob_group_flow_differences(obj) %set obj.knob_group_flow_differences : the flow requested to each knob group in obj.knob_groups order.
            for i=1:size(obj.knob_groups,2)
                [source,sink]=obj.get_monitored_segment_for_knob_group(obj.knob_groups{1,i});
                knob_group_flow_differences(1,i)=obj.get_unmonitored_flow_difference(source,sink);
            end
            obj.knob_group_flow_differences=knob_group_flow_differences;
        end 
        
       
        function [] = set_auto_knob_boundaries_refined(obj, is_assistant)
            %Messy code because stuff had to be changed and reused long
            %after it was written.
            if (nargin>0 && is_assistant)
                obj.algorithm_box.multiplicative_uncertainty=input(['Enter the multiplicative uncertainty for the flow going through the knob links (e.g. : 0.5) : ']);
            end    
            if  obj.algorithm_box.multiplicative_uncertainty==1
                obj.algorithm_box.multiplicative_uncertainty=0.999999;
                obj.algorithm_box.multiplicative_uncertainty=1.0000001;
            end    
            mu=obj.algorithm_box.multiplicative_uncertainty;
            ref=obj.algorithm_box.pems.average_mainline_flow;
            knob_groups_to_project=[];
            index=1;
            for i=1:size(obj.knob_groups,2)
                for j=1:size(obj.knob_groups{1,i},1)
                    knob_link_id=cell2mat(obj.knob_groups{1,i}(j,1));
                    knob_index=find(obj.link_ids==knob_link_id);
                    sum_of_template=obj.algorithm_box.get_sum_of_template_in_veh(knob_link_id);
                    if ismember(knob_link_id,obj.algorithm_box.link_ids_beats(obj.algorithm_box.source_mask_beats))
                        coeff=-1;
                    else
                        coeff=1;
                    end
                end    
                if (size(obj.knob_groups{1,i},1)==1)
                    knob_perfect_value=coeff*obj.knob_group_flow_differences(i)/sum_of_template;
                    obj.perfect_values(knob_index,1)=knob_perfect_value;
                    incert=obj.algorithm_box.additive_uncertainty;
                    premin=min(knob_perfect_value*(1-mu),knob_perfect_value-ref*incert/sum_of_template);
                    premax=max(knob_perfect_value*(1+mu),knob_perfect_value+ref*incert/sum_of_template);
                    obj.boundaries_min(knob_index,1)=max(obj.naive_boundaries_min(knob_index),premin);
                    obj.boundaries_max(knob_index,1)=min(obj.naive_boundaries_max(knob_index),premax);
                else
                    obj.knob_groups_to_project(index)=i;
                    for j=1:size(obj.knob_groups{1,i},1)
                        obj.knob_group_to_project_indices{index}(j,1)=find(obj.link_ids==cell2mat(obj.knob_groups{1,i}(j,1)));
                    end
                    index=index+1;
                end    
            end
            number_knob_groups_to_project=size(obj.knob_groups_to_project,2);
            number_knob_groups=size(obj.knob_groups,2);
            obj.constraint_equations_coeffs=cell(1,number_knob_groups);
            for i=1:number_knob_groups
                knob_group=cell2mat(obj.knob_groups{1,i});
                constraint_equation_coeffs=[];
                for j=1:size(knob_group)
                    index=find(obj.link_ids==knob_group(j));
                    sum_of_template=obj.algorithm_box.get_sum_of_template_in_veh(obj.link_ids(index));
                    if ismember(obj.link_ids(index),obj.algorithm_box.link_ids_beats(obj.algorithm_box.source_mask_beats))
                        coeff=-1;
                    else
                        coeff=1;
                    end    
                    constraint_equation_coeffs(1,end+1)=coeff*sum_of_template;
                end
                obj.constraint_equations_coeffs{1,i}=constraint_equation_coeffs;
            end  
            obj.monitored_ramp_link_ids=reshape(obj.algorithm_box.link_ids_beats(1,logical(obj.algorithm_box.good_source_mask_beats+obj.algorithm_box.good_sink_mask_beats.*~obj.algorithm_box.mainline_mask_beats)),[],1);     
        end %set refined knob boundaries with tolerance coefficients.
        
        function [knobs_on_correct_subspace]= project_involved_knob_groups_on_correct_flow_subspace(obj, knobs_vector)
            knobs_on_correct_subspace=knobs_vector;
            obj.current_preGroupProjection_value=knobs_vector;
            for i=1:size(obj.knob_groups_to_project,2)
                knob_group=cell2mat(obj.knob_groups{1,obj.knob_groups_to_project(i)});
                indices=obj.knob_group_to_project_indices{1,i};
                subvector=knobs_vector(indices,1);
                constraint_equation_coeffs=obj.constraint_equations_coeffs{obj.knob_groups_to_project(i)};
                flowdiff=obj.knob_group_flow_differences(1,obj.knob_groups_to_project(i));
                mu=obj.algorithm_box.multiplicative_uncertainty;
                si=sign(flowdiff);
                incert=obj.algorithm_box.additive_uncertainty;
                ref=obj.algorithm_box.pems.average_mainline_flow;
%                   [subvector_on_correct_subspace,fval]=quadprog(eye(size(knob_group,1)),-reshape(subvector,1,[]),[si*constraint_equation_coeffs;-si*constraint_equation_coeffs],[si*(1+mu)*flowdiff;-si*(1-mu)*flowdiff],[],[],obj.naive_boundaries_min(obj.knob_group_to_project_indices{1,i},1),obj.naive_boundaries_max(obj.knob_group_to_project_indices{1,i},1)); % minimization program
                [subvector_on_correct_subspace,fval]=quadprog(eye(size(knob_group,1)),-reshape(subvector,1,[]),[si*constraint_equation_coeffs;-si*constraint_equation_coeffs],[max(si*flowdiff+incert*ref,si*(1+mu)*flowdiff);max(-si*flowdiff+incert*ref,-si*(1-mu)*flowdiff)],[],[],obj.naive_boundaries_min(obj.knob_group_to_project_indices{1,i},1),obj.naive_boundaries_max(obj.knob_group_to_project_indices{1,i},1)); % minimization program
                knobs_on_correct_subspace(obj.knob_group_to_project_indices{1,i},1)=subvector_on_correct_subspace;
            end    
        end %Project each multiple-knob group between the two hyperplans such that the flow they provide is the flow asked by PeMS mainline sensors +-obj.over/underevaluation_tolerance_coefficients

        %rescale between real and zero-ten scales .........................
        function [result_matrix] = rescale_knobs(obj, input_matrix, isRealScaleToZeroTenScale) % rescales the knobs from 0:10 to their actual respective range (used by cmaes for 'uniform sensitivity' reasons) or the opposite operation, depending on isRealScaleToZeroTenScale.
            min=repmat(obj.boundaries_min,1,size(input_matrix,2));
            range=repmat(obj.boundaries_max-obj.boundaries_min,1,size(input_matrix,2));
            if obj.algorithm_box.is_uncertainty_for_monitored_ramps
                min=[min;repmat(obj.monitored_ramp_knob_boundaries_min,1,size(input_matrix,2))];
                range=[range;repmat(obj.monitored_ramp_knob_boundaries_max-obj.monitored_ramp_knob_boundaries_min,1,size(input_matrix,2))];
            end    
            if isRealScaleToZeroTenScale==1
                result_matrix=((input_matrix-min)./range)*10;
            elseif isRealScaleToZeroTenScale==0
                result_matrix=((input_matrix/10).*range)+min;
            else error ('The second parameter must be zero or one');
            end        
        end
        
        %set the knobs in beats............................................
        function [] = set_knobs_persistent_deprecated(obj, knobs_vector)         
%             for i= 1:size(obj.link_ids)
%                 if (ismember(obj.link_ids(i),obj.algorithm_box.link_ids_beats(obj.algorithm_box.source_mask_beats)))
%                     obj.algorithm_box.beats_simulation.beats.set.demand_knob_for_link_id(obj.link_ids(i),knobs_vector(i));
%                 else
%                     obj.algorithm_box.beats_simulation.beats.set.knob_for_offramp_link_id(obj.link_ids(i),knobs_vector(i));
%                 end    
%             end
%             obj.current_value=knobs_vector;
        end
        
        function [] = set_knobs_persistent(obj,knobs_vector) %in BeATS, sets the knobs to the value of knobs_vector. Changes obj.current_value, and saves the value for log.
            for i= 1:obj.nKnobs
                obj.algorithm_box.beats_simulation.beats.set.demand_knob_for_link_id(obj.link_ids(i),knobs_vector(i));
            end
            reshaped=reshape(mean(knobs_vector,2),1,[]);
            zeroten_reshaped=reshape(mean(obj.rescale_knobs(knobs_vector,1),2),1,[]);
            obj.knobs_history(end+1,1:obj.nKnobs)=reshaped(1,1:obj.nKnobs);
            obj.zeroten_knobs_history(end+1,1:obj.nKnobs)=zeroten_reshaped(1,1:obj.nKnobs);
            if obj.algorithm_box.is_uncertainty_for_monitored_ramps
                for i= 1:size(obj.monitored_ramp_link_ids)
                    obj.algorithm_box.beats_simulation.beats.set.demand_knob_for_link_id(obj.monitored_ramp_link_ids(i),knobs_vector(i+obj.nKnobs));
                end
                sze=size(obj.monitored_ramp_link_ids,1);
                obj.monitored_ramp_knobs_history(end+1,1:sze)=reshaped(1,obj.nKnobs+1:obj.nKnobs+sze);
                obj.monitored_ramp_zeroten_knobs_history(end+1,1:sze)=zeroten_reshaped(1,obj.nKnobs+1:obj.nKnobs+sze);
            end    
            obj.current_value=knobs_vector;
        end      
        
        function [] = reset_history(obj) %reset the logs for new run
            obj.knobs_history=[];
            obj.knobs_genmean_history=nan;
            obj.zeroten_knobs_history=[];
            obj.monitored_ramp_zeroten_knobs_genmean_history=nan;
            obj.monitored_ramp_knobs_history=[];
            obj.monitored_ramp_zeroten_knobs_history=[];
            obj.monitored_ramp_knobs_genmean_history=nan;
            obj.monitored_ramp_zeroten_knobs_genmean_history=nan;
        end    
                        
        function [] = plot_knobs(obj,figureNumber,evaluation_number,knobs_array_to_plot, figure_title, y_label,with_legend)
            n=nargin;
            if (n<2 || figureNumber==0)
                h=figure;
            else
                h=figure(figureNumber);
            end  
            if n<3 || evaluation_number==0
                evaluation_number=size(knobs_array_to_plot,1);
            end     
%             p=[700,400,800,470];
%             set(h, 'Position', p);
            plot(knobs_array_to_plot(1:evaluation_number,:));
            title(figure_title);
            xlabel('Number of BeATS evaluations');
            ylabel(y_label);
            xlim([0,size(knobs_array_to_plot,1)+1]);
            if (n>6 && with_legend==1) 
                for i=1:obj.nKnobs
                    leg{i}=['Knob ',num2str(find(obj.linear_link_ids==obj.link_ids(i,1))),' (',num2str(obj.link_ids(i,1)),')'];
                end 
                legend(leg);
                legend BOXOFF
            end
        end  
    end
end

