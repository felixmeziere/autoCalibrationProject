classdef (Abstract) evolutionnaryAlgorithm < algorithmBox
    %evolutionnaryalgorithm Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Access = public)
        initial_population=[]
    end    
    
    properties (SetAccess = protected)
        bestEverIndividual
        bestEverValue
    end
    
    methods (Access = public)
        function [] = set_starting_point(obj)
            %This will set the initial population.
            method='0';
            while (~strcmp(method,'random') && ~strcmp(method,'manual')) 
                method = input(['How should the initial population be created ? (random/manual) : '],'s');
            end
            if (strcmp(method,'random'))
            end
            if (strcmp(method,'manual'))
                sizePopulation = input(['Size of the population : ']);
                for i = 1:sizePopulation
                    disp(['Individual ', num2str(i)]);
                    for k = 1:length(obj.knobs.knob_ids)
                        p=-1000;
                        while ~(isnumeric(p) && p >= obj.knobs.knob_boundaries(1,k) && p <= obj.knobs.knob_boundaries(2,k))
                            p=input(['Knob ', num2str(obj.knobs.knob_ids(k)), ' : ']);
                            obj.initial_population(k,i)=p;
                            if ~(isnumeric(p) && p >= obj.knobs.knob_boundaries(1,k) && p <= obj.knobs.knob_boundaries(2,k))
                                disp('The value is not in the boundaries');
                            end;    
                        end    
                    end    
                end
                obj.parameters.xstart=obj.initial_population;
            end    
        end 

    end
    
end

