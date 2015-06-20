classdef (Abstract) EvolutionnaryAlgorithmBox < AlgorithmBox
    %EvolutionnaryAlgorithmBox : subclass of AlgorithBox used only by
    %evolutionnary algorithms.
    %   Contains the properties and methods used by any evolutionnary
    %   algorithm.
    
    properties (Constant)
       
        algorithm_type='Evolutionnary'
        
    end    
    properties (Access = public)
        
        starting_point=[] % (nxp) array containing the initial population : each column is a knob values array.
        normopts=struct;
        initial_population_size;
        
    end    
    
    properties (SetAccess = protected)
        
        population_size
        
    end    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Setting initial population                                         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        function [] = ask_for_starting_point(obj)
            if (obj.knobs.is_loaded)
                 obj.initial_population_size = input(['Size of the population : ']);
                 method='0';
                 while (~strcmp(method,'uniform') && ~strcmp(method,'normal') && ~strcmp(method,'manual')) 
                    method = input(['How should the initial population be created ? (manual/uniform/normal) : '],'s');
                 end
                 if (strcmp(method,'uniform'))
                     obj.set_starting_point('uniform');
                 elseif (strcmp(method,'normal'))
                     for i=1:size(obj.knobs.link_ids,1)
                        obj.normopts.CENTERS(i,1)= input(['Center for knob ', num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(i,1)),' : ']);
                     end
                     for i=1:size(obj.knobs.link_ids,1)
                        obj.normopts.SIGMAS(i,1)= input(['Standard deviation for knob ',num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(i,1)),' : ']);
                     end                        
                     obj.set_starting_point('normal');
                 elseif (strcmp(method,'manual'))
                    for i = 1:obj.initial_population_size;
                        disp(['Individual ', num2str(i)]);
                        for k = 1:size(obj.knobs.link_ids,1)
                            p=-1000;
                            while ~(isnumeric(p) && p >= obj.knobs.boundaries_min(k,1) && p <= obj.knobs.boundaries_max(k,1))
                                p=input(['Knob ', num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(k)), ' : ']);
                                obj.starting_point(k,i)=p;
                                if ~(isnumeric(p) && p >= obj.knobs.boundaries_min(k,1) && p <= obj.knobs.boundaries_max(k,1))
                                    disp('The value is not in the boundaries');
                                end;    
                            end    
                         end    
                    end
                 end
           else error('Knobs ids and boundaries must be set first');
           end    
        end  %This will set the initial population.
        
        
    end
    
    methods (Access = public)%(Access = ?AlgorithmBox)
        
        function [] = set_starting_point(obj, mode)
            %mode should be 'uniform' or 'normal'. In the 'normal' case,
            %the struct obj.normopts must contain : normopts.CENTERS, which is the
            %a (n x 1) array containing the center of the gaussian for
            %each knob, and normopts.SIGMAS, which is an array with the same format
            %containing the standard deviation for each knob. Initial
            %values out of the defined boundaries will be set to the
            %boundaries.
            
            if ~(isempty(obj.knobs.link_ids) || isempty(obj.knobs.boundaries_min) || isempty(obj.knobs.boundaries_max))
                if (strcmp(mode, 'uniform'))
                    obj.starting_point=rand(size(obj.knobs.link_ids,1),obj.initial_population_size);
                    disp('Initial Population with uniform distribution :');
                    for i = 1:size(obj.knobs.link_ids,1)
                        obj.starting_point(i,:)=obj.starting_point(i,:)*(obj.knobs.boundaries_max(i,1)-obj.knobs.boundaries_min(i,1));
                        obj.starting_point(i,:)=obj.starting_point(i,:) + obj.knobs.boundaries_min(i,1);
                        disp (strcat(['Knob ', num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(i,1)),' : ']));
                        disp(obj.starting_point (i,:));
                    end
                    obj.initialization_method = 'uniform';
                    obj.normopts.CENTERS='';
                    obj.normopts.SIGMAS='';
                elseif (strcmp(mode, 'normal'))
                    if (size(obj.normopts.CENTERS,1)==size(obj.knobs.link_ids,1) && size(obj.normopts.SIGMAS,1)==size(obj.knobs.link_ids,1))
                        obj.starting_point=randn(size(obj.knobs.link_ids,1), obj.initial_population_size);
                        disp('Initial Population with normal distribution :');
                        for i = 1:size(obj.knobs.link_ids,1)
                            knob=obj.starting_point(i,:);
                            min=obj.knobs.boundaries_min(i,1);
                            max=obj.knobs.boundaries_max(i,1);
                            knob=knob*obj.normopts.SIGMAS(i,1);
                            knob=knob+obj.normopts.CENTERS(i,1);
                            knob(knob<min)=min;
                            knob(knob>max)=max;
                            obj.starting_point(i,:)=knob;
                            disp (strcat(['Knob ', num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(i,1)),' : ']));
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
            obj.knobs.set_knobs_persistent(obj.starting_point);
        end  %defined in the body
    
        function [] = set_genmean_data(obj)
            obj.error_function.error_genmean_history=[];                                                           
            obj.error_function.errors_genmean_history=[];                                                          
            obj.error_function.contributions_genmean_history=[];
            obj.error_function.error_in_percentage_genmean_history=[];
            obj.error_function.errors_in_percentage_genmean_history=[];
            obj.error_function.contributions_in_percentage_genmean_history=[];
            obj.knobs.knobs_genmean_history=[];
            obj.knobs.zeroten_knobs_genmean_history=[];
            for i=1:obj.numberOfEvaluations
                if i<=size(obj.knobs.zeroten_knobs_history,1)
                    last=i-mod(i,obj.population_size);
                    if (last<=obj.numberOfEvaluations-obj.population_size)
                        range=last+1:last+obj.population_size;
                    else
                        range=last+1-obj.population_size:last;
                    end     
                    obj.knobs.zeroten_knobs_genmean_history(end+1,:)=mean(obj.knobs.zeroten_knobs_history(range,:),1);
                    obj.knobs.knobs_genmean_history(end+1,:)=mean(obj.knobs.knobs_history(range,:),1);
                    obj.error_function.error_genmean_history(end+1,1)=mean(obj.error_function.error_history(range,1),1);
                    obj.error_function.errors_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.errors_history(range,:),1);
                    obj.error_function.contributions_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.contributions_history(range,:),1);
                    obj.error_function.error_in_percentage_genmean_history(end+1,1)=mean(obj.error_function.error_in_percentage_history(range,:),1);
                    obj.error_function.errors_in_percentage_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.errors_in_percentage_history(range,:),1);
                    obj.error_function.contributions_in_percentage_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.contributions_in_percentage_history(range,:),1);
                end     
            end
        end   
    
    end    
    
end

