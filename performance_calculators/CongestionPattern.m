classdef CongestionPattern < PerformanceCalculator
    
    % Required for loading from xls :
    %    -> temp.rectangles | cell(n,1)       
    %    For i from 1 to n :    
    %       -> temp.congestion_pattern.rectangles{i,1}.left_absciss | [integer]
    %       -> temp.congestion_pattern.rectangles{i,1}.right_absciss | [integer]
    %       -> temp.congestion_pattern.rectangles{i,1}.up_ordinate | [integer]
    %       -> temp.congestion_pattern.rectangles{i,1}.down_ordinate | [integer]
    %       -> temp.congestion_pattern.false_positive_coefficient | [fraction of 1]
    %       -> temp.congestion_pattern.false_negative_coefficient | [fraction of 1]
    
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
        false_positive_coefficient=-1;
        false_negative_coefficient=-1;
        
    end    
    
    properties (Hidden, SetAccess=protected)
        
        first_load=1;

    end    
    
    methods (Access = public)
        
        function [obj] = CongestionPattern(algoBox)
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
                if obj.algorithm_box.currently_loading_from_xls==0
                    obj.run_assistant;
                end
                if (isfield(obj.rectangles{1,1},'left_absciss') && isfield(obj.rectangles{1,1},'right_absciss')...
                && isfield(obj.rectangles{1,1},'up_ordinate') && isfield(obj.rectangles{1,1},'down_ordinate')...
                && obj.false_positive_coefficient+obj.false_negative_coefficient==1 && 0<obj.false_negative_coefficient<1 ...
                && 0<obj.false_positive_coefficient<1)
                    obj.vertical_size=size(obj.algorithm_box.beats_simulation.outflow_veh{1,1},1);
                    obj.horizontal_size=sum(obj.algorithm_box.mainline_mask_beats);
                    obj.linear_mainline_links=obj.algorithm_box.linear_link_ids(obj.algorithm_box.send_mask_beats_to_linear_space(obj.algorithm_box.mainline_mask_beats));
                    linear_fwy_indices=obj.algorithm_box.beats_simulation.scenario_ptr.extract_linear_fwy_indices;
                    obj.linear_mainline_indices=linear_fwy_indices(obj.algorithm_box.send_mask_beats_to_linear_space(obj.algorithm_box.mainline_mask_beats));
                    obj.set_critical_densities;
                else error('Congestion pattern construction inputs not all present or not in the right format. Please see code comments.');     
                end
                obj.calculate_from_pems;
                obj.first_load=0;
            else error('Beats simulation and PeMS data must be loaded first.')
            end
        end    
        
        function [result] = calculate_from_beats(obj)
            result=zeros(obj.vertical_size, obj.horizontal_size);
            densities=obj.algorithm_box.beats_simulation.density_veh{1,1}(2:end,obj.linear_mainline_indices);
            result(densities>obj.critical_densities+6)=1; 
            obj.result_from_beats=result;
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
        
        function [result,result_in_percentage] = calculate_error(obj)
            contour=obj.result_from_pems-obj.result_from_beats;
            for i=1:size(contour,2)
                for j=1:size(contour,1)
                    if contour(j,i)==1
                        contour(j,i)=obj.false_negative_coefficient;
                    elseif contour(j,i)==-1
                        contour(j,i)=obj.false_positive_coefficient;
                    end    
                end
            end
            result=obj.norm.calculate(contour,0);
            error_in_percentage=100*result/obj.norm.calculate(obj.result_from_pems,0);
            obj.result = result;
            obj.error_in_percentage=error_in_percentage;
            obj.error_in_percentage_history=[obj.error_in_percentage_history;error_in_percentage];         
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
        
        function [] = run_assistant(obj)
                norm=input(['Enter the name of a Norm subclass (like L1) : ']);
                obj.false_negative_coefficient=input(['Enter the false negative coefficient for CongestionPattern (zero to one): ']);
                obj.false_positive_coefficient=input(['Enter the false positive coefficient for CongestionPattern (one-precedent): ']);
                if (obj.false_negative_coefficient+obj.false_positive_coefficient~=1)
                   error('The sum of the false positive and false negative coefficients must be one.')
                end
                obj.norm=norm;
                obj.false_positive_coefficient=obj.false_positive_coefficient;
                obj.false_negative_coefficient=obj.false_negative_coefficient;
                if isfield(obj.algorithm_box.temp,'congestion_patterns')
                    change_rectangles=-1;
                    if (obj.first_load~=1)
                        while (change_rectangles~=1 && change_rectangles ~= 0)
                            change_rectangles=input(['Do you want to change the rectangles (instead of leaving them as they were until now) (1=yes/0=no) ? : ']);
                        end
                    end    
                end
                if change_rectangles==1
                    nrectangles=input(['How many rectangles will this "CongestionPattern" have ? : ']);
                    obj.rectangles=cell(nrectangles,1);
                    for i=1:nrectangles
                        obj.rectangles{i,1}.left_absciss=input(['Left absciss of rectangle number ', num2str(i),' (absciss of linear mainline id) : ']);
                        obj.rectangles{i,1}.right_absciss=input(['Right absciss of rectangle number ' , num2str(i), '(absciss of linear mainline id) : ']);
                        obj.rectangles{i,1}.up_ordinate=input(['Up (earliest) ordinate of rectangle number ' , num2str(i), '(beginning time) : ']);
                        obj.rectangles{i,1}.down_ordinate=input(['Down (latest) absciss of rectangle number ' , num2str(i), '(end time) : '] );
                    end
                    obj.algorithm_box.remove_field_from_property('temp','congestion_patterns');
                    obj.algorithm_box.temp.congestion_patterns=obj.rectangles;
                else
                    obj.rectangles=obj.algorithm_box.temp.congestion_patterns;
                end
        end    
   
    end    
end


