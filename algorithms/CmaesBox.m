classdef CmaesBox < EvolutionnaryAlgorithmBox
    %CmaesAlgorithmBox : Subclass of EvolutionnaryAlgorithmBox 
    %   Contains the specific properties and methods used by the cmaes
    %   algorithm.
    
    properties (Constant)
        
        algorithm_name='cmaes';
        
    end
    
    properties (Access = public)
        
        insigma
        
    end    
    
    properties (Hidden, SetAccess = private)
        
        inopts=struct;
        
    end    
    
    properties (SetAccess = private)
        
        bestEver
        
    end    
    
    methods (Access = public)

        function [] = ask_for_algorithm_parameters(obj)
            obj.insigma = input(['Enter initial standard deviation for cmaes (all knob boundaries have been set to a zero to ten scale so value should be between 2 and 5): ']);
            obj.maxIter= input(['Enter the maximum number of cmaes iterations : ']);
            obj.maxEval = input(['Enter the maximum number of beats simulations runs : ']);
            obj.stopFValue = input(['Enter the error value under which the algorithm will stop : ']);
        end  % defined in AlgorithmBox
        
        function [] = set_cmaes_inopts(obj, inopts)
            %to set additional inopts. Be careful, MaxFunEvals, MaxIter,
            %StopFitness, UBounds and LBounds will be overwritten by their 
            %equivalent in AlorithmBox when running the algorithm.
            if (isa(inopts,'struct'))
                obj.inopts=inopts;
            else
                error('inopts must be a struct array');
            end    
        end  % set inopts, a specific parameters struct for cmaes.
        
        function [] = set_cmaes_inopts_field(obj, FIELD, value)
            %to set an additional inopts field. Be careful, MaxFunEvals, MaxIter,
            %StopFitness, UBounds and LBounds will be overwritten by their 
            %equivalent in AlorithmBox when running the algorithm.
            eval(strcat('obj.inopts.',FIELD,'=',num2str(value),';'));
        end  % set a field of inopts.
        
        function [] = run_algorithm(obj)
              obj.numberOfIterations=1;
              obj.numberOfEvaluations=1;
              obj.reset_for_new_run;
              obj.inopts.MaxFunEvals = obj.maxEval;
              obj.inopts.MaxIter = obj.maxIter;
              obj.inopts.StopFitness = obj.stopFValue;
              obj.inopts.UBounds = ones(size(obj.knobs.link_ids,1),1)*10;
              obj.inopts.LBounds = zeros(size(obj.knobs.link_ids,1),1);
              xstart=obj.knobs.rescale_knobs(obj.starting_point,1);
              [lastPoint, lastValue, obj.numberOfEvaluations, obj.stopFlag, obj.out, bestEver]=cmaes(@(x)obj.evaluate_error_function(x,1), xstart, obj.insigma, obj.inopts);  
              load variablescmaes.mat
              bestEver.x=obj.knobs.rescale_knobs(bestEver.x,0);
              obj.bestEverPoint=bestEver.x;
              obj.bestEver=bestEver;
              obj.bestEverErrorFunctionValue=bestEver.f;
              obj.numberOfIterations=countiter;
                obj.save_data;
        end   % defined in AlgorithmBox   
   
        function [] = set_result_for_xls(obj)
            %This function should be changed manually to fit the format
            %choosen in the excel file.
            %load 'variablescmaes.mat';
            obj.result_for_xls{1}=obj.error_function.name;
            obj.result_for_xls{2}=obj.error_function.error_calculator.norm_name;
            obj.result_for_xls{3}=size(obj.starting_point,2);
            obj.result_for_xls{4}=obj.initialization_method;
            obj.result_for_xls{5}=Utilities.double2char(obj.normopts.CENTERS);
            obj.result_for_xls{6}=Utilities.double2char(obj.normopts.SIGMAS);
            obj.result_for_xls{7}=Utilities.double2char(obj.starting_point);
            obj.result_for_xls{8}=obj.insigma;
            obj.result_for_xls{9}=obj.knobs.underevaluation_tolerance_coefficient;
            obj.result_for_xls{10}=obj.knobs.overevaluation_tolerance_coefficient;
            obj.result_for_xls{11}=Utilities.double2char(obj.knobs.boundaries_min);
            obj.result_for_xls{12}=Utilities.double2char(obj.knobs.boundaries_max);
            obj.result_for_xls{13}=obj.maxIter;
            obj.result_for_xls{14}=obj.maxEval;
            obj.result_for_xls{15}=obj.stopFValue;
            obj.result_for_xls{16}=Utilities.double2char(obj.bestEverPoint);
            obj.result_for_xls{17}=obj.bestEverErrorFunctionValue;
            obj.result_for_xls{18}=Utilities.cellArray2char(obj.stopFlag);
            obj.result_for_xls{19}=obj.numberOfIterations;
            obj.result_for_xls{20}=obj.numberOfEvaluations;
            obj.result_for_xls{21}=obj.convergence;
        end % defined in AlgorithmBox
       
    end
    
    methods (Static, Access = public)
        function [] = plot_algorithm_data(figureNumber) % plots data on the last running of cmaes.
            if nargin==1
                plotcmaesdat(figureNumber)
            else    
                plotcmaesdat;
            end
        end
    end
        
end

