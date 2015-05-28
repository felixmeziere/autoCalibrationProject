classdef CongestionPattern < PerformanceCalculator
    %Congestion Summary of this class goes here
    %   Detailed explanation goes here

    properties (SetAccess = protected)
    
        name='Congestion Pattern'
        rectangles
        vertical_size
        horizontal_size
        linear_mainline_links
        critical_densities
        linear_mainline_indices
        linear_link_lengths_miles
        
    end    
    
    methods (Access = public)
        
        function [obj] = CongestionPattern(algoBox, rectangles) 
            %rectangles is a single column cell array of structs whose fields are 'left_absciss', 'left_absciss','up_ordinate' and 'down_ordinate'. 
            %They correspond to the coordinates of the corners of  rectangles of the congestion patterns
            %These coordinates are included.
            %The space in which this is expressed is the linear mainline
            %space (135x288 in the case of 210E during one day with
            %OUTPUT_DT set to 5 minutes).
            %RECTANGLES HAVE TO BE DISJOINED
            if isfield(rectangles{1,1},'left_absciss') && isfield(rectangles{1,1},'right_absciss') && isfield(rectangles{1,1},'up_ordinate') && isfield(rectangles{1,1},'down_ordinate')
                obj.name='Congestion Pattern';
                obj.rectangles=rectangles;
                obj.vertical_size=size(algoBox.pems.data.flw,1);
                obj.horizontal_size=sum(algoBox.mainline_mask_beats);
                obj.linear_mainline_links=algoBox.linear_link_ids(obj.send_mask_beats_to_linear_space(algoBox,algoBox.mainline_mask_beats));
                linear_fwy_indices=algoBox.beats_simulation.scenario_ptr.extract_linear_fwy_indices;
                obj.linear_mainline_indices=linear_fwy_indices(obj.send_mask_beats_to_linear_space(algoBox,algoBox.mainline_mask_beats));
                obj.set_critical_densities(algoBox);
                else error('Argument rectangles not in the right format. Please see code comments.');     
            end
        end    
        
%         function [result] = calculate_from_beats(obj, algoBox)
%             %CHECK ONLY ON MONITORED LINKS (SIMPLIFIES ALL THIS).
%             result=zeros(obj.vertical_size, obj.horizontal_size);
%             for i=1:size(obj.rectangles,1)
%                 uo=obj.rectangles{i}.up_ordinate;
%                 do=obj.rectangles{i}.down_ordinate;
%                 la=obj.rectangles{i}.left_absciss;
%                 ra=obj.rectangles{i}.right_absciss;
%                 densities=algoBox.beats_simulation.density_veh{1,1}(uo:do,obj.linear_mainline_indices(la:ra));
%                 rectangle=zeros(do-uo+1,ra-la+1);
%                 rectangle(densities>obj.critical_densities{i,1})=-1;
%                 result(uo:do,la:ra)=rectangle;
%             end    
%             obj.result_from_beats=result;
%         end

        function [result] = calculate_from_beats(obj, algoBox)
            %CHECK ONLY ON MONITORED LINKS (SIMPLIFIES ALL THIS).
            result=zeros(obj.vertical_size, obj.horizontal_size);
%             for i=1:size(obj.rectangles,1)
%                 uo=obj.rectangles{i}.up_ordinate;
%                 do=obj.rectangles{i}.down_ordinate;
%                 la=obj.rectangles{i}.left_absciss;
%                 ra=obj.rectangles{i}.right_absciss;
                densities=algoBox.beats_simulation.density_veh{1,1}(2:end,obj.linear_mainline_indices);
%                 rectangle=zeros(do-uo+1,ra-la+1);
                result(densities>obj.critical_densities+6)=1;
%             end    
            obj.result_from_beats=result;
        end
        
        function [result] = calculate_from_pems(obj, algoBox)
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
        end    
        
    end
    
    methods (Access = public) %public for debug reasons
       
        
