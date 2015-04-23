classdef (Abstract) AlgorithmBox < handle
    %AlgorithmBox : used by any algorithm.
    %   Contains the properties and methods that are used by any algorithm for
    %   the automatic calibration problem (for now, tuning only on and
    %   offramp knobs). This allows you to run a program set in an excel
    %   file and automaticlly registers the results in another excel file.
    
    properties (Abstract, Constant)
        
        algorithm_name %name used sometimes.
        
    end    
    
    properties (Abstract, Access = public)
        
        starting_point %starting vector or matrix. If the starting point is a matrix (e.g. if is a population for an evolutionnary algorithm), the columns are vectors (individuals) and the rows are knobs.
        
    end    
    
    properties (Access = public)
        
        performance_calculator@PerformanceCalculator % a PerformanceCalculator subclass, which is a quantity measured in pems or outputed by beats (e.g. TVM).
        error_calculator@ErrorCalculator % an ErrorCalculator subclass, which is a way of comparing two performance calculator values (e.g. L1 norm).
        beats_simulation@BeatsSimulation % the BeatsSimulation object that will run and be overwritten at each algorithm iteration.
        beats_parameters=struct; % the parameters passed to BeatsSimulation.run_beats(beats_parameters).
        pems % the pems data to compare with the beats results.
        knobs=struct; % struct with three array fields : (nx1) 'knob_link_ids' containing the ids of the n knobs to tune,(nx2) 'knob_boundaries_min' containing the value of the minimum and (n x 1) 'knob_boundaries_max' containing the values of the maximum value allowed for each knob (in the same order as in 'knob_link_ids').
        number_runs=1; % the number of times the algorithm will run before going to the next column if an xls program is run. 
        initialization_method@char % initialization method must be 'normal', 'uniform' or 'manual'.
        maxEval=90; % maximum number of times that beats will run.
        maxIter=30; % maximum number of iterations of the algorithm (can be different in Evolutionnary Algorithms for example).
        stopFValue=1000; % the algorithm will stop if a smaller value is reached by error_calculator (this is the goal).
        xls_program % cell array corresponding to the excel file containing configs in the columns, with the same format as given in the template.
        xls_results@char % address of the excel file containing the results, with a format that fits to the method obj.send_result_to_xls.
        current_xls_program_column=2; % in the xls program, number (not 'B' as in Excel) of the config column currently used.
        
    end
                
    properties (SetAccess = protected)
        
        result_for_xls@cell % result of the algorithm to be outputed to the xls file.
        out % struct with various histories and solutions.
        bestEverErrorFunctionValue % smallest error_calculator value reached during the execution. Extracted from out.
        bestEverPoint % vector of knob values that gave the best (smallest) ever function value.
        numberOfFlops % number of flops for the execution. Probably won't be used as BeatsSimulation is way longer than any other function used here : it is the limiting factor and is uncompressible : the number of times BeatsSimulation was run seems enough to measure time or flops.
        numberOfEvaluations % number of times beats ran a simulation. Extracted from out.
        stopFlag; % reason why the algorithm stopped. Extracted from out.
        convergence % convergence speed.
        
    end
    
    properties (Hidden, SetAccess = protected)
        
        %masks pointing at the links with working sensors used on beats 
        %output or on pems data.
        good_freeway_mask_beats
        good_onramp_mask_beats
        good_offramp_mask_beats
        good_freeway_mask_pems
        good_onramp_mask_pems
        good_offramp_mask_pems
        good_sensor_link_ids % list of the link ids of the working sensors
        current_day=1;
        
    end    
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Construction, loading properties for single run                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    methods (Abstract, Access = public)
        
        [] = ask_for_algorithm_parameters(obj) % ask for the algorithm parameters in the command window.
        
        [] = ask_for_starting_point(obj); % set the starting knob values.
        
        [] = set_starting_point(obj, mode); % set a random starting point. 'mode' should be 'uniform' or 'normal'.
    
    end   
    
    methods (Access= public)    
        
        function [obj] = AlgorithmBox()
            obj.knobs.knob_link_ids=[];
            obj.knobs.knob_boundaries_min = [];
            obj.knobs.knob_boundaries_max = [];
        end % useless constructor.
        
        function [] = run_assistant(obj) % assistant to set all the parameters for a single run in the command window.
            obj.ask_for_beats_simulation;
            obj.ask_for_errorFunction;
            obj.ask_for_pems_data;
            obj.ask_for_knob_link_ids;
            obj.ask_for_knob_boundaries;
            obj.ask_for_algorithm_parameters;
            obj.ask_for_starting_point;
        end
        
        function [] = load_properties_from_xls(obj) % load the properties from an excel file in the format described underneath.
            %properties file : an xls file containing the AlgorithmBox
            %properties in the first column and the corresponding
            %expressions to be evaluated by Matlab in the 'current' column
            %(column 2 for a single run).
            %Empty cells in the current column will be ignored.
            for i=1:size(obj.xls_program,1)
                if ~strcmp(obj.xls_program(i,obj.current_xls_program_column),'')
                    eval(strcat('obj.',char(obj.xls_program(i,1)),'=',char(obj.xls_program(i,obj.current_xls_program_column)),';'));
                end
            end
            obj.set_starting_point(obj.initialization_method);
            obj.set_knob_demand_ids;
        end    
               
        function [] = ask_for_beats_simulation(obj) % ask the user to enter a beats scenario and beats run parameters.
            scenario_ptr = input('Address of the scenario xml file : ', 's');
            obj.beats_simulation = BeatsSimulation;
            obj.beats_simulation.load_scenario(scenario_ptr);
            obj.beats_parameters=input(['Enter a struct containing the beats simulation properties (like struct("DURATION",86000,"SIM_DT",5)) : ']);
        end   
        
        function [] = ask_for_pems_data(obj) % ask the user for the pems info (still not implemented).
            startyear=input(['Enter pems data beginning year (integer) : ']);
            startmonth=input(['Enter pems data beginning month (integer) : ']);
            startday=input(['Enter pems data beginning day (integer) : ']);
            endyear=input(['Enter pems data end year (integer) : ']);
            endmonth=input(['Enter pems data end month (integer) : ']);
            endday=input(['Enter pems data end day (integer) : ']);
            obj.pems.days = (datenum(startyear, startmonth, startday):datenum(endyear, endmonth, endday));
            obj.pems.district = input(['Enter district : ']);
            obj.pems.processed_folder = input(['Enter the adress of the peMS processed folder : '], 's');
            obj.load_pems_data;
        end 
        
        function [] = ask_for_knob_link_ids(obj) % set the ids of the knobs to tune in the command window.
            if (size(obj.beats_simulation)~=0)
                demand2link=obj.beats_simulation.scenario_ptr.get_demandprofile_link_map;
                bad_onramps=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('on-ramp');
                bad_onramps=bad_onramps(~ismember(bad_onramps,obj.good_sensor_link_ids));
                bad_onramps=demand2link(ismember(demand2link(:,2),bad_onramps),:);
                bad_offramps=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('off-ramp');
                bad_offramps=bad_offramps(~ismember(bad_offramps,obj.good_sensor_link_ids));
                bad_offramps=demand2link(ismember(demand2link(:,2), bad_offramps),:);
                numberOfKnobs=size(bad_onramps,1)+size(bad_offramps,1);
                numberMissingKnobs = input(strcat(['Among the ', num2str(numberOfKnobs), ' on and off ramps whithout sensors, how many knobs have to be tuned ? :']));
                disp(['List of on-ramps whithout working sensor demand ids and corresponding link ids : ']);
                disp(bad_onramps);
                disp(bad_onramps(:,2));
                disp(['List of off-ramps whithout working sensor demand ids and corresponding link ids : ']);
                disp(bad_offramps);
                disp(bad_offramps(:,2));
                disp('You can directly select and copy-paste several at a time from the second lists with only link ids.');
                for i=1:numberMissingKnobs
                    obj.knobs.knob_link_ids(i,1)=input(strcat(['knob ', num2str(i),' link id :']));
                end
                obj.set_knob_demand_ids;
            else
                error('No Beats Simulation loaded');
            end    
        end
        
        function [] = ask_for_knob_boundaries(obj) % set the knob boundaries (in the same order as the knob ids) in the command window.
            if (isfield(obj.knobs, 'knob_link_ids'))
                for i=1:size(obj.knobs.knob_link_ids,1)
                    obj.knobs.knob_boundaries_min(i,1)=input(['Knob ', num2str(obj.knobs.knob_link_ids(i,1)), ' minimum value : ']);
                    obj.knobs.knob_boundaries_max(i,1)=input(['Knob ', num2str(obj.knobs.knob_link_ids(i,1)), ' maximum value : ']);
                end
            else
                error('The knobs to tune ids : obj.knobs.knob_link_ids has to be set first.');
            end    
        end    
               
        function [] = ask_for_errorFunction (obj) % set the performance calculator and error calculator in the command window.
            obj.performance_calculator=input(['Enter the name of a "PerformanceCalculator" subclass (like TVM) : ']);
            obj.error_calculator=input(['Enter the name of an "ErrorCalculator" subclass (like L1) : ']);
        end
          
    end
    
    methods (Access = private)
        
        function [] = load_pems_data(obj)
            obj.pems.peMS5minData= PeMS5minData;
            obj.set_masks_and_flow;
            obj.performance_calculator.calculate_from_pems(obj.pems,obj.good_freeway_mask_pems);        
            disp('PeMS data loaded');
        end
        
    end    
            
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Loading program instead of single run and printing results to xls  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Abstract, Access = public)
         
        [] = set_result_for_xls(obj); % sets results_for_xls after the algorithm has run.
         
    end    
    
    methods (Access = public)
        
        function [] = ask_for_xls(obj)
             % ask the user for the adress of the input and output Excel files.
            program=input(['Enter the address of the Excel program file : '], 's');
            results=input(['Enter the address of the Excel results file : '], 's');
            obj.load_xls(program,results);

        end
        
        function [] = load_xls(obj, xls_program_adress, xls_results_adress)
            % loads the input Excel file and sets the adress of the output.
            if ~exist('xls_results_adress','var')
                xls_results_adress='';
            end
            [useless,obj.xls_program,useless] = xlsread(xls_program_adress);
            obj.xls_results=xls_results_adress;
            obj.beats_simulation = BeatsSimulation;
            obj.load_properties_from_xls;
            obj.load_pems_data;
        end 
        
    end
    
    methods (Access = private)
    
       function [] = send_result_to_xls(obj, filename)
            %the legend in the xls file should be written manually.
            %the counter for current cell should be in cell AZ1.
            [useless1,useless2,xls]=xlsread(filename, obj.algorithm_name);
            id=xls{1,52};
            xlswrite(filename,id,obj.algorithm_name, strcat('A',num2str(id+1)));
            xlswrite(filename, obj.result_for_xls, obj.algorithm_name, strcat('B',num2str(id+1)));
            xlswrite(filename, id+1,obj.algorithm_name,'AZ1');
        end  % send result of an execution of the algorithm to the output Excel file.
        
    end    
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Running algorithm and program                                      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Abstract, Access = public)
        
        [] = run_algorithm(obj) % single run of the algorithm.
    
    end    
    
    methods (Access = public)
        
        function [result] = errorFunction(obj, knob_values) % the error function used by the algorithm. Compares the beats simulation result and pems data.
            %knob_values : n x 1 array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            disp('Knobs vector tested');
            disp(knob_values);
            if (size(knob_values,1)==size(obj.knobs.knob_link_ids,1))
              obj.beats_simulation.scenario_ptr.set_knob_values(obj.knobs.knob_demand_ids, knob_values)
              obj.beats_simulation.run_beats(obj.beats_parameters);
              obj.performance_calculator.calculate_from_beats(obj.beats_simulation, obj.good_freeway_mask_beats);
              result = obj.error_calculator.calculate(obj.performance_calculator.result_from_beats, obj.performance_calculator.result_from_pems);
            else
                error('The matrix with knobs values given does not match the number of knobs to tune or is not a column array.');
            end    
        end
        
        function [] = run_program(obj, firstColumn, lastColumn)
            %run the program set in the program Excel file and print the
            %results in the results Excel file.
            obj.current_xls_program_column=firstColumn;
            while (obj.current_xls_program_column<=lastColumn)
                disp(strcat(['PROGRAM COLUMN ', num2str(obj.current_xls_program_column)]));
                obj.load_properties_from_xls;
                counter=obj.number_runs;          
                while (counter > 0)
                    disp([num2str(counter), ' RUNS REMAINING FOR THESE SETTINGS']);
                    obj.run_algorithm;
                    obj.set_result_for_xls;
                    obj.send_result_to_xls(obj.xls_results);
                    counter=counter-1;
                end
                obj.current_xls_program_column=obj.current_xls_program_column+1; 
           end    
        end % run the program defined by the input Excel file and write its results in the output Excel file.        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Utilities                                                          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    methods (Access = protected)
        
        function [bool] = is_set_knobs(obj) %check if the knobs struct is set.

            bool = 0;
            if (size(obj.knobs.knob_link_ids,2)~=0 && size(obj.knobs.knob_boundaries_max,2)~=0 && size(obj.knobs.knob_boundaries_min,2)~=0 && size(obj.knobs.knob_demand_ids,2)~=0)
                bool=1;
            end    
        end 
        
        function [] = set_masks_and_flow(obj)
            %sets the masks for further link selection and smoothens flow 
            %values.
            link_ids = obj.beats_simulation.scenario_ptr.get_link_ids;
            sensor_link = obj.beats_simulation.scenario_ptr.get_sensor_link_map;
            vds2id = obj.beats_simulation.scenario_ptr.get_sensor_vds2id_map;
            obj.pems.peMS5minData.load(obj.pems.processed_folder,  vds2id(:,1), obj.pems.days);
            obj.pems.flow_measurements=obj.pems.peMS5minData.get_data_batch_aggregate(vds2id(:,1), obj.pems.days(obj.current_day), 'smooth', true).flw;
            is_good_sensor_mask_pems = all(~isnan(obj.pems.flow_measurements), 1);
            good_sensor_ids=vds2id(is_good_sensor_mask_pems,2);
            good_sensor_link_ids=sensor_link(ismember(sensor_link(:,1), good_sensor_ids),2);
            freeway_link_ids=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('freeway');
            onramp_link_ids=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('on-ramp');
            offramp_link_ids=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('off-ramp');
            freeway_mask_beats=ismember(link_ids, freeway_link_ids);
            onramp_mask_beats=ismember(link_ids, onramp_link_ids);
            offramp_mask_beats=ismember(link_ids, offramp_link_ids);
            freeway_mask_pems=reshape(ismember(sensor_link(:,2), freeway_link_ids),1,[]);
            onramp_mask_pems=reshape(ismember(sensor_link(:,2), onramp_link_ids),1,[]);
            offramp_mask_pems=reshape(ismember(sensor_link(:,2), offramp_link_ids),1,[]);
            is_good_sensor_mask_beats=ismember(link_ids, good_sensor_link_ids);
            obj.good_freeway_mask_beats=logical(is_good_sensor_mask_beats.*freeway_mask_beats);
            obj.good_onramp_mask_beats=logical(is_good_sensor_mask_beats.*onramp_mask_beats);
            obj.good_offramp_mask_beats=logical(is_good_sensor_mask_beats.*offramp_mask_beats);
            obj.good_freeway_mask_pems=logical(is_good_sensor_mask_pems.*freeway_mask_pems);
            obj.good_onramp_mask_pems=logical(is_good_sensor_mask_pems.*onramp_mask_pems);
            obj.good_offramp_mask_pems=logical(is_good_sensor_mask_pems.*offramp_mask_pems);
            obj.good_sensor_link_ids=good_sensor_link_ids;
            
        end    %sets the masks for further link selection and smoothens flow values.
        
        function [] = set_knob_demand_ids(obj) 
            %sets obj.knobs.knob_demand_ids, which is the list of the 
            %demandprofile ids corresponding to the link ids of the knobs.
            demand2link = obj.beats_simulation.scenario_ptr.get_demandprofile_link_map;
            obj.knobs.knob_demand_ids=demand2link(ismember(demand2link(:,2),obj.knobs.knob_link_ids),1);
        end   %described in the body       

    end
 
end    


