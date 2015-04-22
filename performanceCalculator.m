classdef (Abstract) PerformanceCalculator < handle
    %PerformanceCalculator Summary of this class goes here
    %   Detailed explanation goes here
   properties (SetAccess = protected)
       
       result_from_beats
       result_from_pems
       
   end 
   
   properties (Abstract, Constant)
       
       name
       
   end
   
   methods(Abstract, Access = public)
       
        [] = calculate_from_beats(obj, BS, freeway_links_with_good_sensors_mask)
        [] = calculate_from_pems(obj, pems, mask)   
        
   end
   
end

