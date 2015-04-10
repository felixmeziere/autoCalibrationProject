classdef algorithmBox < handle
    %algorithm Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        algorithm@algorithm
        beats_simulation@BeatsSimulation
        pemsScenario
        knobs=struct;
        maxEval=90;
        maxIter=30;
        stopFlag=1000;
    end
    
    properties(SetAccess = private)
        result
        bestEverIndividual
        bestEverValue
        numberOfFlops
        convergence
    end    
    
    methods (Access= public)
        function [] = AlgorithmBox()
            set_knobs_id();
            set_knobs_boundaries();
        end    
        
        function [] = set_knobs_id(obj)
            numberMissingKnobs = input(strcat(['Among the', ' ', num2str(length(obj.beats_simulation.scenario_ptr.scenario.DemandSet.demandProfile)), ' knobs, how many have to be tuned ? :']));
            for i=1:numberMissingKnobs
                obj.knobs.knobs_id(1,i)=input(strcat(['knob ', num2str(i),' :']));
            end
        end
        
        function [] = set_knobs_boundaries(obj)
            if (isfield(obj.knobs, 'knobs_id'))
                for i=1:length(obj.knobs.knobs_id)
                    obj.knobs.knobs_boundaries(1,i)=input(['Knob ', num2str(obj.knobs.knobs_id(i)), ' minimum value : ']);
                    obj.knobs.knobs_boundaries(2,i)=input(['Knob ', num2str(obj.knobs.knobs_id(i)), ' maximum value : ']);
                end
            else
                error('The knobs to tune ids : obj.knobs.knobs_id has to be set first.');
            end    
        end    
        
        function [] = run_algorithm_and_compute_error(obj)
        end    
    
        function [] = show_parameters(obj)
           disp(strcat(['Required parameters for ', obj.algorithm.algo,' :']));
           disp(obj.algorithm.parameters_required);
           disp('Optional parameters : ');
           disp(obj.algorithm.parameters_optional);
        end
        
        function [] = ask_for_parameters(obj)
            disp(strcat(['Required parameters for ', obj.algorithm.algo,' :']));
            for i=1:length(obj.algorithm.parameters_required);
                obj.algorithm.parameters(i)=input([char(obj.algorithm.parameters_required(i)),' : ']);
            end
            disp('Optional parameters : ');
            for i=1:length(obj.algorithm.parameters_optional);
                obj.algorithm.parameters(i)=input([char(obj.algorithm.parameters_optional(i)),' : ']);
            end 
        end    
    end    
        
        
end    


