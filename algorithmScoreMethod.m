classdef (Abstract) algorithmScoreMethod < handle
    %algorithmScoreMethod Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        someproperty
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Construction, loading scoreMethod                                  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
        
        % Construction ......................................
        function [obj] = algorithmScoreMethod()
            obj.reset_object();
        end
        
        %
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  private methods                                                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = private)
        
        function [obj] = reset_object(obj)
           
        end
        
  
    end
    
end

