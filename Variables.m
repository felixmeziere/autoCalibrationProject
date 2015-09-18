classdef Variables < handle

    properties (SetAccess = ?AlgorithmBox)
        
        is_loaded=0;
        name='';
        
        dimension=0;
        boundaries_min=[];
        boundaries_max=[];
        
        current_value

    end
    
    properties (Access=protected)
    
        algorithm_box@AlgorithmBox
        nvariables=0;
        variables@cell
    
    end    
    
    methods (Access=public)
        
        function[obj]=Variables(algoBox)
            obj.algorithm_box=algoBox;
            if ~isfield(obj.algorithm_box.settings,'variables') || size(obj.algorithm_box.settings.variables,1)==0
                obj.run_assistant;
            else
                names=fieldnames(obj.algorithm_box.settings.variables);
                nv=size(names,1);
                obj.variables=cell(1,nv);
                for i=1:nv
                    obj.variables(1,i)=eval([names(i,1),'(obj.algorithm_box);']);
                end    
                obj.load;
            end
        end
        
        function [] = run_assistant(obj)
            obj.is_loaded=0;
            while obj.nvariables==0 || ~isa(obj.nvariables,'double')
                obj.nvariables=input(['Enter the number of "Variable" objects that will come into play: ']);
            end
            obj.variables=cell(1,obj.nvariables);
            for i=1:obj.nvariables
                name=input(['Enter the name of the "Variable" subclass #',num2str(i),': ',],'s');
                variable=eval([name,'(obj.algorithm_box);']);
                variable.run_assistant;
                obj.variables(1,i)=variable;
            end    
            obj.load;
        end
        
    end    
    
    methods (Access = protected)
    
        function [] = load(obj)
            obj.is_loaded=0
            obj.boundaries_min(end+1:end+obj.dimension,1)=variable.boundaries_min;
            obj.boundaries_max(end+1:end+obj.dimension,1)=variable.boundaries_max;
            obj.name='| Variables: ';
            for i=1:obj.nvariables
                obj.name=[obj.name,obj.variables(1,i).name,' |'];
            end    
            obj.is_loaded=1;
        end    
    
    end    
    
    methods (Access = ?Variable)
        
    end
    
end

