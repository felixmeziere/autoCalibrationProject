classdef ErrorFunction < handle
    
    properties (SetAccess = public)
        
        is_loaded=0;
        algorithm_box
        error_calculator@ErrorCalculator % an ErrorCalculator subclass, which is a way of comparing two performance calculator values (e.g. L1 norm).
        performance_calculators  % a cell array containing instances of the PerformanceCalculator subclass, which is a quantity measured in pems or outputed by beats (e.g. TVM).
        weights
        name
        result
        results
        error_in_percentage
        %res_history
        
    end    

    methods (Access = public)
        
        %create object.....................................................
        function [obj] = ErrorFunction(algoBox, param) %param : struct which fields are 'performance_calculators', a struct which fields are the names of the performance calculator classes, associated with their respective weight, and 'error_calculator', associated with the name of the error calculator used.               
            no_param=0;
            obj.algorithm_box=algoBox;
            if (obj.algorithm_box.beats_loaded==1 && obj.algorithm_box.pems.is_loaded==1 && obj.algorithm_box.masks_loaded==1)
                if (nargin<2)
                    param=struct;
                end
                has_congestion_pattern=0;
                if (~isfield(param,'performance_calculators'))
                    npc=input(['Enter the number of different performance calculators that will be involved : ']);
                    for i=1:npc
                        name=input(['Enter the name of the "PerformanceCalculator" subclass number ', num2str(i),' (like TVH) : '],'s');
                        weight=input(['Enter its weight (sum of weights must be one) : '],'s');
                        eval(strcat('param.performance_calculators.',name,'=',weight,';'));
                        if strcmp(name,'CongestionPattern')
                            has_congestion_pattern=1;
                            no_param=1;
                        end    
                    end
                end
                if (~isfield(param,'error_calculator'))
                    param.error_calculator=ErrorCalculator(has_congestion_pattern);
                end
                npc=size(param.performance_calculators,2);
                names=fieldnames(param.performance_calculators);
                obj.error_calculator=param.error_calculator;
                obj.performance_calculators=cell(1,npc);
                for i = 1:size(names,1)
                    obj.weights(1,i)=getfield(param.performance_calculators,char(names(i)));
                    if strcmpi(names(i),'CongestionPattern') 
                        if isfield(obj.algorithm_box.temp,'congestion_patterns')
                            change_rectangles=-1;
                            if (no_param==1)
                                while (change_rectangles~=1 && change_rectangles ~= 0)
                                    change_rectangles=input(['Do you want to change the rectangles (instead of leaving them as they were until now) (1=yes/0=no) ? : ']);
                                end
                            end    
                            if change_rectangles==1
                                obj.algorithm_box.remove_field_from_property('temp','congestion_patterns');
                                obj.performance_calculators{i}=CongestionPattern(obj.algorithm_box);
                                obj.algorithm_box.temp.congestion_patterns=obj.performance_calculators{i}.rectangles;
                            else    
                                obj.performance_calculators{i}=CongestionPattern(obj.algorithm_box, obj.algorithm_box.temp.congestion_patterns);
                            end
                        else
                            obj.performance_calculators{i}=CongestionPattern(obj.algorithm_box);
                            obj.algorithm_box.temp.congestion_patterns=obj.performance_calculators{i}.rectangles;
                        end
                    else    
                        obj.performance_calculators{i}=eval(strcat(char(names(i)),'(obj.algorithm_box)'));
                    end
                    if (i==1)
                        obj.name=strcat(num2str(obj.weights(1,i)),'*',names(1));
                    else    
                        obj.name=strcat(obj.name,'+', num2str(obj.weights(1,i)),'*',names(i));
                    end
                    obj.name=char(obj.name);
                end
                if sum(obj.weights)~=1
                    error('The sum of the weights of the performance calculators must be 1.');
                end
%                 display('RUNNING BEATS A FIRST TIME FOR REFERENCE DATA (Temporary method).');
%                 obj.algorithm_box.evaluate_error_function(ones(11,1),0);
%                  STILL HAS TO BE TO IMPLEMENTED BUT WONT BE NEEDED WHEN
%                  WE WILL USE PEMDS DATA
                obj.calculate_pc_from_beats;
                obj.calculate_pc_from_pems;
                obj.calculate_error;  
                obj.is_loaded=1;
            else
                error('Beats Simulation and Pems data must be loaded first.')
            end
        end
        
        %calculate results.................................................
        function [] = calculate_pc_from_beats(obj)
            for i=1:size(obj.performance_calculators,2)
                obj.performance_calculators{i}.calculate_from_beats;
            end
        end    
            
        function [] = calculate_pc_from_pems(obj)
             for i=1:size(obj.performance_calculators,2)
                obj.performance_calculators{i}.calculate_from_pems;
             end
        end    
        
        function [result,error_in_percentage] = calculate_error(obj)
            for i=1:size(obj.performance_calculators,2)
                res(i,1)=obj.error_calculator.calculate(obj.performance_calculators{i}.result_from_beats,obj.performance_calculators{i}.result_from_pems);
                errors_in_percentage(i,1)=obj.performance_calculators{i}.error_in_percentage;
            end    
            result=obj.weights*res;
            error_in_percentage=obj.weights*errors_in_percentage;
            obj.result=result;
            obj.results=res;
            obj.error_in_percentage=error_in_percentage;
        end  
        
        function [] = plot_congestion_pattern_if_exists(obj)
            exists=0;
            for (i=1:size(obj.performance_calculators,2))
                if (strcmp(class(obj.performance_calculators{i}),'CongestionPattern'))
                    obj.performance_calculators{i}.plot;
                    exists=1;
                end    
            end    
            if (exists==0)
                disp('Sorry, no CongestionPattern among the performance calculators of this error function');
            end    
        end    
            
    end
    
end

