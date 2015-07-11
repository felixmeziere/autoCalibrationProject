classdef FDS < Variable
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Constant,Access=public)
        
        variables_order={'congestion_speed','free_flow_speed','jam_density','capacity'}
        
    end
    
    properties (SetAccess=?AlgorithmBox)
    
        mainline_link_groups
        
    end
    methods(Access = public)
        
        [] = run_assistant(obj)
        
        [] = ask_for_boundaries(obj)
        
    end
    
    methods (Access=?AlgorithmBox)
        
        [] = set_persistent(obj, values_vector)
        
        [] = set_auto_boundaries(obj)
        
        [] = reset_history(obj)
    
    end    
    
end

