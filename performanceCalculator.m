classdef (Abstract) PerformanceCalculator<handle
    %PerformanceCalculator Summary of this class goes here
    %   Detailed explanation goes here
   properties (SetAccess = protected)
       
       result_from_beats=0;
       result_from_pems=0;
       error_in_percentage=0;
       algorithm_box
       
   end 
   
   properties (Hidden, Access = public)
    
      error_in_percentage_history=[];
       
   end    
   properties (Abstract, Constant)
       
       name
       
   end    
   
   methods(Abstract, Access = public)
       
       %the constructor must have one argument, algoBox, which will be
       %affected to obj.algorithm_box
        [result] = calculate_from_beats(obj)
        [result] = calculate_from_pems(obj)
        [] = plot(obj,figureNumber);
        
   end
   
end

