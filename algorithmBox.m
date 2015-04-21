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
        knobs=struct; % struct with three array fields : (nx1) 'knob_ids' containing the ids of the n knobs to tune,(nx2) 'knob_boundaries_min' containing the value of the minimum and (n x 1) 'knob_boundaries_max' containing the values of the maximum value allowed for each knob (in the same order as in 'knob_ids').
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
    
    properties (Hidden)
        
        mainline_links_with_good_sensors_mask
        
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
            obj.knobs.knob_ids=[];
            obj.knobs.knob_boundaries_min = [];
            obj.knobs.knob_boundaries_max = [];
        end % useless constructor.
        
        function [] = run_assistant(obj) % assistant to set all the parameters for a single run in the command window.
            obj.ask_for_beats_simulation;
            obj.ask_for_pems_scenario;
            obj.ask_for_knob_ids;
            obj.ask_for_knob_boundaries;
            obj.ask_for_errorFunction;
            obj.ask_for_algorithm_parameters;
            obj.ask_for_starting_point;
        end
        
        function [] = load_properties_from_xls(obj) % load the properties from an excel file in the format described underneath.
            %properties file : an xls file containing the AlgorithmBox
            %properties in the first column and the corresponding
            %expressions to be evaluated by Matlab in the 'current' column
            %(column 2 for a single run).
            %Empty cells in the current column will be ignored.
            xls= obj.xls_program;
            for i=1:size(xls,1)
                if ~strcmp(xls(i,obj.current_xls_program_column),'')
                    eval(strcat('obj.',char(xls(i,1)),'=',char(xls(i,obj.current_xls_program_column)),';'));
                end
            end
            obj.set_starting_point(obj.initialization_method);
        end    
               
        function [] = ask_for_beats_simulation(obj) % ask the user to enter a beats scenario and beats run parameters.
            scenario_ptr = input('Address of the scenario xml file : ', 's');
            obj.beats_simulation = BeatsSimulation;
            obj.beats_simulation.load_scenario(scenario_ptr);
            obj.beats_parameters=input(['Enter a struct containing the beats simulation properties (like struct("DURATION",86000,"SIM_DT",5)) : ']);
        end   
        
        function [] = ask_for_pems_data(obj) % ask the user for the pems info (still not implemented).
            
        end 
        
        function [] = ask_for_knob_ids(obj) % set the ids of the knobs to tune in the command window.
            if (size(obj.beats_simulation)~=0)
                numberMissingKnobs = input(strcat(['Among the', ' ', num2str(length(obj.beats_simulation.scenario_ptr.scenario.DemandSet.demandProfile)), ' knobs, how many have to be tuned ? :']));
                for i=1:numberMissingKnobs
                    obj.knobs.knob_ids(i,1)=input(strcat(['knob ', num2str(i),' id :']));
                end
            else
                error('No Beats Simulation loaded');
            end    
        end
        
        function [] = ask_for_knob_boundaries(obj) % set the knob boundaries (in the same order as the knob ids) in the command window.
            if (isfield(obj.knobs, 'knob_ids'))
                for i=1:size(obj.knobs.knob_ids,1)
                    obj.knobs.knob_boundaries_min(i,1)=input(['Knob ', num2str(obj.knobs.knob_ids(i,1)), ' minimum value : ']);
                    obj.knobs.knob_boundaries_max(i,1)=input(['Knob ', num2str(obj.knobs.knob_ids(i,1)), ' maximum value : ']);
                end
            else
                error('The knobs to tune ids : obj.knobs.knob_ids has to be set first.');
            end    
        end    
               
        function [] = ask_for_errorFunction (obj) % set the performance calculator and error calculator in the command window.
            obj.performance_calculator=input(['Enter the name of a "PerformanceCalculator" subclass (like TVM) : ']);
            obj.error_calculator=input(['Enter the name of an "ErrorCalculator" subclass (like L1) : ']);
        end
        
        function [] = load_pems_data(obj)
            obj.pems.peMS5minData= PeMS5minData;
            vds2id = obj.beats_simulation.scenario_ptr.get_sensor_vds2id_map;
            obj.pems.peMS5minData.load(obj.pems.processed_folder,  vds2id(:,1), obj.pems.days);
            X=obj.pems.peMS5minData.get_data_batch_aggregate(vds2id(:,1), obj.pems.days(1), 'smooth', true);
            is_bad_detector = all(isnan(X.flw), 1);
            good_sensors = vds2id(~is_bad_detector, :);
            flw = X.flw(:, ~is_bad_detector);
            link_ids = obj.beats_simulation.scenario_ptr.get_link_ids;
            link_types = obj.beats_simulation.scenario_ptr.get_link_types;
            sensor_link = obj.beats_simulation.scenario_ptr.get_sensor_link_map;
            links_with_good_sensors_mask=ismember(link_ids, sensor_link(ismember(sensor_link(:,1),good_sensors(:,2)),2));
            for i=1:size(link_types,2)
                if strcmp(link_types(1,i),'Freeway')
                    mainline_links_mask(1,i)=1;
                else mainline_links_mask(1,i)=0;
                end    
            end
            obj.mainline_links_with_good_sensors_mask=links_with_good_sensors_mask.*mainline_links_mask;
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
            program=input(['Enter the address of the Excel program file : '], 's');
            results=input(['Enter the address of the Excel results file : '], 's');
            obj.load_xls(program,results);

        end % ask the user for the adress of the input and output Excel files.
        
        function [] = load_xls(obj, xls_program_adress, xls_results_adress)  % loads the input Excel file and sets the adress of the output.
            if ~exist('xls_results_adress','var')
                xls_results_adress='';
            end
            [useless,xls,useless] = xlsread(xls_program_adress);
            obj.xls_program=xls;
            obj.xls_results=xls_results_adress;
            obj.beats_simulation = BeatsSimulation;
            obj.load_properties_from_xls;
        end 

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
    
    methods (Access = public)
        
        function [result] = errorFunction(obj, knob_values) % the error function used by the algorithm. Compares the beats simulation result and pems data.
            %knob_values : n x 1 array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            knob_values=reshape(knob_values,2,1);
            disp(knob_values);
            if (size(knob_values,1)==size(obj.knobs.knob_ids,1))
              obj.beats_simulation.scenario_ptr.set_knob_values(obj.knobs.knob_ids, knob_values)
              obj.beats_simulation.run_beats(obj.beats_parameters);
              obj.performance_calculator.calculate_from_beats(obj.beats_simulation);
              obj.performance_calculator.calculate_from_pems(obj.pems);
              result = obj.error_calculator.calculate(obj.performance_calculator.result_from_beats, obj.performance_calculator.result_from_pems);
            else
                error('The matrix with knobs values given does not match the number of knobs to tune.');
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
        
         function [mainline_links_with_sensors_mask] = get_mainline_sensors_mask(obj)
            link_ids = obj.beats_simulation.scenario_ptr.get_link_ids;
            link_types = obj.beats_simulation.scenario_ptr.get_link_types;
            sensor_link = obj.beats_simulation.scenario_ptr.get_sensor_link_map;
            mainline_links_with_sensors_mask = ismember(link_ids,sensor_link(:,2));
            for i=1:length(mainline_links_with_sensors_mask)
                if ~strcmp(link_types(i),'Freeway')
                    mainline_links_with_sensors_mask(i)=0;
                end    
            end    
         end
         
        
    end
    
    methods (Abstract, Access = public)
        
        [] = run_algorithm(obj) % single run of the algorithm.
    
    end    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Utilities                                                          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    methods (Access = protected)
        
        function [bool] = is_set_knobs(obj)
            bool = 0;
            if (size(obj.knobs.knob_ids,2)~=0 && size(obj.knobs.knob_boundaries_max,2)~=0 && size(obj.knobs.knob_boundaries_min,2)~=0)
                bool=1;
            end    
        end  %check if the knobs struct is set.
        


    end
 
    
    

end    


