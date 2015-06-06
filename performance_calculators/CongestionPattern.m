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
        
        function [obj] = CongestionPattern(algoBox, congestion_patterns)
            if (nargin<1)
                error('You must enter an AlgorithmBox as argument of any performance calculator constructor.');
            elseif (algoBox.beats_loaded==1 && algoBox.pems.is_loaded==1)
                %congestion_patterns is a single column cell array of structs whose fields are 'left_absciss', 'left_absciss','up_ordinate' and 'down_ordinate'. 
                %They correspond to the coordinates of the corners of  rectangles of the congestion patterns
                %These coordinates are included.
                %The space in which this is expressed is the linear mainline
                %space (135x288 in the case of 210E during one day with
                %OUTPUT_DT set to 5 minutes).
                %RECTANGLES HAVE TO BE DISJOINED
                obj.algorithm_box=algoBox;
                if nargin<2
                    nrectangles=input(['How many rectangles will this "CongestionPattern" have ? : ']);
                    congestion_patterns=cell(nrectangles,1);
                    for i=1:nrectangles
                        congestion_patterns{i,1}.left_absciss=input(['Left absciss of rectangle number ', num2str(i),' (absciss of linear mainline id) : ']);
                        congestion_patterns{i,1}.right_absciss=input(['Right absciss of rectangle number ' , num2str(i), '(absciss of linear mainline id) : ']);
                        congestion_patterns{i,1}.up_ordinate=input(['Up (earliest) ordinate of rectangle number ' , num2str(i), '(beginning time) : ']);
                        congestion_patterns{i,1}.down_ordinate=input(['Down (latest) absciss of rectangle number ' , num2str(i), '(end time) : '] );
                    end    
                end    
                if isfield(congestion_patterns{1,1},'left_absciss') && isfield(congestion_patterns{1,1},'right_absciss') && isfield(congestion_patterns{1,1},'up_ordinate') && isfield(congestion_patterns{1,1},'down_ordinate')
                    obj.rectangles=congestion_patterns;
                    obj.vertical_size=size(obj.algorithm_box.beats_simulation.outflow_veh{1,1},1);
                    obj.horizontal_size=sum(obj.algorithm_box.mainline_mask_beats);
                    obj.linear_mainline_links=obj.algorithm_box.linear_link_ids(obj.algorithm_box.send_mask_beats_to_linear_space(obj.algorithm_box.mainline_mask_beats));
                    linear_fwy_indices=obj.algorithm_box.beats_simulation.scenario_ptr.extract_linear_fwy_indices;
                    obj.linear_mainline_indices=linear_fwy_indices(obj.algorithm_box.send_mask_beats_to_linear_space(obj.algorithm_box.mainline_mask_beats));
                    obj.set_critical_densities;
                    else error('Argument congestion_patterns not in the right format. Please see code comments.');     
                end
                obj.calculate_from_pems;
            else error('Beats simulation and PeMS data must be loaded first.')
            end
        end    
        
        function [result] = calculate_from_beats(obj)
            result=zeros(obj.vertical_size, obj.horizontal_size);
            densities=obj.algorithm_box.beats_simulation.density_veh{1,1}(2:end,obj.linear_mainline_indices);
            result(densities>obj.critical_densities+6)=1; 
            obj.result_from_beats=result;
            obj.error_in_percentage=100*sum(sum(abs(obj.result_from_beats-obj.result_from_pems)))/sum(sum(obj.result_from_pems));
            obj.error_in_percentage_history=[obj.error_in_percentage_history;obj.error_in_percentage];

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
            if (sum(sum(obj.result_from_pems))~=0) && (sum(sum(obj.result_from_beats~=0)))
                obj.error_in_percentage=100*sum(sum((abs(obj.result_from_beats-obj.result_from_pems))))/sum(sum(obj.result_from_pems));
            end    
        end    

        function [h] = plot(obj,figureNumber,frameNumber,frame)
            if (nargin<2)
                h=figure;
            else
                h=figure(figureNumber);
            end
            if (nargin<3)
               imagesc(obj.result_from_beats-obj.result_from_pems); 
%                p=[0,0,450,350];
%                set(h, 'Position', p);
               title('Contour plot : Congestion pattern matching');
            else
               imagesc(frame);
               title(['Contour plot : Congestion pattern matching (Beats evaluation number ',num2str(frameNumber),')']);
            end    
            xlabel('Linear mainline links');
            ylabel('Time (unit : 5 minutes if SI)');
            
        end 
        
        function [] = save_plot(obj)
            frame=obj.result_from_beats-obj.result_from_pems;
            if exist([pwd,'\movies\',obj.algorithm_box.dated_name,'\frames'],'dir')~=7
                mkdir([pwd,'\movies\',obj.algorithm_box.dated_name,'\frames']);
            end
            save([pwd,'\movies\',obj.algorithm_box.dated_name,'\frames\',Utilities.get_matfile_number(['movies\',obj.algorithm_box.dated_name,'\frames']),'.mat'],'frame');
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

        
    end    
end


