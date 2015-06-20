classdef ErrorFunction < handle
    
    
    %Required for loading from xls :
    
    %(NPCSC#k is name of kth PerformanceCalculator subclass and NNSC#k is name of kth Norm subclass)
    
    
    %    -> settings.error_function.performance_calculators | struct('NPCSC#1',[weight#1], 'NPCSC#2',[weight#2],...,'NPCSC#n',[weight#n])       
    %    -> settings.error_function.norms | {'NNSC#1','NNSC#2',...,'NNSC#n'}
    
    properties (SetAccess = ?AlgorithmBox)
        
        is_loaded=0;
        algorithm_box
        performance_calculators  % a cell array containing instances of the PerformanceCalculator subclass, which is a quantity measured in pems or outputed by beats (e.g. TVM).
        weights
        name
        
        error
        errors
        contributions
        
        error_in_percentage
        errors_in_percentage
        contributions_in_percentage
        

        error_history % consecutive values of the errorFunction during last run
        errors_history % consecutive values of the errorFunction during last run
        contributions_history

        error_in_percentage_history
        errors_in_percentage_history
        contributions_in_percentage_history
        
        
        
    end
    
    properties (SetAccess = ?EvolutionnaryAlgorithmBox)
        
        error_genmean_history=nan;
        errors_genmean_history=nan;
        contributions_genmean_history=nan;
        
        error_in_percentage_genmean_history=nan;
        errors_in_percentage_genmean_history=nan;
        contributions_in_percentage_genmean_history=nan;
        
    end    
        
    methods (Access = public)
        
        %create object.....................................................
        function [obj] = ErrorFunction(algoBox) %param : struct which fields are 'performance_calculators', a struct which fields are the names of the performance calculator classes, associated with their respective weight.               
            first_time=1;
            allsame=0;
            obj.algorithm_box=algoBox;
            if (obj.algorithm_box.beats_loaded==1 && obj.algorithm_box.pems.is_loaded==1 && obj.algorithm_box.masks_loaded==1)
                if obj.algorithm_box.currently_loading_from_xls~=1
                    has_congestion_pattern=0;
                    param.performance_calculators=struct;
                    npc=input(['Enter the number of different performance calculators that will be involved : ']);
                    allsame=-1;
                    while allsame~=0 && allsame~=1
                        allsame=input('Do you want to use the same norm for every performance calculator ? (yes=1, no = 0) : ');
                    end              
                    if allsame==1
                        common_norm=input('Enter the name of the "Norm" sublass that will be used for error calculation (e.g. L1) : ','s');
                    end    
                    for i=1:npc
                        name=input(['Enter the name of the "PerformanceCalculator" subclass number ', num2str(i),' (like TVH) : '],'s'); 
                        weight=input(['Enter its weight (sum of weights must be one) : ']);
                        param.performance_calculators=setfield(param.performance_calculators,name,weight);
                        if strcmp(name,'CongestionPattern')
                            has_congestion_pattern=1;
                        end    
                    end
                else
                    param=obj.algorithm_box.settings.error_function;
                end    
                npc=size(param.performance_calculators,2);
                names=fieldnames(param.performance_calculators);
                obj.performance_calculators=cell(1,npc);
                for i = 1:size(names,1)
                    weight=getfield(param.performance_calculators,char(names(i)));
                    obj.weights(1,i)=weight(1);
                    obj.performance_calculators{i}=eval(strcat(char(names(i)),'(obj.algorithm_box)'));
                    if obj.algorithm_box.currently_loading_from_xls~=1
                        if allsame==0
                            obj.performance_calculators{i}.ask_for_norm;
                        else
                            obj.performance_calculators{i}.norm=eval(common_norm);    
                        end    
                    else
                        obj.performance_calculators{i}.norm=eval(obj.algorithm_box.settings.error_function.norms{i});
                    end    
                    if (i==1)
                        obj.name=strcat('(',num2str(obj.weights(1,i)),'*',names(1),')');
                    else    
                        obj.name=strcat(obj.name,'+', '(', num2str(obj.weights(1,i)),'*',names(i),')');
                    end
                    obj.name=char(obj.name);
                end
                if sum(obj.weights(1,:))~=1
                    error('The sum of the weights of the performance calculators must be 1.');
                end
                if (nargin<2 && first_time==0)
                    obj.algorithm_box.reset_beats;
                end    
                obj.calculate_pc_from_pems;
                obj.calculate_pc_from_beats;
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
        
        function [err,error_in_percentage] = calculate_error(obj)
            for i=1:size(obj.performance_calculators,2)
                [obj.errors(1,i),obj.errors_in_percentage(1,i)]=obj.performance_calculators{i}.calculate_error;
            end
            obj.contributions=abs(obj.errors.*obj.weights);
            obj.contributions_in_percentage=abs(obj.errors_in_percentage.*obj.weights);
            obj.contributions_in_percentage(abs(obj.errors_in_percentage)<5)=0;
            err=sum(obj.contributions);
            error_in_percentage=sum(obj.contributions_in_percentage);
            obj.error=err;
            obj.error_in_percentage=error_in_percentage;
            
            obj.error_history(end+1,:)=err;
            obj.errors_history(end+1,:)= obj.errors;
            obj.contributions_history(end+1,:)=obj.contributions;

            obj.error_in_percentage_history(end+1,:)=error_in_percentage;
            obj.errors_in_percentage_history(end+1,:)=obj.errors_in_percentage;
            obj.contributions_in_percentage_history(end+1,:)=obj.contributions_in_percentage;
        end  
        
        %plot functions...................................................
        function [] = plot_performance_calculator_if_exists(obj,performance_calculator, figureNumber)  
            index=obj.find_performance_calculator(performance_calculator);
            if (index~=0)
                if (nargin<3)
                    obj.performance_calculators{index}.plot;
                else    
                    obj.performance_calculators{index}.plot(figureNumber);
                end
            end
        end 
        
        function [h] = plot_error_history(obj, figureNumber, error_history, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n==4)
                error_history=error_history(1:evaluation_number,1);
            else
                if (n~=3)
                    error_history=obj.error_history;
%                     p=[30,400,700,470];
%                     set(h, 'Position', p);
                end    
            end    
            plot(error_history(:,1));
            title('Error function evolution');
            xlabel('Number of BEATS evaluations');
            ylabel('Error function value');
        end
        
        function [h] = plot_error_genmean_history(obj, figureNumber, error_genmean_history, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n==4)
                error_genmean_history=error_genmean_history(1:evaluation_number,1);
            else
                if (n~=3)
                    error_genmean_history=obj.error_genmean_history;
%                     p=[30,400,700,470];
%                     set(h, 'Position', p);
                end    
            end    
            plot(error_genmean_history(:,1));
            title('Error function generation mean evolution');
            xlabel('Number of BEATS evaluations');
            ylabel('Error function value');
        end
        
        function [h] = plot_contributions_history(obj, figureNumber, contributions_history, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n==4)
                contributions_history=contributions_history(1:evaluation_number,1);
            else
                if (n~=3)
                    contributions_history=obj.contributions_history;
%                     p=[30,400,700,470];
%                     set(h, 'Position', p);
                    for i=1:size(obj.performance_calculators,2)
                        leg{i}=obj.performance_calculators{i}.name;
                    end 
                end    
            end    
            plot(contributions_history(:,[1:size(obj.performance_calculators,2)]));
            title('Error function contributions evolution');
            xlabel('Number of BEATS evaluations');
            ylabel('Error function contributions');
            if (n<3)
                legend(leg);
            end      
        end        
        
        function [h] = plot_contributions_genmean_history(obj, figureNumber, contributions_genmean_history, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n==4)
                contributions_genmean_history=contributions_genmean_history(1:evaluation_number,1);
            else
                if (n~=3)
                    contributions_genmean_history=obj.contributions_genmean_history;
%                     p=[30,400,700,470];
%                     set(h, 'Position', p);
                    for i=1:size(obj.performance_calculators,2)
                        leg{i}=obj.performance_calculators{i}.name;
                    end 
                    
                end    
            end    
            plot(contributions_genmean_history);
            title('Error function contributions generation mean evolution');
            xlabel('Number of BEATS evaluations');
            ylabel('Error function contributions');
            if (n<3)
                legend(leg);
            end  
        end
        
        function [h] = plot_complete(obj, figureNumber, contributions_in_percentage_history, error_in_percentage_history, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n==5)
                contributions_in_percentage_history=contributions_in_percentage_history(1:evaluation_number,:);
                error_in_percentage_history=error_in_percentage_history(1:evaluation_number,:);
            else
                if (n<3)
                    contributions_in_percentage_history=obj.contributions_in_percentage_history;
                    error_in_percentage_history=obj.error_in_percentage_history;
%                     p=[30,400,700,470];
%                     set(h, 'Position', p);
                    leg{1}='Total Error';
                    for i=1:size(obj.performance_calculators,2)
                        leg{i+1}=obj.performance_calculators{i}.name;
                    end 
                end    
            end    
            plot(error_in_percentage_history);
            hold on
            plot(contributions_in_percentage_history);
            hold off
            title('Total error in percentage with contributions');
            xlabel('Number of BEATS evaluations');
            ylabel('Error in percentage');
            if (n<3)
                legend(leg);
            elseif n>4
                legend(['Current total error : ',num2str(error_in_percentage_history(evaluation_number,1)),'%']);
                legend BOXOFF
            end 
        end
        
        function [h] = plot_genmean_complete(obj, figureNumber, contributions_in_percentage_genmean_history, error_in_percentage_genmean_history, evaluation_number)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n==5)
                contributions_in_percentage_genmean_history=contributions_in_percentage_genmean_history(1:evaluation_number,:);
                error_in_percentage_genmean_history=error_in_percentage_genmean_history(1:evaluation_number,:);
            else
                if (n<3)
                    contributions_in_percentage_genmean_history=obj.contributions_in_percentage_genmean_history;
                    error_in_percentage_genmean_history=obj.error_in_percentage_genmean_history;
%                     p=[30,400,700,470];
%                     set(h, 'Position', p);
                    leg{1}='Total Error';
                    for i=1:size(obj.performance_calculators,2)
                        leg{i+1}=obj.performance_calculators{i}.name;
                    end 
                end    
            end    
            plot(error_in_percentage_genmean_history);
            hold off
            plot(contributions_in_percentage_genmean_history);
            hold on
            title('Total error in percentage with contributions');
            xlabel('Number of BEATS evaluations');
            ylabel('Error in percentage');
            if (n<3)
                legend(leg);
            end 
        end
        function [] = plot_all_performance_calculators(obj,starting_index)
            if (nargin<2)
                for i=1:size(obj.performance_calculators,2)
                    obj.performance_calculators{i}.plot;
                end 
            else
                for i=1:size(obj.performance_calculators,2)
                    obj.performance_calculators{i}.plot(i+starting_index-1);
                end    
            end    
        end  
        
    end
    
    methods (Access = ?AlgorithmBox)
    
       function [index] = find_performance_calculator(obj,performance_calculator_name)
            try
                index=0;
                for i=1:size(obj.performance_calculators,2)
                    if (strcmp(class(obj.performance_calculators{i}),performance_calculator_name))
                        index=i;
                    end    
                end
                if index==0
                    string=['Sorry, no ',performance_calculator_name,' among the performance calculators of this error function.'];
                    error(string);
                end   
            catch  
            end    
        end    
                
       function [] = reset_history(obj)
            obj.calculate_pc_from_pems;
            obj.error_history=[]; 
            obj.errors_history=[]; 
            obj.contributions_history=[];
            obj.error_in_percentage_history=[];
            obj.errors_in_percentage_history=[];
            obj.contributions_in_percentage_history=[];
            obj.error_genmean_history=nan;
            obj.errors_genmean_history=nan;
            obj.contributions_genmean_history=nan;
            obj.error_in_percentage_genmean_history=nan;
            obj.errors_in_percentage_genmean_history=nan;
            obj.contributions_in_percentage_genmean_history=nan;
            for i=1:size(obj.performance_calculators,2)
                obj.performance_calculators{1,i}.reset_history;
            end    
        end    
        
    end
    
end

