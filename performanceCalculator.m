classdef (Abstract) PerformanceCalculator<handle
    
    properties (SetAccess = protected)
       
       result_from_beats=nan; %Last value of the performance calculator computed from BeATS output.
       result_from_pems=nan; %Last value of the performance calculator computed from PeMS data
       error=nan; %deviation between the two precendent properties (each pc has its own way of computing this)
       error_in_percentage=nan; %same in percentage (each pc has its own way of computing this).
       algorithm_box@AlgorithmBox % Parent AlgorithmBox instance
       error_history=[]; %log with the consecutive values of error during last run
       error_in_percentage_history=[]; %log with the consecutive values of error_in_percentage during last run
       
   end    
   
   properties
       
       norm@Norm %Norm object instance. The norm that will compute the error for this PC.  
       
   end    
   properties (Abstract, Constant)
       
       name %Name of this PC for the logs.
       
   end    
   
   methods(Abstract, Access = public)
       
       %the constructor must have one argument, algoBox, which will be
       %affected to obj.algorithm_box (Matlab OOP doesn't allow me to
       %impose this
        [result] = calculate_from_beats(obj) % calculate the value from beats output and save in result_from_beats
        [result] = calculate_from_pems(obj) % calculate value from pems and save in result_from_pems
        [result,result_in_percentage] = calculate_error(obj) %calculate the deviation between the result of the two last methods and save in log properties (each pc has its own way of computing this).
        [] = plot(obj,figureNumber); %plot the PC history.
        
   end
   
   methods(Access = ?ErrorFunction)
       
        function [] = reset_history(obj) %reset the logs.
            obj.error_history=[];
            obj.error_in_percentage_history=[];
            obj.error=nan;
            obj.error_in_percentage=nan;
        end
        
        function [] = ask_for_norm(obj) %assistant asking for the norm called by error function if needed
            obj.norm=input(['Which norm do you want to use for ',obj.name,' ? (Enter name of "Norm" subclass) : ']);
        end    
       
   end    
   
end

