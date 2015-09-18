classdef PeMSData < handle
    
    %Required for loading from xls :
    
    %   -> pems.days | e.g. : [datenum('2014/10/14'),datenum('2014/10/21'),datenum('2014/11/18'),datenum('2014/11/25'),datenum('2014/12/16')]
    %   -> pems.district | [integer]
    %   -> pems.processed_folder | ['adress of the folder']

    
     properties (SetAccess = ?AlgorithmBox )
        
        is_loaded=0; % flag to indicate if the object is fully loaded
        algorithm_box@AlgorithmBox % parent AlgorithmBox object
        peMS5minData@PeMS5minData % object

        days % horizontal array with the days to use in the pems data
        district % district for PeMS5minData
        processed_folder % folder containing the PeMS processed .mat files
        
        data=struct; % the data itself. The last array is the average of the acceptable other arrays.
        average_mainline_flow % average total flow measured by the mainline sensors

    end
    
    properties (Hidden, SetAccess=?AlgorithmBox)
        
        link_ids % list of the link ids corresponding to the pems data columns
        linear_link_ids % list of the link ids corresponding to the pems data columns, in linear order.
        vds2id % array containing vds and corresponding sensor ids
        vds2id2link % same as before plus corresponding link ids
        
    end    
    
    methods (Access = public)
        
        function [obj] = PeMSData(algoBox)
            obj.algorithm_box=algoBox;
        end   
        
        function [obj] = run_assistant(obj)
            if (obj.algorithm_box.beats_loaded==1)
                isSegment=-1;
                while isSegment ~=1 && isSegment~=0
                    isSegment=input(['PeMS data : Do you want to work on several days in a row (yes=1, no=0) ? : ']);
                end
                if isSegment
                    startyear=input(['Enter PeMS data beginning year (integer) : ']);
                    startmonth=input(['Enter PeMS data beginning month (integer) : ']);
                    startday=input(['Enter PeMS data beginning day (integer) : ']);
                    endyear=input(['Enter PeMS data end year (integer) : ']);
                    endmonth=input(['Enter PeMS data end month (integer) : ']);
                    endday=input(['Enter PeMS data end day (integer) : ']);
                    obj.days = (datenum(startyear, startmonth, startday):datenum(endyear, endmonth, endday));
                else
                    numdays=input('How many days do you want to work on ? : ');
                    obj.days=zeros(1,numdays);
                    for i=1:numdays
                        year=input(['Enter day ',num2str(i),' year (integer) : ']);
                        month=input(['Enter day ',num2str(i),' month (integer) : ']);
                        day=input(['Enter day ',num2str(i),' number of day in the month (integer) : ']);
                        obj.days(1,i)=datenum(year, month, day);
                    end    
                end    
                obj.district = input(['Enter district : ']);
                obj.processed_folder = input(['Enter the adress of the PeMS processed folder : '], 's');
                obj.load;
            else
                error('Beats simulation must be loaded in AlgorithmBox before loading PeMS data.');
            end
        end    
        
        function [] = plot_freeway_contour(obj,with_speed,with_density,with_flow,is_average,firstday,lastday) 
            %unfactorised code
            if (obj.is_loaded==1)
                    if (nargin<2)
                        with_speed=1;
                        with_density=1;
                        with_flow=1;
                    end    
                    if (nargin<5)
                        if obj.algorithm_box.current_day>size(obj.days,2)
                            firstday=1;
                            lastday=1;
                        else    
                        firstday=obj.algorithm_box.current_day;
                        lastday=obj.algorithm_box.current_day;
                        end
                        is_average=0;
                    end
                    mask=obj.algorithm_box.send_mask_pems_to_linear_mainline_space(obj.algorithm_box.good_mainline_mask_pems);
                    linear_mainline_mask=obj.algorithm_box.send_mask_pems_to_linear_space(obj.algorithm_box.good_mainline_mask_pems);
                    ids=obj.linear_link_ids(linear_mainline_mask);
                    ids=unique(ids,'stable');
                    for i=1:size(ids,2)
                        ordered_indices(1,i)=find(obj.link_ids(obj.algorithm_box.good_mainline_mask_pems)==ids(1,i));
                    end
                    if is_average==0
                        average_word='';
                        for j=firstday:lastday
                            duration=['on ', datestr(obj.days(j))];
                            data.speed=obj.data.spd(:,obj.algorithm_box.good_mainline_mask_pems,j);
                            data.density=obj.data.dty(:,obj.algorithm_box.good_mainline_mask_pems,j);
                            data.flw_in_veh=obj.data.flw_in_veh(:,obj.algorithm_box.good_mainline_mask_pems,j);
                            toplot={};
                            count=1;
                            for i=1:sum(obj.algorithm_box.mainline_mask_beats)
                                if mask(i)==1
                                    toplot{1}(:,i)=data.speed(:,ordered_indices(count));
                                    toplot{2}(:,i)=data.density(:,ordered_indices(count));
                                    toplot{3}(:,i)=data.flw_in_veh(:,ordered_indices(count));
                                    count=count+1;
                                else
                                    toplot{1}(:,i)=nan;
                                    toplot{2}(:,i)=nan;
                                    toplot{3}(:,i)=nan;
                                end    
                            end                        
                            if (with_speed==1)
                                figure;
                                imagesc(toplot{1})
                                title(['PeMS data ',average_word,' SPEED contour plot for  \text{',obj.algorithm_box.freeway_name,'} ',duration]);
                                colorbar;
                            end    
                            if (with_density==1)
                                figure;
                                imagesc(toplot{2})
                                title(['PeMS data ',average_word,' DENSITY contour plot for \text{',obj.algorithm_box.freeway_name,'} ',duration]);
                                colorbar;
                            end    
                            if (with_flow==1)
                                figure;
                                imagesc(toplot{3})
                                title(['PeMS data ',average_word,' FLOW contour plot for  \text{',obj.algorithm_box.freeway_name,'} ',duration]);
                                colorbar;
                            end     
                        end
                    else
                        average_word='average';
                        duration=['from ', datestr(obj.days(firstday)),' to ', datestr(obj.days(lastday))];
                        data.speed=mean(obj.data.spd(:,obj.algorithm_box.good_mainline_mask_pems,firstday:lastday),3);
                        data.density=mean(obj.data.dty(:,obj.algorithm_box.good_mainline_mask_pems,firstday:lastday),3);
                        data.flw_in_veh=mean(obj.data.flw_in_veh(:,obj.algorithm_box.good_mainline_mask_pems,firstday:lastday),3);
                        count=1;
                        for i=1:sum(obj.algorithm_box.mainline_mask_beats)
                            if mask(i)==1
                                toplot{1}(:,i)=data.speed(:,ordered_indices(count));
                                toplot{2}(:,i)=data.density(:,ordered_indices(count));
                                toplot{3}(:,i)=data.flw_in_veh(:,ordered_indices(count));
                                count=count+1;
                            else
                                toplot{1}(:,i)=nan;
                                toplot{2}(:,i)=nan;
                                toplot{3}(:,i)=nan;
                            end    
                        end
                        if (with_speed==1)
                            figure;
                            imagesc(toplot{1})
                            title(['PeMS data ',average_word,' SPEED contour plot for  \text{',obj.algorithm_box.freeway_name,'} ',duration]);
                            colorbar;
                        end    
                        if (with_density==1)
                            figure;
                            imagesc(toplot{2})
                            title(['PeMS data ',average_word,' DENSITY contour plot for  \text{',obj.algorithm_box.freeway_name,'} ',duration]);
                            colorbar;
                        end    
                        if (with_flow==1)
                            figure;
                            imagesc(toplot{3})
                            title(['PeMS data ',average_word,' FLOW contour plot for  \text{',obj.algorithm_box.freeway_name,'} ',duration]);
                            colorbar;
                        end
                    end    
    
                else
                    error('PeMS data must be loaded before plotting it.');
            end
        end    
        
    end
    
    methods (Access=?AlgorithmBox)
        function [] = load(obj) %loads pems data once all the inputs have been given to the object
            if (obj.algorithm_box.beats_loaded==1)
                obj.is_loaded=0;
                disp(['LOADING PeMS DATA FROM ',obj.processed_folder]);
                obj.data=struct;
                obj.peMS5minData=PeMS5minData;
                sensor_link = obj.algorithm_box.beats_simulation.scenario_ptr.get_sensor_link_map;
                obj.link_ids=reshape(sensor_link(:,2),1,[]);
                obj.vds2id = obj.algorithm_box.beats_simulation.scenario_ptr.get_sensor_vds2id_map;
                obj.peMS5minData.load(obj.processed_folder,  obj.vds2id(:,1), obj.days);
                obj.data=obj.peMS5minData.get_data_batch_aggregate(obj.vds2id(:,1), obj.days, 'var',{'flw','spd','dty'},'smooth', true, 'fill',true);
                obj.data.dty(ismember(obj.data.dty,Inf))=nan;
                obj.data.flw(:,~any(obj.data.flw,1))=nan;
                obj.data.dty(:,~any(obj.data.dty,1))=nan;
                obj.data.spd(:,~any(obj.data.spd,1))=nan;
                obj.data.flw(:,:,end+1)=mean(obj.data.flw(:,:,:),3);
                obj.data.dty(:,:,end+1)=mean(obj.data.dty(:,:,:),3);
                obj.data.spd(:,:,end+1)=mean(obj.data.spd(:,:,:),3);
                obj.data.flw_in_veh=obj.data.flw/12;
                unique_linear_link_ids=obj.algorithm_box.linear_link_ids(ismember(obj.algorithm_box.linear_link_ids,obj.link_ids));
                obj.linear_link_ids=unique_linear_link_ids;
%                 obj.linear_link_ids=[];
%                 for i=1:size(unique_linear_link_ids,2)
%                     ids=obj.link_ids(1,ismember(obj.link_ids,unique_linear_link_ids(1,i)));
%                     for j=1:size(ids,2)
%                         obj.linear_link_ids(1,end+1)=ids(1);
%                     end    
%                 end    
                obj.vds2id2link=[obj.vds2id,reshape(obj.link_ids,[],1)];
                obj.is_loaded=1;
                disp('PeMS DATA LOADED.');
            else
                error('Beats simulation must be loaded before loading pems data.');
            end       
        end    
    end    
    
end

