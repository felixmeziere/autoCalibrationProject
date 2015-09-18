classdef ErrorFunction < handle
    
    
    %Required for loading from xls :
        
    %(NPCSC#k is name of kth PerformanceCalculator subclass and NNSC#k is name of kth Norm subclass)
    
    
    %    -> settings.error_function.performance_calculators | struct('NPCSC#1',[weight#1], 'NPCSC#2',[weight#2],...,'NPCSC#n',[weight#n])       
    %    -> settings.error_function.norms | {'NNSC#1','NNSC#2',...,'NNSC#n'}
    %    -> error_function.pcs_uncertainty | [fraction of 1]
    
    properties (SetAccess = ?AlgorithmBox)
        
        is_loaded=0; %indicates if objects is ready for use
        algorithm_box@AlgorithmBox %Parent AlgorithmBox
        performance_calculators  % a (1xp) cell array containing instances of the PerformanceCalculator subclasses used
        weights % (1xp) array containing the weights of the performance calculators in the same order as above
        name %name f the error function for the log file (sum(performance_calculator*weight))
        pcs_uncertainty=0.05 %uncertainty allowed on the error of the performance calculators : 0.05 means that the algorithm won't discriminate points that are within +-5% of the PeMS reference value (their error in this range is zero).
        
        error %current total error value : sum(contributions). This is never used.
        errors %(1xp) array containing the unmodified current error value of each pc (can be negative).
        contributions %(1xp) array containing the contribution to the total error of each pc : abs(PC_error)*weight if PC_error_in_percentage>pcs_uncertainty or PC is ProjPenalization, else 0.
        
        error_in_percentage %current total error in percentage value : sum(contributions_in_percentage). This is used by the algorithm.
        errors_in_percentage %(1xp) array containing the unmodified current error in percentage value of each pc (can be negative).
        contributions_in_percentage %(1xp) array containing the contribution to the total error in percentage of each pc : abs(PC_error_in_percentage)*weight if PC_error_in_percentage>pcs_uncertainty or PC is ProjPenalization, else 0.

        

        error_history % column log with consecutive values of error during last run
        errors_history % column log with consecutive values of error during last run
        contributions_history % column log with consecutive values of contributions during last run

        error_in_percentage_history % column log with consecutive values of error_in_percentage during last run
        errors_in_percentage_history % column log with consecutive values of errors_in_percentage during last run
        contributions_in_percentage_history % column log with consecutive values of contributions_in_percentage during last run

    end
    
    properties (SetAccess = ?EvolutionnaryAlgorithmBox)
        
        error_genmean_history=nan; % column log with consecutive values of error in "generation mean" format during last run
        errors_genmean_history=nan; % column log with consecutive values of errors in "generation mean" format during last run
        contributions_genmean_history=nan; % column log with consecutive values of contributions in "generation mean" format during last run
        
        error_in_percentage_genmean_history=nan;
        errors_in_percentage_genmean_history=nan; % column log with consecutive values of errors_in_percentage in "generation mean" format during last run
        contributions_in_percentage_genmean_history=nan; % column log with consecutive values of contributions_in_percentage in "generation mean" format during last run
        
    end    
        
    methods (Access = public)
        
        %create object.....................................................
        function [obj] = ErrorFunction(algoBox) %Constructor that will call an assistant if parameters are missing and then load the object (computes the PeMS values for the pcs).             
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
                    obj.pcs_uncertainty=input('Enter the value of the uncertainty allowed on the PeMS performance calculators (Iglobal)(e.g.:0.05):');
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
                error('Beats Simulation and Pems data must be loaded first.');
            end
        end
        
        %calculate results.................................................
        function [] = calculate_pc_from_beats(obj)
            for i=1:size(obj.performance_calculators,2)
                obj.performance_calculators{i}.calculate_from_beats;
            end
        end  %From BeATS output, calculate the value of each PC in obj.performance_calculator. Used at each iteration.  
            
        function [] = calculate_pc_from_pems(obj) %From PeMS data, calculate the value of each PC in obj.performance_calculator. Used only once at the beginning.
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
            kd=obj.find_performance_calculator('ProjPenalization');
            msk=ismember(1:size(obj.performance_calculators,2),kd);
            obj.contributions_in_percentage(logical(~msk.*(abs(obj.errors_in_percentage)<100*obj.pcs_uncertainty)))=0;
            obj.contributions(logical(~msk.*(abs(obj.errors_in_percentage)<100*obj.pcs_uncertainty)))=0;
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
        end  %Once the precedent functions have been used, calculate the error of each pc and combine the results (contributions) to compute the total error and total error in percentage to feed the algorithm. Used at each iteration.
        
        %plot functions (names speak for themselves. To refactor and debug.)
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
        
        function [] = plot_error_history(obj, figureNumber, evaluation_number)
            n=nargin;
            if n<1
                figureNumber=0;
            elseif n<2
                evaluation_number=0;
            end    
            obj.plot_knobs(figureNumber,evaluation_number, obj.error_history, 'Total error in percentage evolution','Error in percentage');
        end
        
        function [] = plot_error_genmean_history(obj, figureNumber, evaluation_number)
            n=nargin;
            if n<1
                figureNumber=0;
            elseif n<2
                evaluation_number=0;
            end    
            obj.plot_knobs(figureNumber,evaluation_number, obj.error_genmean_history, 'Total error in percentage generation mean evolution','Error in percentage');
        end
        
        function [] = plot_contributions_history(obj, figureNumber, evaluation_number)
            n=nargin;
            if n<1
                figureNumber=0;
            elseif n<2
                evaluation_number=0;
            end    
            obj.plot_knobs(figureNumber,evaluation_number, obj.contributions_history, 'Contributions to total error in percentage evolution','Contributions in percentage');    
            for i=1:size(obj.performance_calculators,2)
                leg{i+1}=obj.performance_calculators{i}.name;
            end 
            legend(leg);
        end        
        
        function [] = plot_contributions_genmean_history(obj, figureNumber, evaluation_number)
            n=nargin;
            if n<1
                figureNumber=0;
            elseif n<2
                evaluation_number=0;
            end    
            obj.plot_knobs(figureNumber,evaluation_number, obj.error_history, 'Contributions to total error in percentage generation mean evolution','Contributions in percentage');  
            for i=1:size(obj.performance_calculators,2)
                leg{i+1}=obj.performance_calculators{i}.name;
            end 
            legend(leg);
        end
        
        function [] = plot_complete(obj, figureNumber, evaluation_number,for_movie)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n<3)
                evaluation_number=size(obj.contributions_in_percentage_history,1);
            end    
%             p=[30,400,700,470];
%             set(h, 'Position', p);
            plot(obj.error_in_percentage_history(1:evaluation_number,:));
            hold on
            plot(obj.contributions_in_percentage_history(1:evaluation_number,:));
            hold off
            title('Total error in percentage with contributions');
            xlabel('Number of BEATS evaluations');
            ylabel('Error in percentage');
            if (n<4 || for_movie~=1)
                leg{1}='Total Error';
                for i=1:size(obj.performance_calculators,2)
                    leg{i+1}=obj.performance_calculators{i}.name;
                end 
                legend(leg);
            else
                legend(['Current total error : ',num2str(obj.error_in_percentage_history(evaluation_number,1)),'%']);
                legend BOXOFF
            end 
        end
        
        function [] = plot_genmean_complete(obj, figureNumber, evaluation_number, for_movie)
            n=nargin;
            if (n<2)
                h=figure;
            else    
                h=figure(figureNumber);
            end
            if (n<3)
                evaluation_number=size(obj.contributions_in_percentage_genmean_history,1);
            end    
%             p=[30,400,700,470];
%             set(h, 'Position', p);
            plot(obj.error_in_percentage_genmean_history(1:evaluation_number,:));
            hold on
            plot(obj.contributions_in_percentage_genmean_history(1:evaluation_number,:));
            hold off
            title('Total error in percentage with contributions');
            xlabel('Number of BEATS evaluations');
            ylabel('Error in percentage');
            if (n<4 || for_movie~=1)
                leg{1}='Total Error';
                for i=1:size(obj.performance_calculators,2)
                    leg{i+1}=obj.performance_calculators{i}.name;
                end 
                legend(leg);
            else
                legend(['Current total error : ', num2str(obj.error_in_percentage_genmean_history(evaluation_number,1)),'%']);
                legend BOXOFF
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
    
       function [index] = find_performance_calculator(obj,performance_calculator_name) %index of performance_calculator_name in obj.performance_calculators and all properties that use this index. index=0 means the performance calculator doesn't exist in this error function.
            index=0;
            for i=1:size(obj.performance_calculators,2)
                if (strcmp(class(obj.performance_calculators{i}),performance_calculator_name))
                    index=i;
                end    
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
        end %reset the logs for new run
        
        
       function [] = plot_error(obj,figureNumber,evaluation_number,error_array_to_plot, title, ylabel)
            n=nargin;
            if (n<2 || figureNumber==0)
                h=figure;
            else
                h=figure(figureNumber);
            end  
            if n<3 || evaluation_number==0
                evaluation_number=size(error_array_to_plot,1);
            end     
%             p=[700,400,800,470];
%             set(h, 'Position', p);
            plot(error_array_to_plot(1:evaluation_number,:));
            title(title);
            xlabel('Number of BeATS evaluations');
            ylabel(ylabel);
            xlim([0,size(error_array_to_plot,1)+1]);
            if (n>6 && with_legend==1) 
                for i=1:obj.nKnobs
                    leg{i}=['Knob ',num2str(find(obj.linear_link_ids==obj.link_ids(i,1))),' (',num2str(obj.link_ids(i,1)),')'];
                end 
                legend(leg);
                legend BOXOFF
            end
       end  
        
    end
    
end

