classdef PeMSData < handle
    
    properties (SetAccess = ?AlgorithmBox)
        
        is_loaded=0;
        current_day=1; %current day used in the pems data loaded.
        algorithm_box@AlgorithmBox
        peMS5minData@PeMS5minData
        
        days
        district
        processed_folder
        
        data=struct;

    end
    
    properties (Hidden, SetAccess=?AlgorithmBox)
        
        link_ids % list of the link ids corresponding to the pems data columns, in linear order.
        vds2id
        
    end    
    
    methods (Access = public)
        
        function [obj] = PeMSData(algoBox)
            obj.algorithm_box=algoBox;
        end   
        
        function [obj] = run_assistant(obj)
            if (obj.algorithm_box.beats_loaded==1)
                startyear=input(['Enter pems data beginning year (integer) : ']);
                startmonth=input(['Enter pems data beginning month (integer) : ']);
                startday=input(['Enter pems data beginning day (integer) : ']);
                endyear=input(['Enter pems data end year (integer) : ']);
                endmonth=input(['Enter pems data end month (integer) : ']);
                endday=input(['Enter pems data end day (integer) : ']);
                obj.days = (datenum(startyear, startmonth, startday):datenum(endyear, endmonth, endday));
                obj.district = input(['Enter district : ']);
                obj.processed_folder = input(['Enter the adress of the PeMS processed folder : '], 's');
                obj.load;
            else
                error('Beats simulation must be loaded in AlgorithmBox before loading PeMS data.');
            end
        end    
        
    end
    
    methods (Access=?AlgorithmBox)
        function [] = load(obj) %loads pems data once all the inputs have been given to the object
            if (obj.algorithm_box.beats_loaded==1)
                obj.is_loaded=0;
                obj.data=struct;
                obj.peMS5minData=PeMS5minData;
                sensor_link = obj.algorithm_box.beats_simulation.scenario_ptr.get_sensor_link_map;
                obj.link_ids=reshape(sensor_link(:,2),1,[]);
                obj.vds2id = obj.algorithm_box.beats_simulation.scenario_ptr.get_sensor_vds2id_map;
                obj.peMS5minData.load(obj.processed_folder,  obj.vds2id(:,1), obj.days);
                obj.data=obj.peMS5minData.get_data_batch_aggregate(obj.vds2id(:,1), obj.days(obj.current_day), 'smooth', true, 'fill',true);
                obj.data.flw_in_veh=obj.data.flw/12;
                obj.data.occ=obj.data.occ;
                obj.is_loaded=1;
                disp('PeMS DATA LOADED.');
            else
                error('Beats simulation must be loaded before loading pems data.');
            end       
        end    
    end    
    
end

