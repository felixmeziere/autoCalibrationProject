classdef algorithmEvaluation < handle
    %evaluateAlgorithm Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
        testedAlgorithm              %algorithm object
        algorithmScoreMethods        %array of algorithmScore objects
        
        % State of the object ..............
        algorithm_loaded            %boolean
        method_loaded               %boolean
        algorithm_computation_done  %boolean
        score_computation_done      %boolean
        
        % Output.............................
        algorithm_score             %number
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Construction, loading algorithm and score methods                  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        % Construction ......................................
        function [obj] = algorithmEvaluation()
            obj.reset_object();
        end
        
        % Add new score method ............................
        function [obj]=add_score_method(obj, method)
            scoreMethod=eval(method);
            if(isa(scoreMethod, 'algorithmScoreMethod'))
                obj.method_loaded = true;
                obj.algorithmScoreMethods =[obj.algorithmScoreMethods, {scoreMethod}];
            else
                error('Score method does not exist.')
            end
        end
        
        % Set algorithm to score
        function [obj]=set_algorithm_by_name(obj,algorithmName)
            algo=eval(algorithmName);
            if(isa(algo, 'algorithm'))
                obj.algorithm_loaded = true;
                obj.testedAlgorithm=algo;
            else
                error('Algorithm does not exist.')
            end
        end
        
        function [obj]=set_algorithm_by_object(obj,algorithmObject)
            if(isa(algorithmObject, 'algorithm'))
                obj.algorithm_loaded = true;
                obj.algorithm=algorithmObject;
            else
                error('Algorithm does not exist.')
            end
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Running the algorithm and the evaluation                           %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        % Run algorithm and score it
        function [obj]=run(obj,param)
            

           
        end    
   
        
        function [obj]=reset_simulation(obj)
            obj.reset_simdata();
        end
        
        function [obj]=load_simulation_output(obj,outprefix)
                        
            if(obj.sim_output_loaded)
                warning('overwriting existing simulation data.')
                obj.reset_simdata();
            end
            
            disp('Loading simulation result')
            
            % ... vehicle type names
            vtypes = obj.scenario_ptr.get_vehicle_types();
            
            % load data
            obj.time = load(sprintf('%s_%s_0.txt',outprefix,'time'));
            numlinks = length(obj.scenario_ptr.scenario.NetworkSet.network(1).LinkList.link);
            numvt = length(vtypes);
            
            obj.density_veh = cell(1,numvt);
            obj.outflow_veh = cell(1,numvt);
            obj.inflow_veh = cell(1,numvt);
            
            [obj.density_veh{1:numvt}] = deal(nan(length(obj.time),numlinks));
            [obj.outflow_veh{1:numvt}] = deal(nan(length(obj.time),numlinks));
            [obj.inflow_veh{1:numvt}] = deal(nan(length(obj.time),numlinks));
            for v=1:numvt
                obj.density_veh{v} = load(sprintf('%s_%s_%s_0.txt',outprefix,'density',vtypes(v).name));
                obj.outflow_veh{v} = load(sprintf('%s_%s_%s_0.txt',outprefix,'outflow',vtypes(v).name));
                obj.inflow_veh{v} = load(sprintf('%s_%s_%s_0.txt',outprefix,'inflow',vtypes(v).name));
            end
            
            obj.sim_output_loaded = true;
            
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  private methods                                                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = private)
        
        function [obj] = reset_object(obj)
            obj.testedAlgorithm = algorithm;
            obj.algorithmScoreMethods={};
            obj.method_loaded = false;
            obj.algorithm_loaded = false;
            obj.algorithm_computation_done = false;
            obj.score_computation_done = false;
        end
        
  
    end
    
end

