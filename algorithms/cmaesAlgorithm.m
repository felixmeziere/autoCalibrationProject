classdef cmaesAlgorithm < evolutionnaryAlgorithm
    %UNTITLED26 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        parameters_required={'fitfun', 'xstart', 'insigma'};
        parameters_optional={'inopts','varargin'};
        result_format={'xmin', 'fmin', 'counteval', 'stopflag', 'out', 'bestever'};
        algo='cmaes';
    end
    
    properties (Access = public)
        insigma
        inopts
        varargin
    end    
    
    methods (Access = public)
        function [] = ask_for_algorithm_parameters(obj)
            obj.insigma = input(['Enter initial sigma : ']);
            obj.inopts = input(['Enter inopts = Facultative struct array with cmaes properties : ']);
            obj.varargin = input(['Enter varargin = Facultative additional arguments for the fitness function : ']);
        end
        
        function [] = run_algorithm(obj)
            cmaes(@obj.errorFunction, obj.initial_population, obj.insigma);
        end    
    end
    
    methods (Static, Access = public)
        function [] = plot_last()
            plotcmaesdat;
        end
    end
    
    
end

