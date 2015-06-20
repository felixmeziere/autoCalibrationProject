classdef (Abstract) PerformanceCalculator<handle
    %PerformanceCalculator Summary of this class goes here
    %   Detailed explanation goes here
   properties (SetAccess = protected)
       
       result_from_beats=nan;
       result_from_pems=nan;
       error=nan;
       error_in_percentage=nan;
       algorithm_box
       error_history=[];
       error_in_percentage_history=[];
       
   end    
   
   properties(SetAccess = ?ErrorFunction)
       
       norm=L1;   
       
   end    
   properties (Abstract, Constant)
       
       name
       
   end    
   
   methods(Abstract, Access = public)
       
       %the constructor must have one argument, algoBox, which will be
       %affected to obj.algorithm_box
        [result] = calculate_from_beats(obj)
        [result] = calculate_from_pems(obj)
        [result,result_in_percentage] = calculate_error(obj)
        [] = plot(obj,figureNumber);
        
   end
   
   methods(Access = ?ErrorFunction)
       
        function [] = reset_history(obj)
            obj.error_history=[];
            obj.error_in_percentage_history=[];
            obj.error=nan;
            obj.error_in_percentage=nan;
        end
        
        function [] = ask_for_norm(obj)
            obj.norm=input(['Which norm do you want to use for',obj.name,' ? (Enter name of "Norm" subclass) : ']);
        end    
       
   end    
   
end

