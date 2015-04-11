classdef (Abstract) algorithmBox < handle
    %algorithm Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        performance_calculator@performanceCalculator
        error_calculator@errorCalculator
        beats_simulation@BeatsSimulation
        beats_parameters
        pems
        knobs=struct;
        maxEval=90;
        maxIter=30;
        stopFlag=1000;
        parameters=struct;
    end
    
    properties (Hidden)
        scenario_adress

    end    
    
    properties (Abstract, Constant)
        parameters_required
        parameters_optional
        result_format
        algo
    end
    
    properties(SetAccess = private)
        result
        bestErrorFunctionValue
        numberOfFlops
        convergence
    end    
    
    methods (Access= public)
                
            
        function [] = run_assistant(obj)
            obj.load_beats_simulation;
            obj.load_pems_scenario;
            obj.set_knob_ids;
            obj.set_knob_boundaries;
            obj.ask_for_errorFunction;
            obj.ask_for_algorithm_parameters;
            obj.set_starting_point;
        end
        
        function [] = load_properties_from_xls_file(obj, properties_file_adress)
            %properties file : an xls file containing the algorithmBox
            %properties in the first column and the corresponding
            %expressions to be evaluated by Matlab in the second.
            %Empty cells in the second column will be ignored.
            [useless,xls,useless2] = xlsread(properties_file_adress);
            for i=1:size(xls,1)
                if ~strcmp(xls(i,2),'')
                    setfield(obj, char(xls(i,1)), eval(char(xls(i,2))));
                end
            end
            beats_simulation = BeatsSimulation;
            beats_simulation.load_scenario(obj.scenario_adress);
        end    
               
        function [] = load_beats_simulation(obj)
            scenario_ptr = input('address of the scenario xml file : ', 's');
            obj.beats_simulation = BeatsSimulation;
            obj.beats_simulation.load_scenario(scenario_ptr);
            obj.beats_parameters=input(['Enter a struct containing the beats simulation properties (like "DURATION") : ']);
        end   
        
        function [] = load_pems_scenario(obj)
        end
        
        function [] = set_knob_ids(obj)
            if (size(obj.beats_simulation)~=0)
                numberMissingKnobs = input(strcat(['Among the', ' ', num2str(length(obj.beats_simulation.scenario_ptr.scenario.DemandSet.demandProfile)), ' knobs, how many have to be tuned ? :']));
                for i=1:numberMissingKnobs
                    obj.knobs.knob_ids(1,i)=input(strcat(['knob ', num2str(i),' id :']));
                end
            else
                error('No Beats Simulation loaded');
            end    
        end
        
        function [] = set_knob_boundaries(obj)
            if (isfield(obj.knobs, 'knob_ids'))
                for i=1:length(obj.knobs.knob_ids)
                    obj.knobs.knob_boundaries(1,i)=input(['Knob ', num2str(obj.knobs.knob_ids(i)), ' minimum value : ']);
                    obj.knobs.knob_boundaries(2,i)=input(['Knob ', num2str(obj.knobs.knob_ids(i)), ' maximum value : ']);
                end
            else
                error('The knobs to tune ids : obj.knobs.knob_ids has to be set first.');
            end    
        end    
               
        function [] = ask_for_errorFunction (obj)
            obj.performanceCalculator=input(['Enter the name of a "performanceCalculator" subclass : ']);
            obj.errorCalculator=input(['Enter the name of an "errorCalculator" subclass : ']);
        end  
        
        function [result] = errorFunction(obj, knob_values)
            %knob_values : n x 1 array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            if (size(knob_values,1)==length(obj.knobs.knob_ids))
              obj.beats_simulation.scenario_ptr.set_knob_values(obj.knobs.knob_ids, knob_values)
              obj.beats_simulation.run_beats(obj.beats_parameters);
              obj.performanceCalculator.calculate_from_beats(obj.beats_simulation);
              obj.performanceCalculator.calculate_from_pems(obj.pems);
              result = obj.errorCalculator.calculate(obj.performanceCalculator.result_from_beats, obj.performanceCalculator.result_from_pems);
              obj.result = result;
            else
                error('The matrix with knobs values given does not match with the number of knobs to tune.');
            end    
        end
        
    end   
    
    methods (Abstract, Access = public)
        [] = ask_for_algorithm_parameters(obj)
        [] = run_algorithm(obj)
        [] = set_starting_point(obj);
    end    
end    


