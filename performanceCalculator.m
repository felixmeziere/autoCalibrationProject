classdef (Abstract) PerformanceCalculator < handle
    %PerformanceCalculator Summary of this class goes here
    %   Detailed explanation goes here
   properties (SetAccess = protected)
       
       result_from_beats
       result_from_pems
       error_in_percentage
       
   end 
   
   properties (Abstract, SetAccess = protected)
       
       name
       
   end    
   
   methods(Abstract, Access = public)
       
        [result] = calculate_from_beats(obj, algoBox)
        [result] = calculate_from_pems(obj, algoBox)   
        
   end
   
end

