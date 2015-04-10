classdef cmaesAlgorithm < algorithm
    %UNTITLED26 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        parameters_required={'fitfun', 'xstart', 'insigma'};
        parameters_optional={'inopts','varargin'};
        result_format={'xmin', 'fmin', 'counteval', 'stopflag', 'out', 'bestever'};
        algo='cmaes';
    end
    
    properties (Access = public)
        initial_population=[]
        fitnessFunctionBox@fitnessFunctionBox
    end    
        
    methods (Access = public)
        function [] = set_initial_population(obj)
            method='0';
            while (~strcmp(method,'random') && ~strcmp(method,'manual')) 
                method = input('How should the initial population be created ? (random/manual)','s');
            end
            if (strcmp(method,'random'))
            end
            if (strcmp(method,'manual'))
                sizePopulation = input(['Size of the population : ']);
                for i = 1:sizePopulation
                    disp(['Individual ', num2str(i)]);
                    for k = 1:length(obj.knobs.knobs_id)
                        p=-1000;
                        while ~(isnumeric(p) && p >= obj.knobs.knobs_boundaries(1,k) && p <= obj.knobs.knobs_boundaries(2,k))
                            p=input(['Knob ', num2str(obj.knobs.knobs_id(k)), ' : ']);
                            obj.initial_population(k,i)=p;
                            if ~(isnumeric(p) && p >= obj.knobs.knobs_boundaries(1,k) && p <= obj.knobs.knobs_boundaries(2,k))
                                disp('The value is not in the boundaries');
                            end;    
                        end    
                    end    
                end
                obj.parameters.xstart=obj.initial_population;
            end    
        end 
        function [obj] = cmaesAlgorithm(knobs)
            obj.knobs=knobs;
        end
        function [xmin,fmin,counteval, stopflag, out, bestever] = cmaes(obj, insigma, inopts, varargin )
            cmaes(obj.fitnessFunctionBox.fitnessFunction, obj.initial_population, insigma, inopts, varargin );
        end    
    end
    
    methods (Static, Access = public)
        
        function [] = plot()
            plotcmaesdat;
        end
    end
    
    
end

