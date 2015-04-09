classdef algorithmBox < handle
    %algorithm Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        algorithm@algorithm
        fitFunction
        beatsScenario
        pemsScenario
        initialPopulation
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
        function [obj] = AlgorithmBox()
        end    
        
        function [obj] = run_algorithm_and_compute_error(obj)
        end    
    end
    
    methods (Access = private)
        
        
    end    
end