%         function [] = set_critical_densities(obj, algoBox)
%             obj.critical_densities=cell(size(obj.rectangles));
%             link_lengths_meters=algoBox.beats_simulation.scenario_ptr.get_link_lengths('si');
%             link_lengths_meters=link_lengths_meters(obj.linear_mainline_indices);
%             links=algoBox.beats_simulation.scenario_ptr.get_link_byID(obj.linear_mainline_links);
%             for i=1:size(obj.linear_mainline_links,2)
%                 number_lanes(1,i)=links(1,i).ATTRIBUTE.lanes;
%             end    
%             for i=1:size(obj.rectangles,1)
%                 this_critical_densities=[];
%                 uo=obj.rectangles{i}.up_ordinate;
%                 do=obj.rectangles{i}.down_ordinate;
%                 la=obj.rectangles{i}.left_absciss;
%                 ra=obj.rectangles{i}.right_absciss;
%                 fds=algoBox.beats_simulation.scenario_ptr.get_fds_with_linkIDs(obj.linear_mainline_links(1,la:ra));
%                 this_number_lanes=number_lanes(1,la:ra);
%                 this_number_lanes=repmat(this_number_lanes,do-uo+1,1);
%                 this_link_lengths_meters=repmat(link_lengths_meters(1,la:ra),do-uo+1,1);
%                 for p=1:size(fds,2)
%                     this_critical_densities(1,p)=fds(1,p).capacity/fds(1,p).free_flow_speed;
%                 end    
%                 this_critical_densities=repmat(this_critical_densities,do-uo+1,1);
%                 this_critical_densities=this_critical_densities.*this_link_lengths_meters.*this_number_lanes;
%                 obj.critical_densities{i,1}=this_critical_densities;
%             end    
%         end      

          function [] = set_critical_densities(obj, algoBox)
                obj.critical_densities=zeros(obj.vertical_size,obj.horizontal_size);
                link_lengths_meters=algoBox.beats_simulation.scenario_ptr.get_link_lengths('si');
                link_lengths_meters=link_lengths_meters(obj.linear_mainline_indices);
                link_lengths_meters=repmat(link_lengths_meters,obj.vertical_size,1);
                links=algoBox.beats_simulation.scenario_ptr.get_link_byID(obj.linear_mainline_links);
                for i=1:size(obj.linear_mainline_links,2)
                    number_lanes(1,i)=links(1,i).ATTRIBUTE.lanes;
                end    
                number_lanes=repmat(number_lanes,obj.vertical_size,1);
                fds=algoBox.beats_simulation.scenario_ptr.get_fds_with_linkIDs(obj.linear_mainline_links);
                for p=1:size(fds,2)
                    critical_densities(1,p)=fds(1,p).capacity/fds(1,p).free_flow_speed;
                end    
                critical_densities=repmat(critical_densities,obj.vertical_size,1);
                critical_densities=critical_densities.*link_lengths_meters.*number_lanes;
                obj.critical_densities=critical_densities;   
        end            

        
        function [linear_mask_in_mainline_space] = send_mask_beats_to_linear_mainline_space(obj, algoBox,mask_beats)
            linear_mask_in_mainline_space=obj.send_linear_mask_beats_to_mainline_space(algoBox, obj.send_mask_beats_to_linear_space(algoBox, mask_beats));
        end  
        
    end  
    
    methods (Static, Access = private)
    
        function [linear_mask] = send_mask_beats_to_linear_space(algoBox, mask_beats)
            linear_mask=ismember(algoBox.linear_link_ids,algoBox.link_ids_beats(mask_beats));
        end    
        
        function [linear_mask_in_mainline_space] = send_linear_mask_beats_to_mainline_space(algoBox, linear_mask_beats)
            mainline_link_ids=algoBox.link_ids_beats(algoBox.mainline_mask_beats);
            linear_mask_in_mainline_space = ismember(mainline_link_ids,algoBox.linear_link_ids(linear_mask_beats));
        end    
        
          
        
        function [linear_mask_in_mainline_space] = send_mask_pems_to_linear_mainline_space(algoBox, mask_pems)
            mainline_link_ids=algoBox.link_ids_beats(algoBox.mainline_mask_beats);
            mainline_masked_link_ids=algoBox.link_ids_pems(mask_pems);
            linear_mask_in_mainline_space = ismember(mainline_link_ids,mainline_masked_link_ids);
        end    
    end    
end


