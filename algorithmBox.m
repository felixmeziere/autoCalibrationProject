classdef (Abstract) AlgorithmBox < handle
    %AlgorithmBox : used by any algorithm.
    %   Contains the properties and methods that are used by any algorithm for
    %   the automatic calibration problem (for now, tuning only unmonitored source and
    %   sink knobs). This allows you to run a program set in an excel
    %   file and automatically registers the results in : another excel file,
    %   an accelerated movie and all the variables and plots containing info 
    %   on the algorithm progress.
    
    %The object oriented programming paradigms are not respected : most of
    %objects' constructors use this class (AlgorithmBox) as only argument
    %and AlgorithmBox can access many of their properties, so they are not 
    %independent at all. I have used objects mainly as a way of splitting 
    %the code in many files instead of having a big messy file. The objects
    %should be seen as a way of grouping the properties and methods used 
    %for a common purpose.
    
    %These objects are : BeatsSimulation, PeMS5mindata, PemsData, 
    %ErrorFunction, PerformanceCalculator, Knobs, Norm. 
    
    %The only implementation of AlgorithmBox coded at this day is CmaesBox,
    %inheriting from EvolutionnaryAlgorithmBox < AlgorithmBox.
    
    %There are two ways of setting up a scenario for calibration. One is
    %using the assistant, which will ask succesively each parameter in the
    %Matlab command window, to run the algorithm once. This can be seen as
    %a tutorial to understand everything that comes into play in this
    %calibration.
    %The other way is using an xls(x) file that will load automatically all
    %the parameters. This will allow to use the AlgorithmBox.run_program
    %method that executes several consecutive times the algorithm with 
    %different parameters (each column of the xls file is one set of 
    %parameters). The parameters in the xls file are entered in a way such
    %that eval(obj.'parameter in excel first column'='value in excel
    %current column') works.
        
    %It is easy to implement a new algorithm with this code or to study
    %different days and their average. Using this code with a freeway that 
    %is not 210E shoudln't cause any problem, if the scenario and PeMS data 
    %have been generated the exact same way as they were given to me for 210E. 
    %(Gabriel's script).
    %However, studying durations different than one day with a 5 minutes 
    %time step WILL require debuging.
    
    %Required for loading from xls :
    
    %    -> scenario_ptr | ['adress of the xml scenario file']
    %    -> number_runs | [integer]
    %    -> maxEval | [integer]
    %    -> stopFValue | [real number]
    %    -> beats_parameters.DURATION | [integer]
    %       Should be 86400.
    %    -> beats_parameters.OUTPUT_DT | [integer]
    %       Should be 300.
    %    -> beats_parameters.SIM_DT | [integer]
    %       Should be 4.
    %    -> additive_uncertainty | [double]
    %       e.g.: 0.05 for +-5%. DEFAULT : 0.1
    %    -> multiplicative_uncertainty | [double]
    %       e.g.: 0.75 for *(1+-75%). DEFAULT : 0.5
    %    -> is_uncertainty_for_monitored_ramps | [0] or [1] DEFAULT:0
    %    -> monitored_source_sink_uncertainty | [fraction of one]
    %    -> starting_point | [knob#1value;knob#2value;...;knob#nvalue]
    %       To use only if obj.initialization_method is 'manual'.
    %       Discouraged.
    %    -> multiple_sensor_vds_to_use | [vds#1,vds#2,...,vds#p]
    %    -> vds_sensors_to_delete | [vds#1,vds#2,...,vds#k]



    
    properties (Abstract, Constant)
        
        algorithm_name %name of the algorithm in the subclass, used sometimes. Example: cmaes
        algorithm_type %type of the algorithm. Example: evolutionnary
        
    end    
    
    properties (Abstract, Access = public)
        
        starting_point %starting vector or matrix. If the starting point is a matrix (e.g. if it is a population for an evolutionnary algorithm), the columns are vectors (individuals) and the rows are knobs.
        
    end    
    
    properties (Access = public)
        
        %manually modificable properties...................................
        number_runs=1; % the number of times the algorithm will run with the current parameters (before going to the next column if an xls program is running). 
        maxEval=1000; % maximum number of times that beats will run.
        stopFValue=0; % the algorithm will stop if a smaller value is reached by error_calculator.
        current_xls_program_column=2; % in the xls program, number of the config column currently used (2 is B in excel for example).
        
    end
                
    properties (SetAccess = protected)
        
        %visible input properties..........................................
        beats_parameters=struct; % struct containing the parameters passed to BeatsSimulation (BeatsSimulation.create_beats_object(obj.beats_parameters)).
        beats_simulation@BeatsSimulation % the BeatsSimulation object that will run, output results and be overwritten at each algorithm iteration.
        pems@PeMSData % the pems data to compare with the beats results. Input fields : 'mainline_uncertainty' (of the mainline sensors. e.g.:0.1), 'days' (e.g. datenum(2014,10,1):datenum(2014,10,10)); 'district' (e.g. 7); 'processed_folder'(e.g. C:\Code\pems\processed). Output Fields : 'data'. 
        error_function@ErrorFunction % instance of ErrorFunction class, containing all the properties and methods to compute the difference between pems and beats output (this computes the fitness function to minimize).
        initialization_method@char % initialization method must be 'normal', 'uniform' or 'manual'.
        TVM_reference_values=struct; %TVM values from pems and beats with all knobs set to one. Used to project the beats knobs input in the correct TVM subspace.
        knobs@Knobs % Knobs class instance with all the properties and methods relative to the knobs of the scenario.
        current_day=1; %current day used in the pems data loaded.
        additive_uncertainty=0.1; %additive local uncertainty corresponding mainly to the uncertainty on the mainline sensors (previously "pems.mainlune_uncertainty"). e.g. additive_uncertainty=0.1;
        multiplicative_uncertainty=0.25; %multiplicative local uncertainty setting the freedom given to the knobs (previously knobs.under/overevaluation_tolerance_coefficients). e.g. multiplicative_uncertainty=0.5. For single-knob groups : (1-multiplicative_uncertainty).perfectValue < knob < (1+multiplicative_uncertainty).perfectValue
        monitored_source_sink_uncertainty=0; %uncertainty used only if the "search knobs also on the monitored ramps" swithc is on (i.e. obj.is_uncertainty_for_monitored_ramps==1). This will set the boundaries for the monitored ramp knobs.
                                    
        %visible output properties.........................................
        out % struct with various histories and solutions.
        bestEverErrorFunctionValue % smallest error_function value reached during the execution. Extracted from out.
        bestEverPoint % vector of knob values that gave the best (smallest) ever function value.
        numberOfIterations=1; % number of iterations of the algorithm (different than the number of evaluations for evolutionnary algorithms for example).
        numberOfEvaluations=1; % number of times beats ran a simulation. Extracted from out.
        stopFlag; % reason why the algorithm stopped. Extracted from out.
        
    end
    
    properties (Hidden, Access = public)
        
        settings=struct; %Struct with several settings for the error function.
        
    end    
    
    properties (Hidden, SetAccess = protected)
        
        %loading properties...............................................
        scenario_ptr=''; % adress of the beats scenario xml file.
        freeway_name=''; %the name of the freeway extracted from the name of the scenario file.
        xls_results@char % address of the excel file containing the results, with a format that is in accordance with the method obj.send_result_to_xls.
        xls_program % cell array containing the excel file to load and set up the algorithm.
        beats_loaded=0; % flag to indicate if the beats simulation and parameters have been correctly loaded.
        masks_loaded=0; % flag to indicate if the masks and reference values have been correctly loaded.
        is_loaded=0; %flag to indicate if the algorithm is ready to run.
        dated_name %name that will have this execution's reports.
        currently_loading_from_xls=0; %flag to indicate if the object is being loaded
        is_uncertainty_for_monitored_ramps=0; %switch to indicate if all the monitored ramps (and mainline source) should be made knobs. The boundaries will be +-...pems.monitored_source_sink_uncertainty (this adds a lot of knobs and makes the algorithm converge way slower).

        
        result_for_xls@cell % result of the algorithm to be outputed to the xls file.

        
        %masks pointing at the links with working sensors used on beats 
        %output or on pems data. The order of the links is therefore not 
        %linear.........................................................
        mainline_mask_beats %mainline link ids in beats scenario format and order.
        good_mainline_mask_beats %monitored mainline links.
        source_mask_beats %all source links (mainline source included).
        good_source_mask_beats %monitored source links.
        sink_mask_beats %all sink links (mainline sink included).
        good_sink_mask_beats %monitored sink links.
        good_sensor_mask_beats %all monitored links.
        mainline_mask_pems %same in pems format and order.
        good_mainline_mask_pems
        source_mask_pems
        good_source_mask_pems
        sink_mask_pems
        good_sink_mask_pems
        good_sensor_mask_pems
        
        %properties with infos on the scenario.............................
        multiple_sensor_index2vds2id2link % vds2id2link of the sensors which are on links with at least two sensors
        multiple_sensor_vds_to_use=0; % tuple containing the vds of the sensors to keep in the precedent situation. Order or grouping is not important. If multiple vds for one link in this property, it means that their flow and dty_veh value will be summed and their speeds will be averaged.
        vds_sensors_to_delete=0; %tuple with sensors to delete. Useful to solve partial data issues.
        sensor_link %array with sensor ids in the left column and corresponding link ids in the second one.
        link_ids_beats % all the link ids of the scenario in the scenario (non-linear) order.
        linear_link_ids % all link ids, in linear order.

    end    
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Construction, loading properties manually with assistant           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    methods (Abstract, Access = public)
        
        [] = ask_for_algorithm_parameters(obj) % ask for the algorithm parameters in the command window.
        
        [] = ask_for_starting_point(obj); % set the starting knob values. Can be different for each type of algorithm.
            
    end   
    
    methods (Access=protected)
        
        [] = set_starting_point(obj, mode); % set a random starting point with some distribution.
    
    end    
    
    methods (Access= public)    
       
        %create object....................................................
        function [obj] = AlgorithmBox() %constructor that changes the working folder for further use by certain methods.
            [name,~,~]=fileparts(mfilename('fullpath'));
            cd(name);   
        end 

        %load for single run from initial loading assistant and its 
        %standalone dependencies (command window)..........................
        function [] = run_assistant(obj) % assistant to set all the parameters for a single run in the command window. 
            %Uses all the standalone command window methods underneath.
            obj.currently_loading_from_xls=0;
            obj.ask_for_beats_simulation;
            obj.ask_for_pems_data;
            obj.ask_for_vds_sensors_to_delete;
            obj.ask_for_solving_multiple_sensors_conflicts;
            obj.ask_for_knobs;
            obj.ask_for_errorFunction;
            obj.ask_for_algorithm_parameters;
            disp('ALL SETTINGS LOADED, ALGORITHM READY TO RUN');
        end

        function [] = ask_for_beats_simulation(obj) % ask the user to enter a beats scenario and beats run parameters.
            scptr= input(['Address of the scenario xml file : '], 's');
            obj.scenario_ptr=scptr;
            obj.beats_parameters=input(['Enter a struct containing the beats simulation properties (like struct("DURATION",86400,"SIM_DT",4,"OUTPUT_DT",300)) : ']);
            obj.load_beats;
        end   
        
        function [] = ask_for_pems_data(obj) % ask the user for the pems data parameters.
            obj.pems=PeMSData(obj);
            obj.pems.run_assistant;
            obj.ask_for_current_day;
            obj.set_masks_and_reference_values;
        end 
        
        function [] = ask_for_knobs(obj) % set the ids of the knobs to tune in the command window.
            obj.knobs=Knobs(obj);
            obj.knobs.run_assistant;
        end
        
        function [] = ask_for_knob_boundaries(obj) % set the knob boundaries (in the same order as the knob ids) in the command window.
            obj.knobs.ask_for_knob_boundaries;
        end    
               
        function [] = ask_for_errorFunction(obj) % set up the error function in the command window.
           obj.error_function=ErrorFunction(obj);
        end
        
        function [] = ask_for_current_day(obj)
             obj.current_day=input(['Enter the position of the day to study among all the days entered (e.g. 3, last day +1 is average of all days) : ']);
             if size(obj.knobs,1)~=0
                 obj.knobs.set_auto_knob_boundaries;
                 if obj.knobs.current_value~=ones(obj.knobs.nKnobs,1)
                     obj.set_masks_and_reference_values;
                 end
             end
        end % set position of current day studied in the pems data array. Last day+1 is average of all days.
        
        function [] = ask_for_solving_multiple_sensors_conflicts(obj)
            if (size(obj.multiple_sensor_index2vds2id2link,1)>0)
                disp('Several sensor on the same link conflicts:');
                disp('Below is the list of conflictual links with the info on their sensors. There is a method to plot these conflicts.');
                disp(' PeMS column:       VDS: Sensor id :    Link id:   ');
                disp(obj.multiple_sensor_index2vds2id2link);
                nsensors=input(['Among the ',num2str(size(obj.multiple_sensor_index2vds2id2link,1)), ' conflictual sensors, how many do you want to keep ? (if on the same link, flows will be summed, non-zero speeds and densities will be averaged) : ']);
                obj.multiple_sensor_vds_to_use=[];
                for i=1:nsensors
                    obj.multiple_sensor_vds_to_use(i)=input(['VDS of sensor number ',num2str(i),' : ']);
                end
                obj.solve_multiple_sensor_link_conflicts;
            end    
        end  % Ask for sensors to delete or sum when there are two sensors on the same link (command window).
        
        function [] = ask_for_vds_sensors_to_delete(obj)
            ndelete=input(['How many sensors would you like to delete (Useful to solve incomplete data issues) : ']);
            obj.vds_sensors_to_delete=[];
            for i=1:ndelete
                obj.vds_sensors_to_delete(i)=input(['VDS of sensor number ',num2str(i),' : ']);
            end    
            obj.delete_chosen_sensors;
        end  % Ask for sensors to delete. This will possibly create new knobs or knob groups. Useful to solve the problem of partial/biased data (command window). 
        
        function [] = ask_for_changing_congestionPattern_rectangles_if_exist(obj)
            cp=obj.error_function.find_performance_calculator('CongestionPattern');
            obj.error_function.performance_calculators{cp}=CongestionPattern(obj);
        end % Change the congestion pattern rectangles manually by the operator (command window).   

    end    
            
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Loading program instead of single run and printing results to xls  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Abstract, Access = public)
         
        [] = set_result_for_xls(obj); % sets result_for_xls after the algorithm has run. This array is sent to the results excel file for record.
         
    end    
    
    methods (Access = public)

        function [] = ask_for_xls(obj)  % ask the user for the adress of the input and output Excel files.
            program=input(['Enter the address of the Excel program file : '], 's');
            results=input(['Enter the address of the Excel results file : '], 's');
            obj.load_xls(program,results);
        end

        function [] = load_xls(obj, xls_program_adress, xls_results_adress) % loads the input Excel file, sets up the algorithm to be ready-to-run and sets the adress of the output xls file.
            % The properties in the excel file should be in the format described underneath.
            %properties file : an xls file containing the AlgorithmBox
            %properties to set in the first column and the corresponding
            %expressions to be evaluated by Matlab in the 'current' column
            %(column 2 for a single run).
            %Empty cells in the current column will be ignored.
            %Comments in each class file explain which properties should be present
            %in the xls file.
            obj.is_loaded=0;
            if ~exist('xls_results_adress','var')
                xls_results_adress='';
                warning('RESULTS WILL NOT BE RECORDED IN XLS FILE.');
            end
            [~,obj.xls_program,~] = xlsread(xls_program_adress);
            obj.xls_results=xls_results_adress;            
            obj.load_properties_from_xls;
        end
    
        function [] = send_result_to_xls(obj, filename) % When algorithm has finished, sends several data on the execution of the algorithm (obj.result_for_xls) to the output Excel file.
            %the legend in the xls file should be written manually.
            %the counter for current cell should be in cell A2.
            if (nargin<2)
                filename=obj.xls_results;
            end    
            obj.set_result_for_xls;
            [~,~,xls]=xlsread(filename, obj.algorithm_name);
            id=xls{2,1};
            to_send=[{id,obj.dated_name},obj.result_for_xls];
            xlswrite(filename,to_send,obj.algorithm_name, strcat('B',num2str(id+1)));
            xlswrite(filename, id+1,obj.algorithm_name,'A2');
            disp('RESULTS OF THE RUN SENT TO XLS FILE :');
            disp(filename);
        end  
        
    end    

    methods (Access = protected)

        %private used by load_xls.........................................
        function [] = load_properties_from_xls(obj) 
                obj.currently_loading_from_xls=1;
                obj.pems=PeMSData(obj);
                obj.knobs=Knobs(obj);
                for i=1:size(obj.xls_program,1)
                    if ~strcmp(obj.xls_program(i,obj.current_xls_program_column),'')
                        eval(strcat('obj.',char(obj.xls_program(i,1)),'=',char(obj.xls_program(i,obj.current_xls_program_column)),';'));
                    end
                end
                obj.load_beats;
                obj.pems.load;
                obj.set_masks_and_reference_values;
                obj.delete_chosen_sensors;
                obj.solve_multiple_sensor_link_conflicts;
                obj.knobs.set_demand_ids;
                obj.knobs.current_value=ones(obj.knobs.nKnobs);
                obj.link_ids_beats=obj.beats_simulation.scenario_ptr.get_link_ids;      
                if (obj.knobs.force_manual_knob_boundaries==0)
                    obj.knobs.set_auto_knob_boundaries(obj.knobs.isnaive_boundaries);
                end   
                obj.knobs.is_loaded=1;
                obj.set_starting_point(obj.initialization_method);
                obj.error_function=ErrorFunction(obj);
                obj.is_loaded=1;
                obj.currently_loading_from_xls=0;
                obj.currently_loading_from_xls=0;
                disp('ALL SETTINGS LOADED, ALGORITHM READY TO RUN');    
        end

    end
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Running algorithm and program                                      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Abstract, Access = public)
        
        [] = run_algorithm(obj) % Manually run the algorithm once (used also by the method which runs the algorithm several times in a row : obj.run_program()).
    
    end    
    
    methods (Access = public)
        
%         function [error_in_percentage] = evaluate_error_function(obj, knob_values, isZeroToTenScale) % the error function evaluated by the algorithm at each iteration. Repairs the knobs, compares the beats simulation output and pems data and plots the result.
%             knob_values : n x 1 array where n is the number of knobs
%             to tune, containing the new values of the knobs.
%             format SHORTG;
%             format LONGG;
%             if (size(knob_values,1)==obj.knobs.nKnobs || size(knob_values,1)==obj.knobs.nKnobs+size(obj.knobs.monitored_ramp_link_ids,1))   
%                 if exist('isZeroToTenScale','var') && isZeroToTenScale==1
%                     knob_values=obj.knobs.rescale_knobs(knob_values,0);
%                 end
%                 if ~obj.knobs.isnaive_boundaries
%                     knob_values=obj.knobs.project_involved_knob_groups_on_correct_flow_subspace(knob_values);
%                 end
%                 knob_values=obj.project_on_correct_TVM_subspace(knob_values);
%                 zeroten_knob_values=obj.knobs.rescale_knobs(knob_values,1);
%                 disp(['Knobs vector and values being tested for evaluation # ',num2str(obj.numberOfEvaluations),' :']);
%                 disp(' ');
%                 disp(['               Demand Id :','                 Link Id :','                                    Value, min and max:','           Value on a scale from 0 to 10:']);
%                 disp(' ');
%                 disp([obj.knobs.demand_ids,obj.knobs.link_ids, knob_values(1:obj.knobs.nKnobs,1),obj.knobs.boundaries_min,obj.knobs.boundaries_max,zeroten_knob_values(1:obj.knobs.nKnobs,1)]);
%                 obj.beats_simulation.beats.reset();
%                 obj.knobs.set_knobs_persistent(knob_values);
%                 obj.beats_simulation.run_beats_persistent;
%                 obj.error_function.calculate_pc_from_beats; 
%                 [err,error_in_percentage] = obj.error_function.calculate_error;
%                 disp(['Total error in percentage value : ', num2str(error_in_percentage)]);
%                 disp('CONTRIBUTIONS : ')
%                 for i=1:size(obj.error_function.performance_calculators,2)
%                     disp([obj.error_function.performance_calculators{i}.name,' : ']);
%                     disp(['         contribution in total error in percentage : ', num2str(obj.error_function.contributions_in_percentage(i))]);
%                     disp(['         actual error in percentage : ', num2str(obj.error_function.errors_in_percentage(i))])
%                     disp(['         actual error value : ',num2str(obj.error_function.errors(i))]);
%                 end              
%                 obj.save_congestionPattern_matrix;
%                 obj.knobs.plot_zeroten_knobs_history(1);
%                 obj.error_function.plot_complete(2);
%                 obj.error_function.plot_all_performance_calculators(5);
%                 obj.plot_performance_calculator_if_exists('CongestionPattern');
%                 drawnow;
%                 obj.numberOfEvaluations=obj.numberOfEvaluations+1;
%             else
%                 error('The matrix with knobs values given does not match the number of knobs to tune or is not a column vector.');
%             end    
%         end

    function [errors_in_percentage] = evaluate_error_function(obj, knobs_values, isZeroToTenScale) % the error function evaluated by the algorithm at each iteration. Repairs the knobs, compares the beats simulation output and pems data and plots the result.
            %knob_values : n x obj.population_size array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            format SHORTG;
            format LONGG;
%             numEval=obj.numberOfEvaluations;
        parfor p=1:1
            knob_values=knobs_values(:,p);
            if (size(knob_values,1)==obj.knobs.nKnobs || size(knob_values,1)==obj.knobs.nKnobs+size(obj.knobs.monitored_ramp_link_ids,1))   
%                 if exist('isZeroToTenScale','var') && isZeroToTenScale==1
                    knob_values=obj.knobs.rescale_knobs(knob_values,0);
%                 end
%                 if ~obj.knobs.isnaive_boundaries
                    knob_values=obj.knobs.project_involved_knob_groups_on_correct_flow_subspace(knob_values);
%                 end
                knob_values=obj.project_on_correct_TVM_subspace(knob_values);
                zeroten_knob_values=obj.knobs.rescale_knobs(knob_values,1);
                disp(['Knobs vector and values being tested for iteration # ']);%,num2str(obj.numberOfEvaluations),' :']);
                disp(' ');
                disp(['               Demand Id :','                 Link Id :','                                    Value, min and max:','           Value on a scale from 0 to 10:']);
                disp(' ');
                disp([obj.knobs.demand_ids,obj.knobs.link_ids, knob_values(1:obj.knobs.nKnobs,1),obj.knobs.boundaries_min,obj.knobs.boundaries_max,zeroten_knob_values(1:obj.knobs.nKnobs,1)]);
                obj.beats_simulation.beats.reset();
                obj.knobs.set_knobs_persistent(knob_values);
                obj.beats_simulation.run_beats_persistent;
                obj.error_function.calculate_pc_from_beats; 
                [err,error_in_percentage] = obj.error_function.calculate_error;
                disp(['Total error in percentage value : ', num2str(error_in_percentage)]);
                disp('CONTRIBUTIONS : ')
                for i=1:size(obj.error_function.performance_calculators,2)
                    disp([obj.error_function.performance_calculators{i}.name,' : ']);
                    disp(['         contribution in total error in percentage : ', num2str(obj.error_function.contributions_in_percentage(i))]);
                    disp(['         actual error in percentage : ', num2str(obj.error_function.errors_in_percentage(i))])
                    disp(['         actual error value : ',num2str(obj.error_function.errors(i))]);
                end              
%                 obj.save_congestionPattern_matrix;
%                 obj.plot_zeroten_knobs_history(1);
%                 obj.error_function.plot_complete(2);
%                 obj.plot_all_performance_calculators(5);
% %                 obj.plot_performance_calculator_if_exists('CongestionPattern');
%                 drawnow;
                 errors_in_percentage(1,p)=error_in_percentage;
%                  obj.numberOfEvaluations=numEval+p;
            else
                error('The matrix with knobs values given does not match the number of knobs to tune or is not a column vector.');
            end
        end    
        end

        function [] = run_program(obj, firstColumn, lastColumn)
            %run the program set in the program Excel file and print the
            %results in the results Excel file.
            if obj.current_xls_program_column~=firstColumn
                obj.current_xls_program_column=firstColumn;
                obj.is_loaded=0;
            end
            while (obj.current_xls_program_column<=lastColumn)
                disp(strcat(['PROGRAM SETTINGS COLUMN ', num2str(obj.current_xls_program_column)]));
%             try
                if (obj.is_loaded~=1)
                    obj.load_properties_from_xls;
                end    
                counter=obj.number_runs;          
                while (counter > 0)
                    disp([num2str(counter), ' RUNS REMAINING FOR THIS SETTINGS COLUMN']);
                    obj.run_algorithm;
                    obj.send_result_to_xls(obj.xls_results);
                    counter=counter-1;
                end
                obj.current_xls_program_column=obj.current_xls_program_column+1;
                obj.is_loaded=0;
%             catch exception
%                 warning(['AN ERROR OCCURED DURING COLUMN ',num2str(obj.current_xls_program_column),' EXECUTION : ']);
%                 disp(exception);
%             end
            end    
           obj.make_notmade_movies;
        end % run the program defined by the input Excel file and write its results in the output Excel file, a .mat file and as frames of CongestionPattern to make a movie.        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Plot and movie methods                                             %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
                         
        function [] = plot_scenario(obj,is_mainline_only_format, with_monitored_onramps,with_monitored_offramps,with_nonmonitored_onramps,with_nonmonitored_offramps,with_monitored_mainlines) %Visually plot the freeway and ramps
            %The designated mainline link for ramps will be the precedent one.

            if(nargin<3)
                with_monitored_onramps=1;
                with_monitored_offramps=1;
                with_nonmonitored_onramps=1;
                with_nonmonitored_offramps=1;
                with_monitored_mainlines=1;
                if (nargin<2)
                   is_mainline_only_format=0;
                end    
            end
            cmap=[0.25,0.25,0.25];
            leg={};
            value=1;
            if ~is_mainline_only_format
                xinfo='Mainline links in order';
                yinfo='Ramps info                                       Mainline info';
                mainline_array=zeros(1,sum(obj.mainline_mask_beats));
                ramps_array=zeros(1,sum(obj.mainline_mask_beats));
                good_source_mask=obj.send_mask_beats_to_linear_mainline_space(obj.good_source_mask_beats);
                good_sink_mask=obj.send_mask_beats_to_linear_mainline_space(obj.good_sink_mask_beats);
                good_mainline_mask=obj.send_mask_beats_to_linear_mainline_space(obj.good_mainline_mask_beats);
                onramp_mask=obj.send_mask_beats_to_linear_mainline_space(logical(obj.source_mask_beats.*~obj.mainline_mask_beats));
                offramp_mask=obj.send_mask_beats_to_linear_mainline_space(logical(obj.sink_mask_beats.*~obj.mainline_mask_beats));
                if with_monitored_mainlines
                    mainline_array(good_mainline_mask)=value;
                    value=value+1;
                    cmap=[cmap;1,1,0];
                    leg{1,end+1}='Monitored mainline links';
                end
                if with_monitored_onramps
                   ramps_array(logical(good_source_mask.*onramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;0,0,0.4];
                   leg{1,end+1}='Monitored on-ramps';
                end    
                if with_monitored_offramps
                   ramps_array(logical(good_sink_mask.*offramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;0,0.4,0.4];
                   leg{1,end+1}='Monitored off-ramps';
                end    
                if with_nonmonitored_onramps
                    ramps_array(logical(~good_source_mask.*onramp_mask))=value;
                    value=value+1;
                    cmap=[cmap;1,0,0];
                    leg{1,end+1}='Non-monitored on-ramps';
                end
                if with_nonmonitored_offramps
                    ramps_array(logical(~good_sink_mask.*offramp_mask))=value;
                    cmap=[cmap;1,0.25,1];
                    leg{1,end+1}='Non-monitored off-ramps';
                end
                array=[mainline_array;ramps_array];
            else
                xinfo='All links in order';
                yinfo='Link info';
                array=zeros(1,size(obj.link_ids_beats,1));
                good_source_mask=obj.send_mask_beats_to_linear_space(obj.good_source_mask_beats);
                good_sink_mask=obj.send_mask_beats_to_linear_space(obj.good_sink_mask_beats);
                good_mainline_mask=obj.send_mask_beats_to_linear_space(obj.good_mainline_mask_beats);
                onramp_mask=obj.send_mask_beats_to_linear_space(logical(obj.source_mask_beats.*~obj.mainline_mask_beats));
                offramp_mask=obj.send_mask_beats_to_linear_space(logical(obj.sink_mask_beats.*~obj.mainline_mask_beats));
                if with_monitored_mainlines
                    array(good_mainline_mask)=value;
                    value=value+1;
                    cmap=[cmap;1,1,0];
                    leg{1,end+1}='Monitored mainline links';
                end
                if with_monitored_onramps
                   array(logical(good_source_mask.*onramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;0,0,0.4];
                   leg{1,end+1}='Monitored on-ramps';
                end    
                if with_monitored_offramps
                   array(logical(good_sink_mask.*offramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;0,0.4,0.4];
                   leg{1,end+1}='Monitored off-ramps';
                end    
                if with_nonmonitored_onramps
                    array(logical(~good_source_mask.*onramp_mask))=value;
                    value=value+1;
                    cmap=[cmap;1,0,0];
                    leg{1,end+1}='Non-monitored on-ramps';
                end
                if with_nonmonitored_offramps
                    array(logical(~good_sink_mask.*offramp_mask))=value;
                    value=value+1;
                    cmap=[cmap;1,0.25,1];
                    leg{1,end+1}='Non-monitored off-ramps';                    
                end    
            end      
            arg_array=[with_monitored_onramps,with_monitored_offramps,with_nonmonitored_onramps,with_nonmonitored_offramps,with_monitored_mainlines];
            number_arg=sum(arg_array);
            figure;
            imagesc(array);
            colormap(cmap);
            title(['Scenario']);
            xlabel(xinfo);
            ylabel(yinfo);
            L = line(ones(number_arg),ones(number_arg), 'LineWidth',2); 
            set(L,{'color'},mat2cell(cmap(2:end,:),ones(1,number_arg),3));
            legend(leg);
        end    
                
        function [movie] = plot_movie(obj, figureNumber, congestion_pattern_only, tosave, noncongestion_refresh_rate, stop_frame)
            if(nargin<5)
                noncongestion_refresh_rate=obj.knobs.nKnobs;
            end    
            directory=[pwd,'\movies\',obj.dated_name,'\'];
            figure_title=obj.get_figure_title;
            max_error=max(error_in_percentage_history);
            if (nargin<4)
                tosave=0;
            end    
            if (nargin<6)
                D = dir([pwd,'\movies\',obj.dated_name,'\frames\*.mat']);
                stop_frame = length(D(not([D.isdir])));
            end
            stop_frame=min([stop_frame,size(obj.error_function.error_in_percentage_history,1),size(obj.knobs.zeroten_knobs_history,1)]);
            if (nargin<2)
                h=figure;
                figureNumber=h.Number;
            else
                h=figure(figureNumber);
            end
            movie(stop_frame) = struct('cdata',[],'colormap',[]);
            p=[100,50,1366,768];
            set(h, 'Position', p);
            i=1;
            flag=1;
            h.Name=figure_title;
            suptitle(figure_title);
            if (nargin>3 && congestion_pattern_only)
                while flag && i<=stop_frame
                    if exist([directory,num2str(i),'.mat'],'file')==2
                        load(['movies\',obj.dated_name,'\frames\',num2str(i),'.mat']);
                        cp=obj.error_function.performance_calculators{obj.error_function.find_performance_calculator('CongestionPattern')};
                        cp.plot(figureNumber,i,frame);
                        drawnow;
                        if (tosave)
                            movie(i)=getframe;
                        end    
                        i=i+1;
                    else flag=0;
                    end
                end
            else
                while flag && i<=stop_frame
                    if exist([pwd,'\movies\',bj.dated_name,'\frames\',num2str(i),'.mat'],'file')==2
                        if (mod(i,noncongestion_refresh_rate)==0 || i==1)
                            subplot(20,2,[3,5,7,9,11]);
                            obj.knobs.plot_zeroten_knobs_genmean_history(figureNumber,i);
                            axis([0,stop_frame,0,10]);
                            line([i i],[0,10],'Color',[1 0 0]);
                            hold on
                            plot(i,obj.zeroten_knobs_genmean_history(i,:),'r.','MarkerSize',20)
                            hold off
                            subplot(20,2,[4,6,8,10,12]);
                            obj.error_function.plot_complete(figureNumber, i, 1);
                            axis([0,stop_frame,0,max_error]);
                            line([i i],[0,max_error],'Color',[1 0 0]);
                            hold on
                            plot(i,obj.error_function.error_in_percentage_genmean_history(i),'r.','MarkerSize',20)
                            hold on
                            plot(i,obj.error_function.contributions_in_percentage_genmean_history(i,:),'b.','MarkerSize',10)
                            hold off
                        end    
                        load(['movies\',obj.dated_name,'\frames\',num2str(i),'.mat']);
                        subplot(12,2, [11:24]);
                        cp=obj.error_function.performance_calculators{obj.error_function.find_performance_calculator('CongestionPattern')};
                        cp.plot(figureNumber,i,frame);
                        figure(figureNumber);
                        drawnow;
                        if (tosave)
                            movie(i)=getframe(figureNumber);
                        end    
                        i=i+1;
                    else flag=0;
                    end
                end
            end
        end
        
        function [] = make_movie(obj,stop_frame)
            videoname=[pwd,'\movies\',obj.dated_name,'.avi'];
            if exist(videoname,'file')~=2
                if nargin==3
                    M=obj.plot_movie(1,0,1,1,stop_frame);
                else
                    M=obj.plot_movie(1,0,1,1);
                end
                vidObj = VideoWriter(videoname);
                open(vidObj);
                disp(['WRITTING MOVIE TO ',videoname]);
                writeVideo(vidObj,M);
                close(vidObj);
            else
                error('Sorry, a video already exists for this algorithm execution.');
            end    
        end    
        
        function [] = make_notmade_movies(obj,stop_frame)
            dirname=[pwd,'\movies\'];
            reportname=[pwd,'\',obj.algorithm_name,'_reports\',obj.dated_name,'\',obj.dated_name,'_allvariables.mat'];
            list=dir(dirname);
            for i=1:size(list,1)
                videoname=[dirname,list(i).name,'.avi'];
                try
                    if (list(i).isdir && exist(videoname,'file')~=2 && ~strcmp(list(i).name,'..') ...
                            && ~strcmp(list(i).name,'.') && exist(reportname,'file')==2)
                        report_obj=load(reportname, 'obj');
                        if nargin==2
                            report_obj.make_movie(stop_frame);
                        else    
                            report_obj.make_movie;
                        end
                    end
                    close all;
                    drawnow;
                catch exception
                    warning(['AN ERROR OCCURED BUILDING ',videoname,' :']);
                    disp(exception);
                end
            end    
        end    
        
        function [] = plot_all(obj)
%             number=2+size(obj.error_function.performance_calculators,2);
%             vsize=floor(number/2);
%             hsize=number-floor(number/2);
            obj.knobs.plot_zeroten_knobs_history(1);
            obj.error_function.plot_complete(2);
            obj.plot_all_performance_calculators(3);
            obj.plot_algorithm_data;
        end    
                
        function [] = plot_multiple_sensor_link_conflicts(obj)
            unique_multiple_sensor_link_ids=unique(obj.multiple_sensor_index2vds2id2link(:,4),'stable');
            for i=1:size(unique_multiple_sensor_link_ids,1)
                link_id=unique_multiple_sensor_link_ids(i,1);
                indices=find(obj.pems.link_ids==link_id);
                leg={};
                h=figure;
                for j=1:size(indices,2)
                    plot(obj.pems.data.flw_in_veh(:,indices(j)));
                    leg{j}=['Link ID = ',num2str(link_id),' | VDS = ',num2str(obj.pems.vds2id(indices(j),1)),' | SensorID = ',num2str(obj.sensor_link(indices(j),1)),' PeMS profile.'];
                    hold on
                end
                h.Name=['Flow profiles for link id ',num2str(link_id)];
                title(['Flow profiles for link id ',num2str(link_id)]);
                legend(leg);
                hold off
                leg={};
                h=figure;
                for j=1:size(indices,2)
                    plot(obj.pems.data.spd(:,indices(j)));
                    leg{j}=['Link ID = ',num2str(link_id),' | VDS = ',num2str(obj.pems.vds2id(indices(j),1)),' | SensorID = ',num2str(obj.sensor_link(indices(j),1)),' PeMS profile.'];
                    hold on
                end
                h.Name=['Speed profiles for link id ',num2str(link_id)];
                title(['Speed profiles for link id ',num2str(link_id)]);
                legend(leg);
                hold off
                leg={};
                h=figure;
                for j=1:size(indices,2)
                    plot(obj.pems.data.dty(:,indices(j)));
                    leg{j}=['Link ID = ',num2str(link_id),' | VDS = ',num2str(obj.pems.vds2id(indices(j),1)),' | SensorID = ',num2str(obj.sensor_link(indices(j),1)),' PeMS profile.'];
                    hold on
                end
                h.Name=['Density profiles for link id ',num2str(link_id)];
                title(['Density profiles for link id ',num2str(link_id)]);
                legend(leg);
                hold off
            end   
        end    
        
    end    
    
    methods (Abstract, Static)
        
         [] = plot_algorithm_data() %this plot method is proper to each algorithm.
         
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Privates and Hidden                                                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    methods (Abstract, Access= protected)
        
        [figure_title] = get_figure_title(obj) % This is the figure title for the movie. It is proper to each algorithm.
        
    end    
    
    methods (Hidden, Access = public) %Access is public because other objects should be able to access it (didn't find how to allow several classes to access a method.)
        
        %initial loading and setting stuff.................................
        function [] = load_beats(obj)
            if (~strcmp(obj.scenario_ptr,''))
                obj.beats_loaded=0;
                obj.beats_parameters.RUN_MODE = 'fw_fr_split_output'; 
                display('LOADING BEATS.');
                obj.beats_simulation = BeatsSimulation;
                obj.beats_simulation.import_beats_classes;
                obj.beats_simulation.load_scenario(obj.scenario_ptr);
                obj.beats_simulation.create_beats_object(obj.beats_parameters);
                obj.link_ids_beats=obj.beats_simulation.scenario_ptr.get_link_ids;
                [~,obj.freeway_name,~]=fileparts(obj.scenario_ptr);
                obj.reset_beats;
                obj.linear_link_ids=obj.link_ids_beats(obj.beats_simulation.scenario_ptr.extract_linear_fwy_indices);
                disp('BEATS SETTINGS LOADED.')
                obj.beats_loaded=1;
            else error('Beats scenario xml file adress and beats parameters must be set before loading beats.');   
            end    
        end    %load beats simulation and scenario data to AlgorithmBox.
        
        function [type] = get_type(obj,link_id) %Get the type of a link with its id (should be in ScenarioPtr).
            if (ismember(link_id,obj.link_ids_beats(obj.source_mask_beats)))
                type='On-Ramp';
            elseif ismember(link_id,obj.link_ids_beats(obj.sink_mask_beats))
                type='Off-Ramp';
            else 
                type='Freeway';
            end    
        end   
        
        function [] = set_masks_and_reference_values(obj)
            if (obj.beats_loaded && obj.pems.is_loaded)
                obj.sensor_link = obj.beats_simulation.scenario_ptr.get_sensor_link_map;
                good_sensor_mask_pems_r = logical(all(~isnan(obj.pems.data.flw(:,:,obj.current_day))).*any(obj.pems.data.flw(:,:,obj.current_day)));
                good_sensor_ids_r=obj.pems.vds2id(good_sensor_mask_pems_r,2);
                good_sensor_link_r=obj.sensor_link(ismember(obj.sensor_link(:,1), good_sensor_ids_r),:);
                good_sensor_link=zeros(1,2);
                k=1;
                for i= 1:size(good_sensor_link_r(:,2),1)
                    if (~ismember(good_sensor_link_r(i,2),good_sensor_link(:,2)))
                        good_sensor_link(k,:)=good_sensor_link_r(i,:);
                        k=k+1;
                    end    
                end
                good_sensor_ids=good_sensor_link(:,1);
                obj.good_sensor_mask_pems=reshape(ismember(obj.pems.vds2id(:,2),good_sensor_ids),1,[]);
                good_sensor_link_ids=good_sensor_link(:,2);
                mainline_link_ids=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('freeway');
                obj.mainline_mask_beats=ismember(obj.link_ids_beats, mainline_link_ids);
                obj.source_mask_beats=obj.beats_simulation.scenario_ptr.is_source_link;
                obj.sink_mask_beats=obj.beats_simulation.scenario_ptr.is_sink_link;
                source_link_ids=obj.link_ids_beats(1,obj.source_mask_beats);
                sink_link_ids=obj.link_ids_beats(1,obj.sink_mask_beats);
                obj.mainline_mask_pems=reshape(ismember(obj.sensor_link(:,2), mainline_link_ids),1,[]);
                obj.source_mask_pems=reshape(ismember(obj.sensor_link(:,2), source_link_ids),1,[]);
                obj.sink_mask_pems=reshape(ismember(obj.sensor_link(:,2), sink_link_ids),1,[]);
                obj.good_sensor_mask_beats=ismember(obj.link_ids_beats, good_sensor_link_ids);
                obj.good_mainline_mask_beats=logical(obj.good_sensor_mask_beats.*obj.mainline_mask_beats);
                obj.good_source_mask_beats=logical(obj.good_sensor_mask_beats.*obj.source_mask_beats);
                obj.good_sink_mask_beats=logical(obj.good_sensor_mask_beats.*obj.sink_mask_beats);
                obj.good_mainline_mask_pems=logical(obj.good_sensor_mask_pems.*obj.mainline_mask_pems);
                obj.good_source_mask_pems=logical(obj.good_sensor_mask_pems.*obj.source_mask_pems);
                obj.good_sink_mask_pems=logical(obj.good_sensor_mask_pems.*obj.sink_mask_pems);
                obj.set_multiple_sensor_index2vds2id2link;
                TVmiles=TVM(obj);
                if (size(obj.knobs,1)~=0 && obj.knobs.is_loaded && all(mean(obj.knobs.current_value,2)~=ones(obj.knobs.nKnobs,1)))
                    obj.reset_beats;
                end    
                obj.TVM_reference_values.beats=TVmiles.calculate_from_beats;
                obj.TVM_reference_values.pems=TVmiles.calculate_from_pems;
                if (size(obj.error_function,1)~=0 && obj.error_function.is_loaded==1)
                    obj.error_function.calculate_pc_from_pems;
                end    
                pems_flows=sum(obj.pems.data.flw_in_veh(:,obj.good_mainline_mask_pems,size(obj.pems.days,2)+1),1);
                obj.pems.average_mainline_flow=mean(pems_flows(~isnan(pems_flows)),2);
                obj.masks_loaded=1;
            else
                error('Beats simulation and PeMS data must be loaded before setting the masks and reference values.');
            end    
        end    %sets the masks for further link selection and smoothens pems flow values. Computes initial reference values as well (TVM, PeMS average mainline flow).
                                                                
        function [] = reset_beats(obj) %sets the knobs to one (reference value) and runs beats.
            obj.beats_simulation.beats.reset();
            if size(obj.knobs,1)~=0
                if obj.is_uncertainty_for_monitored_ramps
                    obj.knobs.set_knobs_persistent(ones(obj.knobs.nKnobs+size(obj.knobs.monitored_ramp_link_ids,1),1));
                else
                    obj.knobs.set_knobs_persistent(ones(obj.knobs.nKnobs));
                end
            end    
            disp('RUNNING BEATS A FIRST TIME FOR REFERENCE DATA.');
            obj.beats_simulation.run_beats_persistent;
        end
        
        function [] = reset_for_new_run(obj) %erases record of last run for the  next one, sets the name of the next run and creates corresponding directories.
            obj.error_function.reset_history;
            obj.knobs.reset_history;
            obj.dated_name=Utilities.give_dated_name([obj.algorithm_name,'_reports\']);
            mkdir([pwd,'\',obj.algorithm_name,'_reports\',obj.dated_name]);
            mkdir([pwd,'\movies\',obj.dated_name,'\frames']);
        end    
        
        %solving multiple sensors in one link conflicts
        function [] = set_multiple_sensor_index2vds2id2link(obj)
            if (obj.beats_loaded && obj.pems.is_loaded)
                obj.multiple_sensor_index2vds2id2link=[];
                unique_link_ids=unique(obj.sensor_link(:,2),'stable');
                vds=obj.pems.vds2id(:,1);
                for i=1:size(unique_link_ids,1)
                    indexes=find(obj.sensor_link(:,2)==unique_link_ids(i,1));
                    if (size(indexes,1)>1)
                        obj.multiple_sensor_index2vds2id2link([end+1,end+sum(ismember(obj.sensor_link(:,2),unique_link_ids(i,1)))],:)=[indexes,vds(indexes,1),obj.sensor_link(indexes,:)];
                    end    
                end
            else
                error('Please, load BEATS and PeMS before solving multiple sensors conflicts');
            end    
        end %detects multiple sensors on one link situations and put them in obj.multiple_sensor_index2vds2id2link.
        
        function [] = solve_multiple_sensor_link_conflicts(obj)
            if (obj.multiple_sensor_vds_to_use~=0)
                disp('SOLVING "MULTIPLE SENSORS ON THE SAME LINK" CONFLICTS.');
                obj.set_multiple_sensor_index2vds2id2link;
                info=obj.multiple_sensor_index2vds2id2link;
                tokeep=obj.multiple_sensor_vds_to_use;
                ndays=size(obj.pems.days,2);
                flw_profiles=zeros(size(obj.pems.data.flw,1),size(info,1),ndays);
                spd_profiles=zeros(size(obj.pems.data.flw,1),size(info,1),ndays);
                dty_profiles=zeros(size(obj.pems.data.flw,1),size(info,1),ndays);
                for k=1:ndays
                    profile_index=1;
                    link_id=info(1,4);
                    spd_count=1;
                    for i=1:size(info,1)
                        if link_id~=info(i,4)
                            spd_profiles(:,profile_index,k)=spd_profiles(:,profile_index,k)/spd_count;
                            profile_index=i;
                            link_id=info(i,4);
                            spd_count=1;
                        end    
                        if (ismember(info(i,2),tokeep))
                            ind=info(i,1);
                            if any(obj.pems.data.flw(:,ind,k),1)
                                flw_profiles(:,profile_index,k)=flw_profiles(:,profile_index,k)+obj.pems.data.flw(:,ind,k);
                            end    
                            if any(obj.pems.data.dty(:,ind,k))
                                dty_profiles(:,profile_index,k)=dty_profiles(:,profile_index,k)+obj.pems.data.dty(:,ind,k);                         
                            end
                            if any(obj.pems.data.spd(:,ind,k))
                                spd_profiles(:,profile_index,k)=spd_profiles(:,profile_index,k)+obj.pems.data.spd(:,ind,k);
                                spd_count=spd_count+1;
                            end    
                        else
                            profile_index=profile_index+1;
                        end
                    end 
                    flw_profiles(:,~any(flw_profiles(:,:,k),1),k)=nan;
                    spd_profiles(:,~any(spd_profiles(:,:,k),1),k)=nan;
                    dty_profiles(:,~any(dty_profiles(:,:,k),1),k)=nan;
                end    
                obj.pems.data.flw(:,info(:,1),1:end-1)=flw_profiles;
                obj.pems.data.spd(:,info(:,1),1:end-1)=spd_profiles;
                obj.pems.data.dty(:,info(:,1),1:end-1)=dty_profiles;
                obj.pems.data.flw(:,:,end)=mean(obj.pems.data.flw(:,:,1:end-1),3);
                obj.pems.data.dty(:,:,end)=mean(obj.pems.data.dty(:,:,1:end-1),3);
                obj.pems.data.spd(:,:,end)=mean(obj.pems.data.spd(:,:,1:end-1),3);
                obj.pems.data.flw_in_veh=obj.pems.data.flw/12;
                obj.set_masks_and_reference_values;
            end    
        end %among the sensors in obj.multiple_sensor_index2vds2id2link, keep those who are in obj.multiple_sensor_vds_to_use. If multiple vds for one link, flw and dty_veh value will be summed and their speeds will be averaged.
        
        %solving particular situations (like HOV pbs) by deleting sensors.
        function [] = delete_chosen_sensors(obj) %delete sensors in obj.vds_sensors_to_delete.
            if (obj.vds_sensors_to_delete~=0)
                disp('DELETING CHOSEN SENSORS.');
                for i=1:size(obj.vds_sensors_to_delete,2)
                    index=find(obj.pems.vds2id(:,1)==obj.vds_sensors_to_delete(i));
                    obj.pems.data.flw(:,index,:)=nan;
                    obj.pems.data.dty(:,index,:)=nan;
                    obj.pems.data.spd(:,index,:)=nan;
                    obj.pems.data.flw_in_veh(:,index,:)=nan;   
                    obj.set_masks_and_reference_values;
                end
            end    
        end    
        
        %get link lengths in beats or pems data matching format............
        function [lengths] = get_link_lengths_miles_pems(obj,link_mask_pems, same_link_mask_beats)
            all_lengths=obj.beats_simulation.scenario_ptr.get_link_lengths('us');
            lengths=zeros(1,sum(link_mask_pems));
            ordered_link_ids=obj.pems.linear_link_ids(obj.send_mask_pems_to_linear_space(link_mask_pems));
            k=1;
            for i=1:size(ordered_link_ids,2)
                link_mask=ismember(obj.link_ids_beats,ordered_link_ids(1,i));
                if ~isempty(find(link_mask.*same_link_mask_beats))
                    lengths(1,k)=all_lengths(1,logical(link_mask.*same_link_mask_beats));
                    k=k+1;
                end    
            end
        end %get an array with the lengths of the links pointed by link_mask_pems, when applied to a 'pems format' link ids array. Same_link_mask_beats must be the the same link mask for beats format (e.g. : good_mainline_mask_beats for good_mainline_mask_pems).
        
        function [lengths] = get_link_lengths_miles_beats(obj,link_mask_beats)
            link_length_miles = obj.beats_simulation.scenario_ptr.get_link_lengths('us');
            lengths = link_length_miles(link_mask_beats);
        end %get an array with the lengths of the links pointed by link_mask_beats, when applied to a 'beats format' link ids array.
        
        %get remaining monitored mainline link ids.........................
        function [mainline_link_id]=get_next_mainline_link_id_deprecated(obj, input_link_id)
%             if ismember(input_link_id,obj.link_ids_beats(logical(obj.source_mask_beats.*~obj.mainline_mask_beats)))
%                 output_node_id=obj.beats_simulation.scenario_ptr.get_link_byID(input_link_id).end.ATTRIBUTE.node_id;
%                 output_node=obj.beats_simulation.scenario_ptr.get_node_byID(output_node_id);
%                 mainline_link_ids=obj.link_ids_beats(obj.mainline_mask_beats);
%                 output_link_ids=output_node.outputs.output;
%                 node_output_links=[];
%                 for i=1:size(output_link_ids,2)
%                     node_output_links=output_node.outputs.output(i).ATTRIBUTE.link_id;
%                 end
%                 mainline_link_id=node_output_links(ismember(node_output_links,mainline_link_ids));
%             elseif ismember(input_link_id,obj.link_ids_beats(logical(obj.sink_mask_beats.*~obj.mainline_mask_beats)))
%                 input_node_id=obj.beats_simulation.scenario_ptr.get_link_byID(input_link_id).begin.ATTRIBUTE.node_id;
%                 input_node=obj.beats_simulation.scenario_ptr.get_node_byID(input_node_id);
%                 mainline_link_ids=obj.link_ids_beats(obj.mainline_mask_beats);
%                 output_link_ids=input_node.outputs.output;
%                 node_output_links=[];
%                 for i=1:size(output_link_ids,2)
%                     node_output_links=input_node.outputs.output(i).ATTRIBUTE.link_id;
%                 end
%                 mainline_link_id=node_output_links(ismember(node_output_links,mainline_link_ids));
%             else error('Input link must be non-mainline sink or source');        
%             end    
         end % gets the id of the mainline link just after the node connecting the input_link_id ramp to the freeway.

        function [mainline_link_id]=get_next_mainline_link_id(obj, input_link_id)
            index=find(obj.linear_link_ids==input_link_id);
            is_mainline=0;
            i=0;
            while (is_mainline==0)
                i=i+1;
                mainline_link_id=obj.linear_link_ids(index+i);
                is_mainline=ismember(mainline_link_id, obj.link_ids_beats(obj.mainline_mask_beats));
            end
        end % gets the id of the mainline link just after the node connecting the input_link_id ramp to the freeway.
        
        function [remaining_mainline_length]=get_remaining_monitored_mainline_length(obj, first_mainline_link_id)
            k=1;
            while obj.linear_link_ids(k)~=first_mainline_link_id && k<=size(obj.linear_link_ids,2)
                k=k+1;
            end
            remaining_link_ids=obj.linear_link_ids(k:size(obj.linear_link_ids,2));
            remaining_link_ids_mask=ismember(obj.link_ids_beats,remaining_link_ids);
            remaining_monitored_mainline_links_mask=logical(remaining_link_ids_mask.*obj.good_mainline_mask_beats);
            remaining_mainline_length=sum(obj.get_link_lengths_miles_beats(remaining_monitored_mainline_links_mask));
        end  %gets the remaining mainline length after the mainline link first_mainline_link_id. Used to compute TVM a-priori.

        %project the algorithm input to correct total TVM subspace.........
        function [sum_of_template] = get_sum_of_template_in_veh(obj,link_id) 
            dp=obj.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(link_id);
            sum_of_template=5000; %sum(dp.demand)*dp.dt;
        end  %returns the sum over time of the template of the link id, in vehicles.
        
        function [knobs_on_correct_subspace] = project_on_correct_TVM_subspace(obj,vector) % Project vector on the hyperplan of vectors that will make beats output have the same TVM as pems within a range given by obj.error_function.pcs_uncertainty.
            equation_coefficients_tuple=[]; 
            obj.knobs.current_preTVMProjection_value=vector;
            %equation_coefficients_tuple : N tuple that will contain the coefficients of the equation of 
            %the hyperplan. We will call them alpha(i) : alpha(i)= (sum over time of the template values of the demand profile of knob(i))*(remaining mainline length from the corresponding link) 
            %The equation is [(knob1)*alpha(1)+(knob2)*alpha(2)+...+(knobN)*alpha(N)-sum(alpha(i))]+[TVM value given by beats output when all knobs are set to one]=pems TVM value
            %(the substraction of sum of alphaIs removes the extra contributions of the links tuned in beats TVM)
            sze=obj.knobs.nKnobs;
            link_ids=obj.knobs.link_ids;
            boundaries_min=obj.knobs.boundaries_min;
            boundaries_max=obj.knobs.boundaries_max;
            if obj.is_uncertainty_for_monitored_ramps
                sze=sze+size(obj.knobs.monitored_ramp_link_ids,1);
                link_ids=[link_ids;obj.knobs.monitored_ramp_link_ids];
                boundaries_min=[boundaries_min;obj.knobs.monitored_ramp_knob_boundaries_min];
                boundaries_max=[boundaries_max;obj.knobs.monitored_ramp_knob_boundaries_max];
            end
            for i=1:sze %fill the tuple
                if (ismember(link_ids(i),obj.link_ids_beats(obj.source_mask_beats)))
                    sig=1;
                else
                    sig=-1;
                end
                equation_coefficients_tuple(1,i)=sig*obj.get_sum_of_template_in_veh(link_ids(i,1))*obj.get_remaining_monitored_mainline_length(obj.get_next_mainline_link_id(link_ids(i)));  
            end
            equation_rest_of_left_side=obj.TVM_reference_values.beats-sum(equation_coefficients_tuple); %second term between brackets of the left side
            flowdiff=obj.TVM_reference_values.pems-equation_rest_of_left_side;
            si=sign(flowdiff);
            unc=obj.error_function.pcs_uncertainty;
            %Exact TVM projection : [knobs_on_correct_subspace,fval]=quadprog(eye(sze),-reshape(vector,1,[]),[],[],equation_coefficients_tuple, obj.TVM_reference_values.pems-equation_rest_of_left_side,obj.knobs.boundaries_min,obj.knobs.boundaries_max); % minimization program
            %Projection within a tolerance range :
            [knobs_on_correct_subspace,fval]=quadprog(eye(sze),-reshape(vector,1,[]),[si*equation_coefficients_tuple;-si*equation_coefficients_tuple],[si*(1+unc)*flowdiff;-si*(1-unc)*flowdiff],[],[],boundaries_min,boundaries_max);
        end    
  
        %Transform masks to fit linear link ids............................
        function [linear_mask] = send_mask_beats_to_linear_space(obj, mask_beats) %Transforms a link mask that is in the order of the BeATS scenario to a mask that is in linear order.
            linear_mask=ismember(obj.linear_link_ids,obj.link_ids_beats(mask_beats));
        end    
        
        function [linear_mask_in_mainline_space] = send_linear_mask_beats_to_mainline_space(obj, linear_mask) %Transforms a mask that is in linear order and pointing at all the links to a mask that is pointing only at mainline links. For ramps selected by the former mask, the designated mainline link will be the precedent one.
            ordered_mainline_link_ids=obj.linear_link_ids(ismember(obj.linear_link_ids,obj.link_ids_beats(obj.mainline_mask_beats)));
            nonlinear_mask=ismember(obj.link_ids_beats,obj.linear_link_ids(linear_mask));
            linear_mask_in_mainline_space = ismember(ordered_mainline_link_ids,obj.linear_link_ids(linear_mask));
            ramp_link_ids=obj.link_ids_beats(logical(nonlinear_mask.*(obj.source_mask_beats+obj.sink_mask_beats).*~obj.mainline_mask_beats));
            indices=find(ismember(obj.linear_link_ids,ramp_link_ids));
            linear_mainline_mask=ismember(obj.linear_link_ids,obj.link_ids_beats(obj.mainline_mask_beats));
            for i=1:size(indices,2)
                left=0;
                l=1;
                while left==0;
                    if linear_mainline_mask(indices(i)-l)==1
                        index=find(ordered_mainline_link_ids==obj.linear_link_ids(indices(i)-l));
                        linear_mask_in_mainline_space(index)=1;
                        left=1;
                    else l=l+1;
                    end
                end    
%                 r=1;
%                 right=0;
%                 while right==0;
%                     if linear_mainline_mask(indices(i)+r)==1
%                         index=find(ordered_mainline_link_ids==obj.linear_link_ids(indices(i)+r));
%                         linear_mask_in_mainline_space(index)=1;
%                         right=1;
%                     else r=r+1;
%                     end
%                 end
            end       
        end  
        
        function [linear_mask_in_mainline_space] = send_mask_beats_to_linear_mainline_space(obj,mask_beats)
            linear_mask_in_mainline_space=obj.send_linear_mask_beats_to_mainline_space(obj.send_mask_beats_to_linear_space( mask_beats));
        end  %Combine the two precedent methods.
        
        function [linear_mask] = send_mask_pems_to_linear_space(obj, mask_pems)
            linear_mask=ismember(obj.pems.linear_link_ids,obj.pems.link_ids(mask_pems));
        end %Same with pems data format masks.   
            
        function [linear_mask_in_mainline_space] = send_linear_mask_pems_to_mainline_space(obj, linear_mask_pems)
            linear_mainline_ids=obj.linear_link_ids(obj.send_mask_beats_to_linear_space(obj.mainline_mask_beats));
            linear_mask_in_mainline_space=ismember(linear_mainline_ids,obj.pems.linear_link_ids(linear_mask_pems));
        end   %Same with pems data format masks.
        
        function [linear_mask_in_mainline_space] = send_mask_pems_to_linear_mainline_space(obj, mask_pems)
            linear_mask_in_mainline_space=obj.send_linear_mask_pems_to_mainline_space(obj.send_mask_pems_to_linear_space(mask_pems));
        end  %Same with pems data format masks.  
        
        %temporary.........................................................        
        function [res] = compute_TVM_with_knobs_vector(obj,vector)
            %assumes units are in SI
            alphaIs_tuple=[];
            for i=1:size(obj.knobs.link_ids) %fill the tuple
                if (ismember(obj.knobs.link_ids(i),obj.link_ids_beats(obj.source_mask_beats)))
                    sign=1;
                else
                    sign=-1;
                end
                alphaIs_tuple(1,i)=sign*obj.get_sum_of_template_in_veh(obj.knobs.link_ids(i,1))*obj.get_remaining_monitored_mainline_length(obj.get_next_mainline_link_id(obj.knobs.link_ids(i))); 
            end
            res=obj.TVM_reference_values.beats+alphaIs_tuple*(vector-1);
       end   % Computes a-priori TVM with the knobs vector.
       
        function [absciss] = get_linear_absciss_for_link_id(obj,link_id)
           if ~ismember(link_id,obj.link_ids_beats(obj.mainline_mask_beats))
               link_id=obj.get_next_mainline_link_id(link_id);
           end    
           absciss=find(obj.error_function.performance_calculators{1}.send_mask_beats_to_linear_mainline_space(obj.link_ids_beats==link_id));
        end  %Get the idnex of link_id in the linear link ids array (with mainline and ramps).
       
    end
    
    methods (Hidden, Access = public)
        
        function [] = remove_field_from_property(obj, property, field)
           eval(strcat('obj.',property,'=rmfield(obj.',property,',',Utilities.char2char('field'),');'));
        end  %useless  
        
        %saving data......................................................
        function [] = save_data(obj)
            obj.plot_all;
            figures=findobj(0,'type','figure');
            fig_name= [pwd,'\',obj.algorithm_name,'_reports\',obj.dated_name,'\',obj.dated_name,'_figures.fig'];
            savefig(figures,fig_name);  
            if exist([pwd,'\movies\',obj.dated_name],'dir')~=7
                mkdir([pwd,'\movies\',obj.dated_name]);
            end
            load variablescmaes.mat
            mat_name =[pwd,'\',obj.algorithm_name,'_reports\',obj.dated_name,'\',obj.dated_name,'_allvariables.mat'];
            save(mat_name);
            close all
        end    %save the .mat file and figures with all the infos once the algorithm has finished.
        
        function [] = save_congestionPattern_matrix(obj)
            try
                CPindex=obj.error_function.find_performance_calculator('CongestionPattern');
                obj.error_function.performance_calculators{CPindex}.save_plot;
            catch
            end    
        end   %save the congestion pattern frame at every iteration.
           
    end    
     
end    



