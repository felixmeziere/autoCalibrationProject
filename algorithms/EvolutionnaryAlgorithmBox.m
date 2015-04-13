classdef (Abstract) EvolutionnaryAlgorithmBox < AlgorithmBox
    %EvolutionnaryAlgorithmBox : subclass of AlgorithBox used only by
    %evolutionnary algorithms.
    %   Contains the properties and methods used by any evolutionnary
    %   algorithm.
    
    properties (Access = public)
        initial_population=[] % (nxp) array containing the initial population : each column is a knob values array.
    end    

    methods (Access = public)
        function [] = ask_for_starting_point(obj)
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
                    for k = 1:size(obj.knobs.knob_ids,1)
                        p=-1000;
                        while ~(isnumeric(p) && p >= obj.knobs.knob_boundaries_min(k,1) && p <= obj.knobs.knob_boundaries_max(k,1))
                            p=input(['Knob ', num2str(obj.knobs.knob_ids(k)), ' : ']);
                            obj.initial_population(k,i)=p;
                            if ~(isnumeric(p) && p >= obj.knobs.knob_boundaries_min(k,1) && p <= obj.knobs.knob_boundaries_max(k,1))
                                disp('The value is not in the boundaries');
                            end;    
                        end    
                    end    
                end
             end    
        end 
    end
    
end

