classdef (Abstract) EvolutionnaryAlgorithmBox < AlgorithmBox
    %EvolutionnaryAlgorithmBox : subclass of AlgorithBox used only by
    %evolutionnary algorithms.
    %   Contains the properties and methods used by any evolutionnary
    %   algorithm.
    
    %Required for loading from xls :
    
    
    %    -> population_size | [integer] 
    %       Does not change much. Setting it to 4 + floor(3*log([number of
    %       knobs])) which is the size used in CMAES is a good idea.
    %    -> initialization_method | ['uniform'], ['normal'] or ['manual'].
    %       For CMAES, 'uniform' should be used in order to center the starting_point : the initialization doesn't matter very much if sigma is set between reasonable bound (2:5)
    %    -> maxIter | [integer]


    
    %    -> starting_point | [knob#1value;knob#2value;...;knob#nvalue] 
    %       REQUIRED ONLY IF obj.initialization_method is 'manual'
    %    -> normopts.SIGMAS | [sigma#1;sigma#2;...;sigma#n]
    %       REQUIRED ONLY IF obj.initialization_method is 'normal'
    %    -> normopts.CENTERS | [center#1;center#2;...;center#n]
    %       REQUIRED ONLY IF obj.initialization_method is 'normal'

    
    properties (Constant)
       
        algorithm_type='Evolutionnary'
        
    end   
    
    properties (Access = public)
        
        starting_point=[] % (nxp) array containing the initial population : each column is a knob values array.
        normopts=struct; %struct whose fields are : 'CENTERS' containing the center of the gaussian generating the starting point for each knob and 'SIGMAS' containing their standard deviation. Scale is real scale (not zero-ten). Normal distribution initialization is useless with CMAES which is not initialization dependent if its initial standard deviation is reasonable (between 2 and 5).
        %initial_population_size %initial population size. CMAES will take the mean of this and then use its own population size (this is not very important).
        maxIter % maximum number of generations of the algorithm : each generation is several beats executions (the size of the population). Default population size for CMAES : 4 + floor(3*log([number of knobs]))

    end    
    
    properties (SetAccess = ?AlgorithmBox)
        
        population_size=0; %used to build "generation mean" data. Values is 4 + floor(3*log([number of knobs])) for CMAES.
        
    end    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Setting initial population                                         %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        function [] = ask_for_starting_point(obj)
            if (obj.knobs.is_loaded)
                 obj.population_size = input(['Size of the population : ']);
                 method='0';
                 while (~strcmp(method,'uniform') && ~strcmp(method,'normal') && ~strcmp(method,'manual')) 
                    method = input(['How should the initial population be created ? (manual/uniform/normal) : '],'s');
                 end
                 if (strcmp(method,'uniform'))
                     obj.set_starting_point('uniform');
                 elseif (strcmp(method,'normal'))
                     for i=1:obj.knobs.nKnobs
                        obj.normopts.CENTERS(i,1)= input(['Center for knob ', num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(i,1)),' : ']);
                     end
                     for i=1:obj.knobs.nKnobs
                        obj.normopts.SIGMAS(i,1)= input(['Standard deviation for knob ',num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(i,1)),' : ']);
                     end                        
                     obj.set_starting_point('normal');
                 elseif (strcmp(method,'manual'))
                    for i = 1:obj.population_size;
                        disp(['Individual ', num2str(i)]);
                        for k = 1:obj.knobs.nKnobs
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
        end  %Ask for the settings to build the initial population in the command prompt.
        
    end
    
    methods (Access = protected)
        
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
                    obj.starting_point=rand(obj.knobs.nKnobs,obj.population_size);
                    disp('Initial Population with uniform distribution :');
                    for i = 1:obj.knobs.nKnobs
                        obj.starting_point(i,:)=obj.starting_point(i,:)*(obj.knobs.boundaries_max(i,1)-obj.knobs.boundaries_min(i,1));
                        obj.starting_point(i,:)=obj.starting_point(i,:) + obj.knobs.boundaries_min(i,1);
                        disp (strcat(['Knob ', num2str(obj.knobs.demand_ids(i,1)),' | ',num2str(obj.knobs.link_ids(i,1)),' : ']));
                        disp(obj.starting_point (i,:));
                    end
                    obj.initialization_method = 'uniform';
                    obj.normopts.CENTERS='';
                    obj.normopts.SIGMAS='';
                elseif (strcmp(mode, 'normal'))
                    if (size(obj.normopts.CENTERS,1)==obj.knobs.nKnobs && size(obj.normopts.SIGMAS,1)==obj.knobs.nKnobs)
                        obj.starting_point=randn(obj.knobs.nKnobs, obj.population_size);
                        disp('Initial Population with normal distribution :');
                        for i = 1:obj.knobs.nKnobs
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
            if obj.knobs.is_uncertainty_for_monitored_ramps
                obj.starting_point=[obj.starting_point;ones(size(obj.knobs.monitored_ramp_link_ids,1),obj.population_size)];
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
            obj.knobs.monitored_ramp_knobs_genmean_history=[];
            obj.knobs.monitored_ramp_zeroten_knobs_genmean_history=[];
            obj.knobs.knobs_genmean_history=[];
            obj.knobs.zeroten_knobs_genmean_history=[];
            for i=0:obj.numberOfEvaluations-1
                if i<=size(obj.knobs.zeroten_knobs_history,1)-1
                    last=i-mod(i,obj.population_size);
                    if (last<=obj.numberOfEvaluations-obj.population_size)
                        range=last+1:last+obj.population_size;
                    else
                        range=last+1-obj.population_size:last;
                    end     
                    obj.knobs.zeroten_knobs_genmean_history(end+1,:)=mean(obj.knobs.zeroten_knobs_history(range,:),1);
                    obj.knobs.knobs_genmean_history(end+1,:)=mean(obj.knobs.knobs_history(range,:),1);
                    if obj.knobs.is_uncertainty_for_monitored_ramps
                        obj.knobs.monitored_ramp_knobs_genmean_history(end+1,:)=mean(obj.knobs.monitored_ramp_knobs_history(range,:),1);
                        obj.knobs.monitored_ramp_zeroten_knobs_genmean_history(end+1,:)=mean(obj.knobs.monitored_ramp_zeroten_knobs_history(range,:),1);
                    end
                    obj.error_function.error_genmean_history(end+1,1)=mean(obj.error_function.error_history(range,1),1);
                    obj.error_function.errors_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.errors_history(range,:),1);
                    obj.error_function.contributions_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.contributions_history(range,:),1);
                    obj.error_function.error_in_percentage_genmean_history(end+1,1)=mean(obj.error_function.error_in_percentage_history(range,:),1);
                    obj.error_function.errors_in_percentage_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.errors_in_percentage_history(range,:),1);
                    obj.error_function.contributions_in_percentage_genmean_history(end+1,1:size(obj.error_function.performance_calculators,2))=mean(obj.error_function.contributions_in_percentage_history(range,:),1);
                end     
            end
        end   %set the "generation mean" data in obj.knobs and obj.error_function. Each individual (i.e. BeATS execution) has the mean value of its generation.
    
    end    
    
end

