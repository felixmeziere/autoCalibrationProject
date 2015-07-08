classdef CongestionPattern < PerformanceCalculator
    
    % Required for loading from xls :
    %    -> settings.rectangles | cell(n,1)       
    %    For i from 1 to n :    
    %       -> settings.congestion_pattern.rectangles{i,1}.left_absciss | [integer]
    %       -> settings.congestion_pattern.rectangles{i,1}.right_absciss | [integer]
    %       -> settings.congestion_pattern.rectangles{i,1}.up_ordinate | [integer]
    %       -> settings.congestion_pattern.rectangles{i,1}.down_ordinate | [integer]
    %       -> settings.congestion_pattern.false_positive_coefficient | [fraction of 1]
    %       -> settings.congestion_pattern.false_negative_coefficient | [fraction of 1]
    
    properties (Constant)
        
        name='Congestion pattern';
    
    end
    
    properties (SetAccess = protected)
    
        rectangles %(px1) cell array of structs identical to settings.congestion_pattern.rectangles : rectangles{i,1}=struct('left_absciss',int,'right_absciss',int,'up_ordinate',int,'down_ordinate',int); coordinates are in the contour plot (absciss : linear mainline links, ordinate : time in 5 minutes steps i.e. 0:288 for one day).
        vertical_size %size of ordinate (289 for one day with 5mn step)
        horizontal_size %size of absciss (135 for the 210E scenario I used)
        linear_mainline_links %mainline link ids in linear order
        critical_densities %densities above which each link is theoretically congested, in the order of the preceding property
        linear_mainline_indices %index of the links of linear_mainline_links in the beats scenario order (i.e. find(obj.algorithm_box.link_ids_beats==obj.linear_mainline_links(i))
        false_positive_coefficient=-1; %the sum of these two positive coefficients must be one. Importance given to false positive vs. false negative (i.e. congestion where there shouldn't be vs. freeflow where there shouldn't be). Usually 0.5 and 0.5.
        false_negative_coefficient=-1; %See above.
        
    end    
    
    properties (Hidden, SetAccess=protected)
        
        first_load=1; %flag to indicate if the object has been loaded before.

    end    
    
    methods (Access = public)
        
        function [obj] = CongestionPattern(algoBox)
            if (nargin<1)
                error('You must enter an AlgorithmBox as argument of any performance calculator constructor.');
            elseif (algoBox.beats_loaded==1 && algoBox.pems.is_loaded==1)
                %obj.rectangles is a single column cell array of structs whose fields are 'left_absciss', 'left_absciss','up_ordinate' and 'down_ordinate'. 
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
                obj.rectangles=obj.algorithm_box.settings.congestion_pattern.rectangles;
                obj.false_negative_coefficient=obj.algorithm_box.settings.congestion_pattern.false_negative_coefficient;
                obj.false_positive_coefficient=obj.algorithm_box.settings.congestion_pattern.false_positive_coefficient;
                if (isfield(obj.rectangles{1,1},'left_absciss') && isfield(obj.rectangles{1,1},'right_absciss')...
                && isfield(obj.rectangles{1,1},'up_ordinate') && isfield(obj.rectangles{1,1},'down_ordinate')...
                && obj.false_positive_coefficient+obj.false_negative_coefficient==1 && 0<obj.false_negative_coefficient && 0<obj.false_positive_coefficient && 1>obj.false_negative_coefficient ...
                && 1>obj.false_positive_coefficient)
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
        
        function [result] = calculate_from_beats(obj) %the choosen critical density is critical density+epsilon (*[1+epsilon] doesn't work as good) to avoid noise : we are looking for very congested links. Here epsilon is 6 which has empirically proven to work well on 210E.
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
        end    
        
        function [error,error_in_percentage] = calculate_error(obj,frame)
            if nargin>1
                contour=frame;
            else
                contour=obj.result_from_pems-obj.result_from_beats;
            end    
            for i=1:size(contour,2)
                for j=1:size(contour,1)
                    if contour(j,i)==1
                        contour(j,i)=obj.false_negative_coefficient;
                    elseif contour(j,i)==-1
                        contour(j,i)=obj.false_positive_coefficient;
                    end    
                end
            end
            error=2*obj.norm.calculate(contour,0);
            error_in_percentage=100*error/obj.norm.calculate(obj.result_from_pems,0);
            obj.error = error;
            obj.error_in_percentage=error_in_percentage;
            obj.error_history(end+1,1)=error;
            obj.error_in_percentage_history=[obj.error_in_percentage_history;error_in_percentage];         
        end   
        
        function [h] = plot(obj,figureNumber,frameNumber,frame)
            if (nargin<2)
                h=figure;
            else
                h=figure(figureNumber);
            end
            if (nargin<3)
               frame=obj.result_from_beats-obj.result_from_pems;
               frameNumber=obj.algorithm_box.numberOfEvaluations;
            end
            frame(ismember(frame,0))=2;
            imagesc(-frame);
            title(['Contour plot : Congestion pattern matching (Beats evaluation number ',num2str(frameNumber),') | Error : ',num2str(obj.error_in_percentage_history(frameNumber)),'%']);
            xlabel('Linear mainline links');
            ylabel('Time (unit : 5 minutes if SI)');
            leg={'Correct Congestion Matching','False Positive','False Negative'};
            cmap=[0.3,0.8,0.4;1,0,0;1,1,0];
            colormap(cmap);
            L = line(ones(3),ones(3), 'LineWidth',2); 
            set(L,{'color'},mat2cell(cmap(1:end,:),ones(1,3),3));
            legend(leg);
        end 
        
        function [] = save_plot(obj) %save the error matrix in a .mat file to bea able to plot a movie afterwards.
            frame=obj.result_from_beats-obj.result_from_pems;
            save([pwd,'\movies\',obj.algorithm_box.dated_name,'\frames\',num2str(obj.algorithm_box.numberOfEvaluations),'.mat'],'frame');
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
        end  % Compute the critical density for each link aand save it in the property 
        
        function [] = run_assistant(obj) %assitant called by errror function if needed.
                change_rectangles=-1;
                obj.false_negative_coefficient=input(['Enter the false negative coefficient for CongestionPattern (zero to one): ']);
                obj.false_positive_coefficient=input(['Enter the false positive coefficient for CongestionPattern (one-precedent): ']);
                if (obj.false_negative_coefficient+obj.false_positive_coefficient~=1)
                   error('The sum of the false positive and false negative coefficients must be one.')
                end
                obj.algorithm_box.settings.congestion_pattern.false_positive_coefficient=obj.false_positive_coefficient;
                obj.algorithm_box.settings.congestion_pattern.false_negative_coefficient=obj.false_negative_coefficient;
                if isfield(obj.algorithm_box.settings,'congestion_pattern.rectangles')
                    change_rectangles=-1;
                    if (obj.first_load~=1)
                        while (change_rectangles~=1 && change_rectangles ~= 0)
                            change_rectangles=input(['Do you want to change the rectangles (instead of leaving them as they were until now) (1=yes/0=no) ? : ']);
                        end
                    end
                else
                    change_rectangles=1;
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
                    obj.algorithm_box.settings.congestion_pattern.rectangles=obj.rectangles;
                else
                    obj.rectangles=obj.algorithm_box.settings.congestion_pattern.rectangles;
                end
        end    
   
    end    
end


