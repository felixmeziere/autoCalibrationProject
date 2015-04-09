classdef fitnessFunction < handle
    %fitnessFunction Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (SetAccess = private)
        performanceCalculator@performanceCalculator
        errorCalculator@errorCalculator
        result
        BSProperties
        BS@BeatsSimulation
        initialKnobs                       % 2 x number of missing knobs array. Missing knob number in the first row and corresponding values in the second row.
        pems
    end
    
    methods (Access = public)
        
        function [obj] = fitnessFunction(perfCalculator, errCalculator, BSProperties, BS ,pems, initialKnobs)
            obj.performanceCalculator=perfCalculator;
            obj.errorCalculator=errCalculator;
            obj.BS = BS;
            obj.Pems = Pems;
            obj.BSProperties = BSProperties;
            obj.initialKnobs = initialKnobs;
            pems.run_simulation;
        end
        
        function [result] = compute_error(obj, Knobs)
              changeScenario(obj.BS, Knobs);
              obj.performanceCalculator.calculate_from_beats(obj.BS);
              obj.performanceCalculator.calculate_from_pems(obj.Pems);
              result = obj.errorCalculator.calculate(obj.performanceCalculator.result_from_beats, obj.performanceCalculator.result_from_pems);
              obj.result = result;
        end    
    end
    
end

