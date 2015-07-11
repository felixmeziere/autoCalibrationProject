classdef Variables < handle

    properties (SetAccess = ?AlgorithmBox)
        
        is_loaded=0;
        name
        
        nvariables
        boundaries_min
        boundaries_max
        
        current_value

    end
    
    properties (Access=protected)
    
        algorithm_box@AlgorithmBox
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
            end
        end
        
    end    
    
    methods (Access = ?Variable)
        
        
    end
    
end

