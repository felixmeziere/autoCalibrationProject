classdef CongestionPattern < PerformanceCalculator
    %Congestion Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        
        name='Congestion pattern';
    
    end
    
    properties (SetAccess = protected)
    
        rectangles
        vertical_size
        horizontal_size
        linear_mainline_links
        critical_densities
        linear_mainline_indices
        
    end    
    
    methods (Access = public)
        
        function [obj] = CongestionPattern(algoBox) 
            %obj.algorithm_box.temp.congestion_patterns is a single column cell array of structs whose fields are 'left_absciss', 'left_absciss','up_ordinate' and 'down_ordinate'. 
            %They correspond to the coordinates of the corners of  rectangles of the congestion patterns
            %These coordinates are included.
            %The space in which this is expressed is the linear mainline
            %space (135x288 in the case of 210E during one day with
            %OUTPUT_DT set to 5 minutes).
            %RECTANGLES HAVE TO BE DISJOINED
            obj.algorithm_box=algoBox;    
            if isfield(obj.algorithm_box.temp.congestion_patterns{1,1},'left_absciss') && isfield(obj.algorithm_box.temp.congestion_patterns{1,1},'right_absciss') && isfield(obj.algorithm_box.temp.congestion_patterns{1,1},'up_ordinate') && isfield(obj.algorithm_box.temp.congestion_patterns{1,1},'down_ordinate')
                obj.rectangles=obj.algorithm_box.temp.congestion_patterns;
                obj.vertical_size=size(obj.algorithm_box.beats_simulation.outflow_veh{1,1},1);
                obj.horizontal_size=sum(obj.algorithm_box.mainline_mask_beats);
                obj.linear_mainline_links=obj.algorithm_box.linear_link_ids(obj.send_mask_beats_to_linear_space(obj.algorithm_box,obj.algorithm_box.mainline_mask_beats));
                linear_fwy_indices=obj.algorithm_box.beats_simulation.scenario_ptr.extract_linear_fwy_indices;
                obj.linear_mainline_indices=linear_fwy_indices(obj.send_mask_beats_to_linear_space(obj.algorithm_box,obj.algorithm_box.mainline_mask_beats));
                obj.set_critical_densities(obj.algorithm_box);
                else error('Argument congestion_patterns not in the right format. Please see code comments.');     
            end    
        end    
        
        function [result] = calculate_from_beats(obj)
            result=zeros(obj.vertical_size, obj.horizontal_size);
            densities=obj.algorithm_box.beats_simulation.density_veh{1,1}(2:end,obj.linear_mainline_indices);
            result(densities>obj.critical_densities+6)=1; 
            obj.result_from_beats=result;
            obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
        end
        
        function [result] = calculate_from_pems(obj)
            %CHECK ONLY ON MONITORED LINKS (SIMPLIFIES ALL THIS).
            result=zeros(obj.vertical_size, obj.horizontal_size);
            for i=1:size(obj.rectangles,1)
                uo=obj.rectangles{i}.up_ordinate;
                do=obj.rectangles{i}.down_ordinate;
                la=obj.rectangles{i}.left_absciss;
                ra=obj.rectangles{i}.right_absciss;
                result(uo:do,la:ra)=ones(do-uo+1,ra-la+1);
            end    
            obj.result_from_pems=result;
            obj.error_in_percentage=100*(obj.result_from_beats-obj.result_from_pems)/obj.result_from_pems;
        end    
        
    end
    
    methods (Access = public) %public for debug reasons
       
        %Set critical densities...........................................
        function [] = set_critical_densities(obj)
                obj.critical_densities=zeros(obj.vertical_size,obj.horizontal_size);
                link_lengths_meters=obj.algorithm_box.beats_simulation.scenario_ptr.get_link_lengths('si');
                link_lengths_meters=link_lengths_meters(obj.linear_mainline_indices);
                link_lengths_meters=repmat(link_lengths_meters,obj.vertical_size,1);
                links=obj.algorithm_box.beats_simulation.scenario_ptr.get_link_byID(obj.linear_mainline_links);
                for i=1:size(obj.linear_mainline_links,2)
                    number_lanes(1,i)=links(1,i).ATTRIBUTE.lanes;
                end    
                number_lanes=repmat(number_lanes,obj.vertical_size,1);
                fds=obj.algorithm_box.beats_simulation.scenario_ptr.get_fds_with_linkIDs(obj.linear_mainline_links);
                for p=1:size(fds,2)
                    critical_densities(1,p)=fds(1,p).capacity/fds(1,p).free_flow_speed;
                end    
                critical_densities=repmat(critical_densities,obj.vertical_size,1);
                critical_densities=critical_densities.*link_lengths_meters.*number_lanes;
                obj.critical_densities=critical_densities;   
          end            

        %Utilities.........................................................
        
        function [linear_mask] = send_mask_beats_to_linear_space(obj, mask_beats)
            linear_mask=ismember(obj.algorithm_box.linear_link_ids,obj.algorithm_box.link_ids_beats(mask_beats));
        end    
        
        function [linear_mask_in_mainline_space] = send_linear_mask_beats_to_mainline_space(obj, linear_mask_beats)
            mainline_link_ids=obj.algorithm_box.link_ids_beats(obj.algorithm_box.mainline_mask_beats);
            linear_mask_in_mainline_space = ismember(mainline_link_ids,obj.algorithm_box.linear_link_ids(linear_mask_beats));
        end  
        
        function [linear_mask_in_mainline_space] = send_mask_beats_to_linear_mainline_space(obj,mask_beats)
            linear_mask_in_mainline_space=obj.send_linear_mask_beats_to_mainline_space(obj.algorithm_box, obj.send_mask_beats_to_linear_space(obj.algorithm_box, mask_beats));
        end   

        function [linear_mask_in_mainline_space] = send_mask_pems_to_linear_mainline_space(obj, mask_pems)
            mainline_link_ids=obj.algorithm_box.link_ids_beats(obj.algorithm_box.mainline_mask_beats);
            mainline_masked_link_ids=obj.algorithm_box.link_ids_pems(mask_pems);
            linear_mask_in_mainline_space = ismember(mainline_link_ids,mainline_masked_link_ids);
        end    
    end    
end


