classdef (Abstract) EvolutionnaryAlgorithmBox < AlgorithmBox
    %EvolutionnaryAlgorithmBox : subclass of AlgorithBox used only by
    %evolutionnary algorithms.
    %   Contains the properties and methods used by any evolutionnary
    %   algorithm.
    
    properties (Access = public)
        
        starting_point=[] % (nxp) array containing the initial population : each column is a knob values array.
        normopts=struct;
        population_size;
        
    end    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Setting initial population                                         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        function [] = ask_for_starting_point(obj)
          if (obj.is_set_knobs)
            obj.population_size = input(['Size of the population : ']);
            method='0';
            while (~strcmp(method,'uniform') && ~strcmp(method,'normal') && ~strcmp(method,'manual')) 
                method = input(['How should the initial population be created ? (manual/uniform/normal) : '],'s');
            end
                 if (strcmp(method,'uniform'))
                     obj.set_starting_point('uniform');
                 elseif (strcmp(method,'normal'))
                     for i=1:size(obj.knobs.knob_link_ids,1)
                        obj.normopts.CENTERS(i,1)= input(['Center for knob ', num2str(obj.knobs.knob_demand_ids(i,1)),' | ',num2str(obj.knobs.knob_link_ids(i,1)),' : ']);
                     end
                     for i=1:size(obj.knobs.knob_link_ids,1)
                        obj.normopts.SIGMAS(i,1)= input(['Standard deviation for knob ',num2str(obj.knobs.knob_demand_ids(i,1)),' | ',num2str(obj.knobs.knob_link_ids(i,1)),' : ']);
                     end                        
                     obj.set_starting_point('normal');
                 end  
            if (strcmp(method,'manual'))
                for i = 1:obj.population_size;
                    disp(['Individual ', num2str(i)]);
                    for k = 1:size(obj.knobs.knob_link_ids,1)
                        p=-1000;
                        while ~(isnumeric(p) && p >= obj.knobs.knob_boundaries_min(k,1) && p <= obj.knobs.knob_boundaries_max(k,1))
                            p=input(['Knob ', num2str(obj.knobs.knob_demand_ids(i,1)),' | ',num2str(obj.knobs.knob_link_ids(k)), ' : ']);
                            obj.starting_point(k,i)=p;
                            if ~(isnumeric(p) && p >= obj.knobs.knob_boundaries_min(k,1) && p <= obj.knobs.knob_boundaries_max(k,1))
                                disp('The value is not in the boundaries');
                            end;    
                        end    
                    end    
                end
            end
            else error('Knobs ids and boundaries must be set first');
            end    
        end  %This will set the initial population.
        
        function [] = set_starting_point(obj, mode)
            %mode should be 'uniform' or 'normal'. In the 'normal' case,
            %the struct obj.normopts must contain : normopts.CENTERS, which is the
            %a (n x 1) array containing the center of the gaussian for
            %each knob, and normopts.SIGMAS, which is an array with the same format
            %containing the standard deviation for each knob. Initial
            %values out of the defined boundaries will be set to the
            %boundaries.
            
            if ~(isempty(obj.knobs.knob_link_ids) || isempty(obj.knobs.knob_boundaries_min) || isempty(obj.knobs.knob_boundaries_max))
                if (strcmp(mode, 'uniform'))
                    obj.starting_point=rand(size(obj.knobs.knob_link_ids,1),obj.population_size);
                    disp('Initial Population :');
                    for i = 1:size(obj.knobs.knob_link_ids,1)
                        obj.starting_point(i,:)=obj.starting_point(i,:)*(obj.knobs.knob_boundaries_max(i,1)-obj.knobs.knob_boundaries_min(i,1));
                        obj.starting_point(i,:)=obj.starting_point(i,:) + obj.knobs.knob_boundaries_min(i,1);
                        disp (strcat(['Knob ', num2str(obj.knobs.knob_demand_ids(i,1)),' | ',num2str(obj.knobs.knob_link_ids(i,1)),' : ']));
                        disp(obj.starting_point (i,:));
                    end
                    obj.initialization_method = 'uniform';
                    obj.normopts.CENTERS='';
                    obj.normopts.SIGMAS='';
                elseif (strcmp(mode, 'normal'))
                    if (size(obj.normopts.CENTERS,1)==size(obj.knobs.knob_link_ids,1) && size(obj.normopts.SIGMAS,1)==size(obj.knobs.knob_link_ids,1))
                        obj.starting_point=randn(size(obj.knobs.knob_link_ids,1), obj.population_size);
                        disp('Initial Population :');
                        for i = 1:size(obj.knobs.knob_link_ids,1)
                            knob=obj.starting_point(i,:);
                            min=obj.knobs.knob_boundaries_min(i,1);
                            max=obj.knobs.knob_boundaries_max(i,1);
                            knob=knob*obj.normopts.SIGMAS(i,1);
                            knob=knob+obj.normopts.CENTERS(i,1);
                            knob(knob<min)=min;
                            knob(knob>max)=max;
                            obj.starting_point(i,:)=knob;
                            disp (strcat(['Knob ', num2str(obj.knobs.knob_demand_ids(i,1)),' | ',num2str(obj.knobs.knob_link_ids(i,1)),' : ']));
                            disp(obj.starting_point (i,:));
                        end
                        obj.initialization_method='normal';
                    else
                        error('normopts is not in the right format or does not contain the right fields. Please refer to the method code in EvolutionnaryAlgorithmBox.m');
                    end
                elseif (strcmp(mode,'manual'))
                    disp('Starting point is set manually.');
                else error('The second argument of "set_starting_point" must be "uniform", "normal" or "manual".');    
                end 
            else
                error('Missing information on knob ids or boundaries, please set them before.');
            end    
        end  %defined in the body
        
    end
    
end

