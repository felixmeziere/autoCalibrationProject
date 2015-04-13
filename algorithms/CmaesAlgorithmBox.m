classdef CmaesAlgorithmBox < EvolutionnaryAlgorithmBox
    %CmaesAlgorithmBox : Subclass of EvolutionnaryAlgorithmBox 
    %   Contains the specific properties and methods used by the cmaes
    %   algorithm.
    
    properties (Access = public)
        insigma
        varargin
    end    
    
    properties (Hidden, SetAccess = private)
        inopts=struct;
    end    
    
    properties (SetAccess = private)
        bestEver
    end    
    methods (Access = public)
        function [] = ask_for_algorithm_parameters(obj)
            obj.insigma = input(['Enter initial standard deviation for cmaes : ']);
            obj.maxIter= input(['Enter the maximum number of cmaes iterations : ']);
            obj.maxEval = input(['Enter the maximum number of beats simulations runned : ']);
            obj.stopFValue = input(['Enter the error value under which the algorithm will stop : ']);
        end
        
        function [] = run_algorithm(obj)
            obj.inopts.MaxFunEvals = obj.maxEval;
            obj.inopts.MaxIter = obj.maxIter;
            obj.inopts.StopFitness = obj.stopFValue;
            obj.inopts.UBounds = obj.knobs.knob_boundaries_max;
            obj.inopts.LBounds = obj.knobs.knob_boundaries_min;
            [obj.bestEverPoint, obj.bestEverErrorFunctionValue, obj.numberOfEvaluations, obj.stopFlag, obj.result, obj.bestEver]=cmaes(@obj.errorFunction, obj.initial_population, obj.insigma, obj.inopts);
        end    
    end
    
    methods (Static, Access = public)
        function [] = plot() % plots data on the last running of cmaes.
            plotcmaesdat;
        end
    end
    
    
end

