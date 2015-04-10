classdef fitnessFunctionBox < handle
    %fitnessFunction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        performanceCalculator@performanceCalculator
        errorCalculator@errorCalculator
        beats_simulation@BeatsSimulation
        beats_parameters
        pems
        knobs_id
    end
    
    properties (SetAccess = private)
        result
    end
    
    methods (Access = public)
        
        function [obj] = fitnessFunctionBox(perfCalculator, errCalculator,  knobs_id, beats_parameters, BS, pems)
            obj.performanceCalculator=perfCalculator;
            obj.errorCalculator=errCalculator;
            obj.beats_simulation = BS;
            obj.pems = pems;
            obj.knobs_id = knobs_id;
            obj.beats_parameters = beats_parameters;
        end
        
        function [result] = fitnessFunction(obj, knobs_values)
            %knobs_values : 1 x n array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            if (length(knobs_values)==length(obj.knobs_id))
              obj.beats_simulation.scenario_ptr.set_knobs_values(obj.knobs_id, knobs_values)
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

end

