classdef (Abstract) AlgorithmBox < handle
    %AlgorithmBox : used by any algorithm.
    %   Contains the properties and methods that are used by any algorithm for
    %   the automatic calibration problem (for now, tuning only on and
    %   offramp knobs).
    
    properties (Access = public)
        performance_calculator@PerformanceCalculator % a PerformanceCalculator subclass, which is a quantity measured in pems and outputed by beats e.g. TVM.
        error_calculator@ErrorCalculator % an ErrorCalculator subclass, which is a way of comparing two performance calculator values e.g. L1 norm.
        beats_simulation@BeatsSimulation % the BeatsSimulation object that will run and be overwritten at each algorithm iteration.
        beats_parameters=struct; % the parameters passed to BeatsSimulation.run_beats
        pems % the pems data to compare with the beats results.
        knobs=struct; % struct with two array fields : (nx1) 'knob_ids' containing the ids of the n knobs to tune and (nx2) 'knob_boundaries' containing the value of the min (first column) and the max (second column) values allowed for each knob (in the same order as knob_ids).
        maxEval=90; % maximum number of times that beats will run.
        maxIter=30; % maximum number of iterations of the algorithm.
        stopFValue=1000; % the algorithm will stop if a smaller value is reached by error_calculator.
    end
    
    properties(SetAccess = protected)
        result % result of the algorithm, given in the result_format.
        bestEverErrorFunctionValue % smallest error_calculator value reached during the execution. Extracted from the result.
        bestEverPoint % array of knob values that gave the best ever function value.
        numberOfFlops % number of flops for the execution. Extracted from result.
        numberOfEvaluations % number of times beats ran a simulation.
        stopFlag; % reason why the algorithm stopped. Extracted from result.
        convergence % convergence speed. Extracted from the result.
    end    
    
    methods (Access= public)
            
        function [] = run_assistant(obj) % assistant to set all the parameters in the command window.
            obj.load_beats_simulation;
            obj.load_pems_scenario;
            obj.set_knob_ids;
            obj.set_knob_boundaries;
            obj.ask_for_errorFunction;
            obj.ask_for_algorithm_parameters;
            obj.set_starting_point;
        end
        
        function [] = load_properties_from_xls_file(obj, properties_file_adress) % load the properties from an excel file in the format described underneath.
            %properties file : an xls file containing the AlgorithmBox
            %properties in the first column and the corresponding
            %expressions to be evaluated by Matlab in the second.
            %Empty cells in the second column will be ignored.
            [useless,xls,useless2] = xlsread(properties_file_adress);
            obj.beats_simulation = BeatsSimulation;
            obj.pems = BeatsSimulation;
            for i=1:size(xls,1)
                if ~strcmp(xls(i,2),'')
                    eval(strcat('obj.',char(xls(i,1)),'=',char(xls(i,2)),';'));
                end
            end
            obj.pems.run_beats(obj.beats_parameters);

        end    
               
        function [] = load_beats_simulation(obj)
            scenario_ptr = input('address of the scenario xml file : ', 's');
            obj.beats_simulation = BeatsSimulation;
            obj.beats_simulation.load_scenario(scenario_ptr);
            obj.beats_parameters=input(['Enter a struct containing the beats simulation properties (like "DURATION") : ']);
        end   
        
        function [] = load_pems_scenario(obj)
        end
        
        function [] = set_knob_ids(obj) % set the ids of the knobs to tune in the command window.
            if (size(obj.beats_simulation)~=0)
                numberMissingKnobs = input(strcat(['Among the', ' ', num2str(length(obj.beats_simulation.scenario_ptr.scenario.DemandSet.demandProfile)), ' knobs, how many have to be tuned ? :']));
                for i=1:numberMissingKnobs
                    obj.knobs.knob_ids(i,1)=input(strcat(['knob ', num2str(i),' id :']));
                end
            else
                error('No Beats Simulation loaded');
            end    
        end
        
        function [] = set_knob_boundaries(obj) % set the knob boundaries (in the same order as the knob ids) in the command window.
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
            obj.performance_calculator=input(['Enter the name of a "PerformanceCalculator" subclass : ']);
            obj.error_calculator=input(['Enter the name of an "ErrorCalculator" subclass : ']);
        end  
        
        function [result] = errorFunction(obj, knob_values) % the error function used by the algorithm. Compares the beats simulation result and pems data.
            %knob_values : n x 1 array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            if (size(knob_values,1)==size(obj.knobs.knob_ids,1))
              obj.beats_simulation.scenario_ptr.set_knob_values(obj.knobs.knob_ids, knob_values)
              obj.beats_simulation.run_beats(obj.beats_parameters);
              obj.performance_calculator.calculate_from_beats(obj.beats_simulation);
              obj.performance_calculator.calculate_from_pems(obj.pems);
              result = obj.error_calculator.calculate(obj.performance_calculator.result_from_beats, obj.performance_calculator.result_from_pems);
            else
                error('The matrix with knobs values given does not match with the number of knobs to tune.');
            end    
        end
        
    end   
    
    methods (Abstract, Access = public)
        [] = ask_for_algorithm_parameters(obj) % ask for the algorithm parameters in the command window.
        [] = run_algorithm(obj) % run the algorithm.
        [] = ask_for_starting_point(obj); % set the starting knob values.
    end    
end    


