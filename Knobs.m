classdef Knobs < handle
    
    properties (SetAccess = ?AlgorithmBox)
        
        is_loaded=0;
        algorithm_box@AlgorithmBox;
        
        %selecting.........................................................
        link_ids=0;
        demand_ids
        
        
        %boundaries........................................................ 
        boundaries_min
        boundaries_max
        naive_boundaries_min
        naive_boundaries_max
        underevaluation_tolerance_coefficient=-Inf;
        overevaluation_tolerance_coefficient=-Inf;
        
        %values............................................................
        current_value=[];
        knobs_history % consecutive values of the knobs during last run
        perfect_values
         
    end
    
    properties (Hidden, SetAccess = ?AlgorithmBox)
    
        %selecting.........................................................
        knob_sensor_map
        knob_groups
        knob_groups_to_project
        
        %boundaries........................................................
        force_manual_knob_boundaries=0; % 1 if knob boundaries are set manually, 0 if they are set to [link's FD max capacity*number of lanes]/[max value of the link's demand template].
        isnaive_boundaries=0;

        %values............................................................
        knob_group_flow_differences

    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Constructing                                                       %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        function [obj] = Knobs(algoBox)
            obj.algorithm_box=algoBox;
        end    
        
        function [] = run_assistant(obj) % set the ids of the knobs to tune in the command window.
            if (obj.algorithm_box.beats_loaded==1)
                obj.link_ids=[];
                demand2link=obj.algorithm_box.beats_simulation.scenario_ptr.get_demandprofile_link_map;
                bad_sources=obj.algorithm_box.link_ids_beats(1,logical(~obj.algorithm_box.good_source_mask_beats.*obj.algorithm_box.source_mask_beats));
                bad_sources=demand2link(ismember(demand2link(:,2),bad_sources),:);
                bad_sinks=obj.algorithm_box.link_ids_beats(1,logical(~obj.algorithm_box.good_sink_mask_beats.*obj.algorithm_box.sink_mask_beats));
                bad_sinks=demand2link(ismember(demand2link(:,2), bad_sinks),:);
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
                error('No Beats Simulation loaded.');
            end    
        end

        function [] = ask_for_knob_boundaries(obj) % set the knob boundaries (in the same order as the knob ids) in the command window.
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
                    obj.set_auto_knob_boundaries(obj.isnaive_boundaries);
                elseif (strcmp(mode,'manual'))     
                    obj.boundaries_max=[];
                    obj.boundaries_min=[];
                    for i=1:size(obj.link_ids,1)
                        obj.boundaries_min(i,1)=input(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' minimum : ']);
                        obj.boundaries_max(i,1)=input(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' maximum : ']);
                    end
                else     
                end
            else
                error('The knobs to tune ids : obj.link_ids has to be set first.');
            end    
        end    

        function [] = set_auto_knob_boundaries(obj, isnaive) %sets automatically the knob minimums to zero and maximums to [link's FD max capacity*number of lanes]/[max value of the link's demand template]
            for i=1:size(obj.link_ids)    
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
                obj.set_auto_knob_boundaries_refined;
                disp('Refined knob boundaries set automatically :');
            else
                disp('Naive knob boundaries set automatically :');

            end
            for i=1:size(obj.link_ids)
                disp(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' minimum : ',num2str(obj.boundaries_min(i,1))]);
                disp(['Knob ', num2str(obj.demand_ids(i,1)), ' | ', num2str(obj.link_ids(i,1)), ' maximum : ',num2str(obj.boundaries_max(i,1))]);
            end     
        end
   
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Privates                                                           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = ?AlgorithmBox)
        
        %utilities.........................................................
        function []=set_demand_ids(obj) % set demand profile ids in obj.demand_ids corresponding to obj.link_ids.
            obj.demand_ids=[];
            for i=1:size(obj.link_ids,1)
                dps=obj.algorithm_box.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(obj.link_ids);
                obj.demand_ids(i,1)=dps(i).id;
            end
        end
        
        %functions to refine the auto boundaries to realistic ones, taking 
        %local monitored flows for each knob into account..................
        
        function [] = set_knob_groups(obj) %assumes a mainline link is monitored before the first unknown knob
            knob_sensor_map=zeros(size(obj.algorithm_box.linear_link_ids));
            knob_sensor_map(ismember(obj.algorithm_box.linear_link_ids,obj.algorithm_box.link_ids_beats(obj.algorithm_box.good_mainline_mask_beats)))=1;
            knob_sensor_map(ismember(obj.algorithm_box.linear_link_ids,obj.algorithm_box.link_ids_beats(logical(obj.algorithm_box.good_source_mask_beats+obj.algorithm_box.good_sink_mask_beats))))=0.5;
            knob_sensor_map(ismember(obj.algorithm_box.linear_link_ids,obj.link_ids))=-1;
            obj.knob_sensor_map=knob_sensor_map;
            last_monitored_is_mainline=1;
            index=1;
            subindex=1;
            knob_groups=cell(1,size(obj.link_ids,1));
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
        end
        
        function [monitored_closer_mainline_source,monitored_closer_mainline_sink]= get_monitored_segment_for_knob_group(obj, knob_group) 
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
        end
        
        function [local_flow_difference] = get_unmonitored_flow_difference(obj, monitored_source_mainline_link_id, monitored_sink_mainline_link_id)
            source_index=find(obj.algorithm_box.linear_link_ids==monitored_source_mainline_link_id);
            sink_index=find(obj.algorithm_box.linear_link_ids==monitored_sink_mainline_link_id);
            local_segment_link_ids=obj.algorithm_box.linear_link_ids(1,source_index:sink_index);
            all_monitored_sources=obj.algorithm_box.link_ids_beats(obj.algorithm_box.good_source_mask_beats);
            all_monitored_sinks=obj.algorithm_box.link_ids_beats(obj.algorithm_box.good_sink_mask_beats);
            local_monitored_sources(1,1)=monitored_source_mainline_link_id;
            number_local_monitored_sources=sum(ismember(local_segment_link_ids,all_monitored_sources))+1;
            local_monitored_sources(1,2:number_local_monitored_sources)=local_segment_link_ids(ismember(local_segment_link_ids,all_monitored_sources));
            local_monitored_sinks=local_segment_link_ids(ismember(local_segment_link_ids,all_monitored_sinks));
            local_monitored_sinks(1,end+1)=monitored_sink_mainline_link_id;
            local_flow_difference=0;
            for i=1:size(local_monitored_sources,2)
                local_flow_difference=local_flow_difference+sum(obj.algorithm_box.beats_simulation.get_output_for_link_id(local_monitored_sources(1,i)).flw_in_veh);
            end
            for i=1:size(local_monitored_sinks,2)
                local_flow_difference=local_flow_difference-sum(obj.algorithm_box.beats_simulation.get_output_for_link_id(local_monitored_sinks(1,i)).flw_in_veh);
            end   
        end    
        
        function [] = set_knob_group_flow_differences(obj)
            for i=1:size(obj.knob_groups,2)
                [source,sink]=obj.get_monitored_segment_for_knob_group(obj.knob_groups{1,i});
                obj.knob_group_flow_differences(1,i)=obj.get_unmonitored_flow_difference(source,sink);
            end
        end
        
        function [] = set_auto_knob_boundaries_refined(obj)
            if (obj.underevaluation_tolerance_coefficient==-Inf || obj.overevaluation_tolerance_coefficient==-Inf)
                obj.underevaluation_tolerance_coefficient=input(['Enter the underevaluation tolerance coefficient for the flow going throw the knob links : ']);
                obj.overevaluation_tolerance_coefficient=input(['Enter the overevaluation tolerance coefficient for the flow going throw the knob links : ']);
            end    
            knob_groups_to_project=[];
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
                    if (size(obj.knob_groups{1,i},1)==1)
                        knob_perfect_value=coeff*obj.knob_group_flow_differences(i)/sum_of_template;
                        obj.perfect_values(knob_index,1)=knob_perfect_value;
                        obj.boundaries_min(knob_index,1)=knob_perfect_value*obj.underevaluation_tolerance_coefficient;
                        obj.boundaries_max(knob_index,1)=knob_perfect_value*obj.overevaluation_tolerance_coefficient;
                    else
                        knob_groups_to_project(end+1)=i;
                    end    
                end    
            end
            obj.knob_groups_to_project=unique(knob_groups_to_project);
        end    
        
        function [knobs_on_correct_subspace]= project_involved_knob_groups_on_correct_flow_subspace(obj, knobs_vector)
            knobs_on_correct_subspace=knobs_vector;
            for i=1:size(obj.knob_groups_to_project)
                knob_group=cell2mat(obj.knob_groups{1,obj.knob_groups_to_project(i)});
                indices=[];
                constraint_equation_coeffs=[];
                for j=1:size(knob_group)
                    index=find(obj.link_ids==knob_group(j));
                    indices(end+1,1)=index;
                    subvector=knobs_vector(indices,1);
                    sum_of_template=obj.algorithm_box.get_sum_of_template_in_veh(obj.link_ids(index));
                    if ismember(obj.link_ids(index),obj.algorithm_box.link_ids_beats(obj.algorithm_box.source_mask_beats))
                        coeff=-1;
                    else
                        coeff=1;
                    end    
                    constraint_equation_coeffs(1,end+1)=coeff*sum_of_template;
                end
                flowdiff=obj.knob_group_flow_differences(1,obj.knob_groups_to_project(i));
                otc=obj.overevaluation_tolerance_coefficient;
                utc=obj.underevaluation_tolerance_coefficient;
                [subvector_on_correct_subspace,fval]=quadprog(eye(size(knob_group,1)),-reshape(subvector,1,[]),[constraint_equation_coeffs;-constraint_equation_coeffs],[otc*flowdiff;-utc*flowdiff],[],[],obj.naive_boundaries_min(indices,1),obj.naive_boundaries_max(indices,1)); % minimization program
                knobs_on_correct_subspace(indices,1)=subvector_on_correct_subspace;
            end    
        end

        %rescale between real and zero-ten scales .........................
        function [result_matrix] = rescale_knobs(obj, input_matrix, isRealScaleToZeroTenScale) % rescales the knobs from 0:10 to their actual respective range (used by cmaes for 'uniform sensitivity' reasons) or the opposite operation.
            min=repmat(obj.boundaries_min,1,size(input_matrix,2));
            range=repmat(obj.boundaries_max-obj.boundaries_min,1,size(input_matrix,2));
            if isRealScaleToZeroTenScale==1
                result_matrix=((input_matrix-min)./range)*10;
            elseif isRealScaleToZeroTenScale==0
                result_matrix=((input_matrix/10).*range)+min;
            else error ('The second parameter must be zero or one');
            end        
        end
        
        %set the knobs in beats............................................
        function [] = set_knobs_persistent(obj, knobs_vector)
            for i= 1:size(obj.link_ids)
                if (ismember(obj.link_ids(i),obj.algorithm_box.link_ids_beats(obj.algorithm_box.source_mask_beats)))
                    obj.algorithm_box.beats_simulation.beats.set.demand_knob_for_link_id(obj.link_ids(i),knobs_vector(i));
                else
                    obj.algorithm_box.beats_simulation.beats.set.knob_for_offramp_link_id(obj.link_ids(i),knobs_vector(i));
                end    
            end
            obj.current_value=knobs_vector;
        end

    end    
    
end

