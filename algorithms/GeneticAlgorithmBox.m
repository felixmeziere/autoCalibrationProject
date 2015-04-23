classdef GeneticAlgorithmBox < EvolutionnaryAlgorithmBox

    
    properties (Constant)
        
        algorithm_name='genetic';
        
    end
    
    properties (Access = public)
        
        
        
    end    
    
    properties (Hidden, SetAccess = private)
        
        inopts=struct;
        
    end    
    
    properties (SetAccess = private)
        
        bestEver
        
    end    
    
    methods
        
        function [] = ask_for_algorithm_parameters(obj)
            obj.insigma = input(['Enter initial standard deviation for cmaes : ']);
            obj.maxIter= input(['Enter the maximum number of cmaes iterations : ']);
            obj.maxEval = input(['Enter the maximum number of beats simulations runs : ']);
            obj.stopFValue = input(['Enter the error value under which the algorithm will stop : ']);
        end  % defined in AlgorithmBox
        
        function [] = run_algorithm(obj)
              [obj.bestEverPoint, obj.bestEverErrorFunctionValue, obj.numberOfEvaluations, obj.stopFlag, obj.out, obj.bestEver]=optimtool;
        end   % defined in AlgorithmBox   
        
        function [] = set_result_for_xls(obj)
            %This function should be changed manually to fit the format
            %choosen in the excel file.
            load 'variablescmaes.mat';
            obj.result_for_xls{1}=obj.performance_calculator.name;
            obj.result_for_xls{2}=obj.error_calculator.name;
            obj.result_for_xls{3}=size(obj.starting_point,2);
            obj.result_for_xls{4}=obj.initialization_method;
            obj.result_for_xls{5}=Utilities.double2char(obj.normopts.CENTERS);
            obj.result_for_xls{6}=Utilities.double2char(obj.normopts.SIGMAS);
            obj.result_for_xls{7}=obj.insigma;
            obj.result_for_xls{8}=Utilities.double2char(obj.knobs.knob_boundaries_min);
            obj.result_for_xls{9}=Utilities.double2char(obj.knobs.knob_boundaries_max);
            obj.result_for_xls{10}=obj.maxIter;
            obj.result_for_xls{11}=obj.maxEval;
            obj.result_for_xls{12}=obj.stopFValue;
            obj.result_for_xls{13}=Utilities.double2char(obj.bestEverPoint);
            obj.result_for_xls{14}=obj.bestEverErrorFunctionValue;
            obj.result_for_xls{15}=Utilities.cellArray2char(obj.stopFlag);
            obj.result_for_xls{16}=obj.numberOfFlops;
            obj.result_for_xls{17}=obj.numberOfEvaluations;
            obj.result_for_xls{18}=obj.convergence;
        end % defined in AlgorithmBox
               
    end
    
end

