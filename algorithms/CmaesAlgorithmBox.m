classdef CmaesAlgorithmBox < EvolutionnaryAlgorithmBox
    %CmaesAlgorithmBox : Subclass of EvolutionnaryAlgorithmBox 
    %   Contains the specific properties and methods used by the cmaes
    %   algorithm.
    
    properties (Constant)
        algo='cmaes';
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
            [obj.bestEverPoint, obj.bestEverErrorFunctionValue, obj.numberOfEvaluations, obj.stopFlag, obj.out, obj.bestEver]=cmaes(@obj.errorFunction, obj.initial_population, obj.insigma, obj.inopts);
            obj.set_result_xls;
        end    
        
        function [] = set_cmaes_inopts(obj, inopts)
            %to set additional inopts. Be careful, MaxFunEvals, MaxIter,
            %StopFitness, UBounds and LBounds will be overwritten by their 
            %equivalent in AlorithmBox when running the algorithm.
            if (isa(inopts,'struct'))
                obj.inopts=inopts;
            else
                error('inopts must be a struct array');
            end    
        end    
        
        function [] = set_cmaes_inopts_field(obj, FIELD, value)
            %to set an additional inopts field. Be careful, MaxFunEvals, MaxIter,
            %StopFitness, UBounds and LBounds will be overwritten by their 
            %equivalent in AlorithmBox when running the algorithm.
            eval(strcat('obj.inopts.',FIELD,'=',num2str(value),';'));
        end    
        
        function [] = send_result_to_xls(obj, filename)
            %the legend in the xls file should be written manually.
            [useless1,useless2,xls]=xlsread(filename,'cmaes');
            id{1}=xls{1,52};
            num=id{1}+1;
            xlswrite(filename,id,'cmaes', strcat('A',num2str(num)));
            xlswrite(filename, obj.result_xls, 'cmaes', strcat('B',num2str(num)));
            xlswrite(filename, num,'cmaes','AZ2');
        end    
        
    end
    
    methods (Static, Access = public)
        function [] = plot() % plots data on the last running of cmaes.
            plotcmaesdat;
        end
    end
    
    methods (Access = private)
        
        function [] = set_result_xls(obj)
            %This function should be changed manually to fit the format
            %choosen in the excel file.
            load 'variablescmaes.mat';
            obj.result_xls{1}=size(obj.initial_population,2);
            obj.result_xls{2}=obj.initialization_method;
            obj.result_xls{3}=Utilities.double2char(obj.normopts.CENTERS);
            obj.result_xls{4}=Utilities.double2char(obj.normopts.SIGMAS);
            obj.result_xls{5}=obj.insigma;
            obj.result_xls{6}=Utilities.double2char(obj.knobs.knob_boundaries_min);
            obj.result_xls{7}=Utilities.double2char(obj.knobs.knob_boundaries_max);
            obj.result_xls{8}=obj.maxIter;
            obj.result_xls{9}=obj.maxEval;
            obj.result_xls{10}=obj.stopFValue;
            obj.result_xls{11}=Utilities.double2char(obj.bestEverPoint);
            obj.result_xls{12}=Utilities.double2char(obj.bestEverErrorFunctionValue);
            obj.result_xls{13}=char(obj.stopFlag);
            obj.result_xls{14}=obj.numberOfFlops;
            obj.result_xls{15}=obj.numberOfEvaluations;
            obj.result_xls{16}=obj.convergence;
        end
    end     
    
end

