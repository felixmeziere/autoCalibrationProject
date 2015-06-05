classdef (Abstract) AlgorithmBox < handle
    %AlgorithmBox : used by any algorithm.
    %   Contains the properties and methods that are used by any algorithm for
    %   the automatic calibration problem (for now, tuning only source and
    %   sink knobs). This allows you to run a program set in an excel
    %   file and automaticlly registers the results in another excel file.
    
    %CHECK THAT MONITORED TEMPLATES ARE THE EXACT SAME AS PEMS DATA.
    %I AM USING BEATS OUTPUT WITH KNOBS SET TO ONE INSTEAD OF TEMPLATES FOR
    %REFINING THE KNOB BOUNDARIES (IN THEORY, THEIR SUM SHOULD BE THE
    %SAME).
    
    properties (Abstract, Constant)
        
        algorithm_name %name used sometimes.
        
    end    
    
    properties (Abstract, Access = public)
        
        starting_point %starting vector or matrix. If the starting point is a matrix (e.g. if is a population for an evolutionnary algorithm), the columns are vectors (individuals) and the rows are knobs.
        
    end    
    
    properties (Access = public)
        
        %manually modificable properties...................................
        beats_parameters=struct; % the parameters passed to BeatsSimulation.run_beats(beats_parameters).
        error_function@ErrorFunction % instance of ErrorFunction class, containing all the properties and methods to compute the difference between pems and beats output (this is the fitness function to minimize).
        number_runs=1; % the number of times the algorithm will run before going to the next column if an xls program is run. 
        maxEval=90; % maximum number of times that beats will run.
        maxIter=30; % maximum number of iterations of the algorithm (can be different in Evolutionnary Algorithms for example).
        stopFValue=1000; % the algorithm will stop if a smaller value is reached by error_calculator (this is the goal).
        current_xls_program_column=2; % in the xls program, number (not 'B' as in Excel) of the config column currently used.
        normal_mode_bs@BeatsSimulation %temporary. Normal mode already run beatsSimulation to test beats as pems real scenario mode
        res_history
    end
                
    properties (SetAccess = protected)
        
        %visible input porperties..........................................
        
        beats_simulation@BeatsSimulation % the BeatsSimulation object that will run and be overwritten at each algorithm iteration.
        pems@PeMSData % the pems data to compare with the beats results. Input fields : 'days' (e.g. datenum(2014,10,1):datenum(2014,10,10)); 'district' (e.g. 7); 'processed_folder'(e.g. C:\Code). Output Fields : 'data' 
        initialization_method@char % initialization method must be 'normal', 'uniform' or 'manual'.
        TVM_reference_values=struct; %TVM values from pems and beats with all knobs set to one.
        knobs@Knobs % Knobs class instance with all the properties and methods relative to the knobs of the scenario.
        
        %visible output properties.........................................
        
        result_for_xls@cell % result of the algorithm to be outputed to the xls file.
        out % struct with various histories and solutions.
        bestEverErrorFunctionValue % smallest error_calculator value reached during the execution. Extracted from out.
        bestEverPoint % vector of knob values that gave the best (smallest) ever function value.
        numberOfIterations=1; % number of iterations of the algorithm (different than the number of evaluations for evolutionnary algorithms for example).
        numberOfEvaluations=1; % number of times beats ran a simulation. Extracted from out.
        stopFlag; % reason why the algorithm stopped. Extracted from out.
        convergence % convergence speed. 
        
    end
    
    properties (Hidden, Access = public)
        
        temp=struct;
        
    end    
    
    properties (Hidden, SetAccess = protected)
        
        %loading properties...............................................
        
        scenario_ptr=''; % adress of the beats scenario xml file.
        xls_results@char % address of the excel file containing the results, with a format that fits to the method obj.send_result_to_xls.
        xls_program % cell array corresponding to the excel file containing configs in the columns, with the same format as given in the template.
        beats_loaded=0; % flag to indicate if the beats simulation and parameters have been correctly loaded.
        masks_loaded=0; % flag to indicate if the masks and TVM reference values have been correctly loaded.
        current_day=1; %current day used in the pems data loaded.
        is_program_first_run=1; %flag to indicate if long loading time data has been already loaded.
        dated_name %name that will have the reports for this run
        
        %masks pointing at the links with working sensors used on beats 
        %output or on pems data............................................
        
        mainline_mask_beats
        good_mainline_mask_beats
        source_mask_beats
        good_source_mask_beats
        sink_mask_beats
        good_sink_mask_beats
        good_sensor_mask_beats
        mainline_mask_pems
        good_mainline_mask_pems
        source_mask_pems
        good_source_mask_pems
        sink_mask_pems
        good_sink_mask_pems
        good_sensor_mask_pems
        
        %properties with infos on the scenario.............................
        
        two_sensors_links
        link_ids_beats % all the link ids of the scenario. For practical reasons.
        linear_link_ids      

    end    
   
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Construction, loading properties for single run                    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
    methods (Abstract, Access = public)
        
        [] = ask_for_algorithm_parameters(obj) % ask for the algorithm parameters in the command window.
        
        [] = ask_for_starting_point(obj); % set the starting knob values.
        
        [] = set_starting_point(obj, mode); % set a random starting point. 'mode' should be 'uniform' or 'normal'.
    
    end   
    
    methods (Access= public)    
       
        %create object....................................................
        function [obj] = AlgorithmBox() %constructor
            [name,~,~]=fileparts(mfilename('fullpath'));
            cd(name);   
        end 
        
        %load for single run from xls file.................................
        function [] = load_properties_from_xls(obj,is_program,is_program_first_run) % load the properties from an excel file in the format described underneath.
            %properties file : an xls file containing the AlgorithmBox
            %properties to set in the first column and the corresponding
            %expressions to be evaluated by Matlab in the 'current' column
            %(column 2 for a single run).
            %Empty cells in the current column will be ignored.
            %The program input (0 or 1) is to avoid reloading useless
            %stuff.
            if ~exist('is_program','var') || is_program~=1
                obj.knobs=Knobs(obj);
                obj.pems=PeMSData(obj);
                for i=1:size(obj.xls_program,1)
                    if ~strcmp(obj.xls_program(i,obj.current_xls_program_column),'')
                        eval(strcat('obj.',char(obj.xls_program(i,1)),'=',char(obj.xls_program(i,obj.current_xls_program_column)),';'));
                    end
                end
                obj.load_beats;
                obj.pems.load;
                obj.set_masks_and_reference_values;
            end
            if ~exist('is_program_first_run','var') || is_program_first_run~=1
                obj.knobs.set_demand_ids;
                obj.knobs.current_value=ones(size(obj.knobs.link_ids,1));
                obj.link_ids_beats=obj.beats_simulation.scenario_ptr.get_link_ids;      
                if (obj.knobs.force_manual_knob_boundaries==0)
                    obj.knobs.set_auto_knob_boundaries(obj.knobs.isnaive_boundaries);
                end   
                obj.knobs.is_loaded=1;
                obj.set_starting_point(obj.initialization_method);
            end
            obj.error_function=ErrorFunction(obj,obj.temp.erfStruct);
            disp('ALL SETTINGS LOADED, ALGORITHM READY TO RUN');    
        end

        %load for single run from initial loading assistant and its 
        %standalone dependencies...........................................
        function [] = run_assistant(obj) % assistant to set all the parameters for a single run in the command window.
            obj.ask_for_beats_simulation;
            obj.ask_for_pems_data;
            obj.ask_for_errorFunction;
            obj.ask_for_knobs;
            obj.ask_for_algorithm_parameters;
            obj.ask_for_starting_point;
            disp('ALL SETTINGS LOADED, ALGORITHM READY TO RUN');
        end
       
        function [] = ask_for_beats_simulation(obj) % ask the user to enter a beats scenario and beats run parameters.
            scptr= input(['Address of the scenario xml file : '], 's');
            obj.scenario_ptr=scptr;
            obj.beats_parameters=input(['Enter a struct containing the beats simulation properties (like struct("DURATION",86400,"SIM_DT",4,"OUTPUT_DT",300)) : ']);
            obj.load_beats;
        end   
        
        function [] = ask_for_pems_data(obj) % ask the user for the pems info (still not implemented).
            obj.pems=PeMSData(obj);
            obj.pems.run_assistant;
            obj.set_masks_and_reference_values;
        end 
        
        function [] = ask_for_knobs(obj) % set the ids of the knobs to tune in the command window.
            obj.knobs=Knobs(obj);
            obj.knobs.run_assistant;
        end
        
        function [] = ask_for_knob_boundaries(obj) % set the knob boundaries (in the same order as the knob ids) in the command window.
            obj.knobs.ask_for_knob_boundaries;
        end    
               
        function [] = ask_for_errorFunction (obj) % set the performance calculator and error calculator in the command window.
           obj.error_function=ErrorFunction(obj);
        end
        
    end    
            
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Loading program instead of single run and printing results to xls  %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Abstract, Access = public)
         
        [] = set_result_for_xls(obj); % sets results_for_xls after the algorithm has run.
         
    end    
    
    methods (Access = public)
        
        function [] = ask_for_xls(obj)
            % ask the user for the adress of the input and output Excel files.
            program=input(['Enter the address of the Excel program file : '], 's');
            results=input(['Enter the address of the Excel results file : '], 's');
            obj.load_xls(program,results);
        end
        
        function [] = load_xls(obj, xls_program_adress, xls_results_adress)
            % loads the input Excel file and sets the adress of the output.
            obj.is_program_first_run=1;
            if ~exist('xls_results_adress','var')
                xls_results_adress='';
                warning('RESULTS WILL NOT BE RECORDED IN XLS FILE.');
            end
            [useless,obj.xls_program,useless] = xlsread(xls_program_adress);
            obj.xls_results=xls_results_adress;            
            obj.load_properties_from_xls;
        end
    
        function [] = send_result_to_xls(obj, filename)
            %the legend in the xls file should be written manually.
            %the counter for current cell should be in cell AZ1.
            if (nargin<2)
                filename=obj.xls_results;
            end    
            obj.set_result_for_xls;
            [useless1,useless2,xls]=xlsread(filename, obj.algorithm_name);
            id=xls{2,1};
            to_send=[{id,obj.dated_name},obj.result_for_xls];
            xlswrite(filename,to_send,obj.algorithm_name, strcat('B',num2str(id+1)));
            xlswrite(filename, id+1,obj.algorithm_name,'A2');
            disp('RESULTS OF THE RUN SENT TO XLS FILE :');
            disp(filename);
        end  % send result of an execution of the algorithm to the output Excel file.
        
    end    
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Running algorithm and program                                      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Abstract, Access = public)
        
        [] = run_algorithm(obj) % single run of the algorithm.
    
    end    
    
    methods (Access = public)
        
        function [result] = evaluate_error_function(obj, knob_values, isZeroToTenScale) % the error function used by the algorithm. Compares the beats simulation result and pems data.
            %knob_values : n x 1 array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            format SHORTG;
            format LONGG;
            if (size(knob_values,1)==size(obj.knobs.link_ids,1))   
                if exist('isZeroToTenScale','var') && isZeroToTenScale==1
                    knob_values=obj.knobs.rescale_knobs(knob_values,0);
                end
                knob_values=obj.knobs.project_involved_knob_groups_on_correct_flow_subspace(knob_values);
                knob_values=obj.project_on_correct_TVM_subspace(knob_values);
                zeroten_knob_values=obj.knobs.rescale_knobs(knob_values,1);
                obj.knobs.knobs_history(end+1,:)=reshape(knob_values,1,[]);
                obj.knobs.zeroten_knobs_history(end+1,:)=reshape(zeroten_knob_values,1,[]);
                disp(['Knobs vector and values being tested for evaluation # ',num2str(obj.numberOfEvaluations),' :']);
                disp(' ');
                disp(['               Demand Id :','                 Link Id :','                                    Value, min and max:','           Value on a scale from 0 to 10:']);
                disp(' ');
                disp([obj.knobs.demand_ids,obj.knobs.link_ids, knob_values,obj.knobs.boundaries_min,obj.knobs.boundaries_max,zeroten_knob_values]);
                obj.beats_simulation.beats.reset();
                obj.knobs.set_knobs_persistent(knob_values);
                obj.beats_simulation.run_beats_persistent;
                obj.error_function.calculate_pc_from_beats;
                [result,error_in_percentage] = obj.error_function.calculate_error;
                disp(['    Error function value :','      Error in percentage:',' CONTRIBUTIONS: ',obj.error_function.performance_calculators{1}.name,':              ',obj.error_function.performance_calculators{2}.name,':']);%              ',obj.error_function.performance_calculators{3}.name,':']);
                disp([result, error_in_percentage,obj.error_function.transformed_results(1),obj.error_function.transformed_results(2)]);%,obj.error_function.transformed_results(3)]);
                obj.error_function.result_history(end+1,[1,2])=[result,error_in_percentage];
                obj.numberOfEvaluations=obj.numberOfEvaluations+1;
                obj.plot_zeroten_knobs_history(1);
                obj.plot_result_history(2);
                obj.plot_all_performance_calculators(3);
                drawnow;
                obj.save_congestionPattern_matrix;
            else
                error('The matrix with knobs values given does not match the number of knobs to tune or is not a column vector.');
            end    
        end
        
        function [] = run_program(obj, firstColumn, lastColumn)
            %run the program set in the program Excel file and print the
            %results in the results Excel file.
            obj.current_xls_program_column=firstColumn;
            while (obj.current_xls_program_column<=lastColumn)
                disp(strcat(['PROGRAM SETTINGS COLUMN ', num2str(obj.current_xls_program_column)]));
                obj.load_properties_from_xls(1,obj.is_program_first_run);
                counter=obj.number_runs;          
                while (counter > 0)
                    disp([num2str(counter), ' RUNS REMAINING FOR THIS SETTINGS COLUMN']);
                    obj.run_algorithm;
                    obj.send_result_to_xls(obj.xls_results);
                    counter=counter-1;
                end
                obj.current_xls_program_column=obj.current_xls_program_column+1;
                obj.is_program_first_run=0;
           end    
        end % run the program defined by the input Excel file and write its results in the output Excel file.        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Plot functions                                                     %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = public)
    
        function [] = plot_zeroten_knobs_history(obj,figureNumber)
            if (nargin<2)
                obj.knobs.plot_zeroten_knobs_history;
            else    
                obj.knobs.plot_zeroten_knobs_history(figureNumber);
            end
        end    
     
        function [] = plot_result_history(obj, figureNumber)
            if (nargin<2)
                obj.error_function.plot_result_history;
            else
                obj.error_function.plot_result_history(figureNumber);
            end
        end    
        
        function [] = plot_performance_calculator_if_exists(obj,performance_calculator, figureNumber)  
            if (nargin<3)
                obj.error_function.plot_performance_calculator_if_exists(performance_calculator);
            else
                obj.error_function.plot_performance_calculator_if_exists(performance_calculator,figureNumber);
            end
        end
        
        function [] = plot_scenario(obj,is_mainline_only_format, with_monitored_onramps,with_monitored_offramps,with_nonmonitored_onramps,with_nonmonitored_offramps,with_monitored_mainlines)
            %The designated mainline link for ramps will be the precedent one.

            if(nargin<3)
                with_monitored_onramps=1;
                with_monitored_offramps=1;
                with_nonmonitored_onramps=1;
                with_nonmonitored_offramps=1;
                with_monitored_mainlines=1;
                if (nargin<2)
                   is_mainline_only_format=0;
                end    
            end
            cmap=[0.25,0.25,0.25];
            leg={};
            value=1;
            if ~is_mainline_only_format
                xinfo='Mainline links in order';
                yinfo='Ramps info                                       Mainline info';
                mainline_array=zeros(1,sum(obj.mainline_mask_beats));
                ramps_array=zeros(1,sum(obj.mainline_mask_beats));
                good_source_mask=obj.send_mask_beats_to_linear_mainline_space(obj.good_source_mask_beats);
                good_sink_mask=obj.send_mask_beats_to_linear_mainline_space(obj.good_sink_mask_beats);
                good_mainline_mask=obj.send_mask_beats_to_linear_mainline_space(obj.good_mainline_mask_beats);
                onramp_mask=obj.send_mask_beats_to_linear_mainline_space(logical(obj.source_mask_beats.*~obj.mainline_mask_beats));
                offramp_mask=obj.send_mask_beats_to_linear_mainline_space(logical(obj.sink_mask_beats.*~obj.mainline_mask_beats));
                if with_monitored_mainlines
                    mainline_array(good_mainline_mask)=value;
                    value=value+1;
                    cmap=[cmap;1,1,0];
                    leg{1,end+1}='Monitored mainline links';
                end
                if with_monitored_onramps
                   ramps_array(logical(good_source_mask.*onramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;1,0,0];
                   leg{1,end+1}='Monitored on-ramps';
                end    
                if with_monitored_offramps
                   ramps_array(logical(good_sink_mask.*offramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;1,0,1];
                   leg{1,end+1}='Monitored off-ramps';
                end    
                if with_nonmonitored_onramps
                    ramps_array(logical(~good_source_mask.*onramp_mask))=value;
                    value=value+1;
                    cmap=[cmap;0,0,1];
                    leg{1,end+1}='Non-monitored on-ramps';
                end
                if with_nonmonitored_offramps
                    ramps_array(logical(~good_sink_mask.*offramp_mask))=value;
                    cmap=[cmap;0,1,1];
                    leg{1,end+1}='Non-monitored off-ramps';
                end
                array=[mainline_array;ramps_array];
            else
                xinfo='All links in order';
                yinfo='Link info';
                array=zeros(1,size(obj.link_ids_beats,1));
                good_source_mask=obj.send_mask_beats_to_linear_space(obj.good_source_mask_beats);
                good_sink_mask=obj.send_mask_beats_to_linear_space(obj.good_sink_mask_beats);
                good_mainline_mask=obj.send_mask_beats_to_linear_space(obj.good_mainline_mask_beats);
                onramp_mask=obj.send_mask_beats_to_linear_space(logical(obj.source_mask_beats.*~obj.mainline_mask_beats));
                offramp_mask=obj.send_mask_beats_to_linear_space(logical(obj.sink_mask_beats.*~obj.mainline_mask_beats));
                if with_monitored_mainlines
                    array(good_mainline_mask)=value;
                    value=value+1;
                    cmap=[cmap;1,1,0];
                    leg{1,end+1}='Monitored mainline links';
                end
                if with_monitored_onramps
                   array(logical(good_source_mask.*onramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;1,0,0];
                   leg{1,end+1}='Monitored on-ramps';
                end    
                if with_monitored_offramps
                   array(logical(good_sink_mask.*offramp_mask))=value;
                   value=value+1;
                   cmap=[cmap;1,0,1];
                   leg{1,end+1}='Monitored off-ramps';
                end    
                if with_nonmonitored_onramps
                    array(logical(~good_source_mask.*onramp_mask))=value;
                    value=value+1;
                    cmap=[cmap;0,0,1];
                    leg{1,end+1}='Non-monitored on-ramps';
                end
                if with_nonmonitored_offramps
                    array(logical(~good_sink_mask.*offramp_mask))=value;
                    value=value+1;
                    cmap=[cmap;0,1,1];
                    leg{1,end+1}='Non-monitored off-ramps';                    
                end    
            end      
%             for i=1:size(obj.knobs.link_ids,1)
%                 legknob{1,end+1}=['Knob ',num2str(find(obj.knobs.linear_link_ids==obj.knobs.link_ids(i,1))),' (',num2str(obj.knobs.link_ids(i,1)),')'];
%             end 
            arg_array=[with_monitored_onramps,with_monitored_offramps,with_nonmonitored_onramps,with_nonmonitored_offramps,with_monitored_mainlines];
            number_arg=sum(arg_array);
            figure;
            imagesc(array);
            colormap(cmap);
            title(['Scenario']);
            xlabel(xinfo);
            ylabel(yinfo);
            L = line(ones(number_arg),ones(number_arg), 'LineWidth',2); 
            set(L,{'color'},mat2cell(cmap(2:end,:),ones(1,number_arg),3));
            legend(leg);
        end    
        
        function [] = plot_all_performance_calculators(obj, firstFigureNumber)
             if (nargin<2)
                 obj.error_function.plot_all_performance_calculators;
             else
                 obj.error_function.plot_all_performance_calculators(firstFigureNumber);
             end    
        end
        
        function [movie] = plot_movie(obj,dated_name,figureNumber,congestion_pattern_only,tosave,noncongestion_refresh,stop_frame)
            if(nargin<6)
                noncongestion_refresh=10;
            end    
            if (nargin<2)
                dated_name=obj.dated_name;
            end    
            directory=[pwd,'\movies\',dated_name,'\'];
            load([directory,'result_history.mat']);
            load([directory,'zeroten_knobs_history.mat']);
            max_error=max(result_history);
            if (nargin<5)
                tosave=0;
            end    
            if (nargin>6)
                Num=stop_frame;
            else    
                D = dir([pwd,'\movies\',dated_name, '\*.mat']);
                Num = length(D(not([D.isdir])));
                stop_frame=Num+1;
            end
            movie(Num) = struct('cdata',[],'colormap',[]);
            if (nargin<2)
                h=figure;
                figureNumber=h.Number;
            else
                h=figure(figureNumber);
            end
            p=[100,50,1300,700];
            set(h, 'Position', p);
            i=1;
            flag=1;
            if (nargin>3 && congestion_pattern_only)
                while flag && i<=stop_frame
                    if exist([directory,num2str(i),'.mat'],'file')==2
                        load(['movies\',dated_name,'\',num2str(i),'.mat']);
                        cp=obj.error_function.performance_calculators{obj.error_function.find_performance_calculator('CongestionPattern')};
                        cp.plot(figureNumber,i,frame);
                        drawnow;
                        if (tosave)
                            movie(i)=getframe;
                        end    
                        i=i+1;
                    else flag=0;
                    end
                end
            else
                while flag && i<=stop_frame
                    if exist([pwd,'\movies\',dated_name,'\',num2str(i),'.mat'],'file')==2
                        if (mod(i,noncongestion_refresh)==0)
                            subplot(3,2,1);
                            obj.knobs.plot_zeroten_knobs_history(h.Number,zeroten_knobs_history,i);
                            axis([0,Num,0,10]);
                            line([i i],[0,1000],'Color',[1 0 0]);
%                             plot(i*ones(1,size(zeroten_knobs_history,2)),zeroten_knobs_history(i,:),'MarkerSize',16);
                            subplot(3,2,2);
                            obj.error_function.plot_result_history(h.Number,result_history, i);
                            axis([0,Num,0,max_error]);
                            line([i i],[0,1000],'Color',[1 0 0]);
                        end    
                        load(['movies\',dated_name,'\',num2str(i),'.mat']);
                        subplot(3,2,[4:6]);
                        cp=obj.error_function.performance_calculators{obj.error_function.find_performance_calculator('CongestionPattern')};
                        cp.plot(figureNumber,i,frame);
                        drawnow;
                        if (tosave)
                            movie(i)=getframe(figureNumber);
                        end    
                        i=i+1;
                    else flag=0;
                    end
                end
            end    
        end
        
        function [] = make_movie(obj,dated_name,stop_frame)
            videoname=[pwd,'\movies\',dated_name,'.avi'];
            if exist(videoname,'file')~=2
                if nargin==3
                    M=obj.plot_movie(dated_name,1,0,1,1,stop_frame);
                else
                    M=obj.plot_movie(dated_name,1,0,1,1);
                end
                vidObj = VideoWriter(videoname);
                open(vidObj);
                writeVideo(vidObj,M);
                close(vidObj);
            else
                error('Sorry, a video already exists for this algorithm execution.');
            end    
        end    
        
        function [] = make_nonmade_movies(obj,stop_frame)
            dirname=[pwd,'\movies\'];
            list=dir(dirname);
            for i=1:size(list,1)
                videoname=[dirname,list(i).name,'.avi'];
                if (list(i).isdir && exist(videoname,'file')~=2 && ~strcmp(list(i).name,'..') && ~strcmp(list(i).name,'.'))
                    if nargin==2
                        obj.make_movie(list(i).name,stop_frame);
                    else    
                        obj.make_movie(list(i).name);
                    end
                end
            end    
        end    
        
    end    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Privates and Hidden                                                %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    methods (Access = public) %supposed to be private but public for debug reasons
        
        %initial loading...................................................
        function [] = load_beats(obj)
            if (~strcmp(obj.scenario_ptr,''))
                obj.beats_loaded=0;
                normalstruct=obj.beats_parameters;
                normalstruct.RUN_MODE='normal';
                b=BeatsSimulation;
                b.import_beats_classes;
                b.load_scenario('C:\Users\Felix\code\autoCalibrationProject\config\210E_joined.xml');
                b.create_beats_object(normalstruct);
                b.run_beats_persistent;
                obj.normal_mode_bs=b;
                obj.beats_parameters.RUN_MODE = 'fw_fr_split_output'; 
                display('LOADING BEATS.');
                obj.beats_simulation = BeatsSimulation;
                obj.beats_simulation.import_beats_classes;
                obj.beats_simulation.load_scenario(obj.scenario_ptr);
                obj.beats_simulation.create_beats_object(obj.beats_parameters);
                obj.link_ids_beats=obj.beats_simulation.scenario_ptr.get_link_ids;
                obj.reset_beats;
                obj.linear_link_ids=obj.link_ids_beats(obj.beats_simulation.scenario_ptr.extract_linear_fwy_indices);
                disp('BEATS SETTINGS LOADED.')
                obj.beats_loaded=1;
            else error('Beats scenario xml file adress and beats parameters must be set before loading beats.');   
            end    
        end    %loads beats simulation and computes first TVM reference value.
                
        function [] = set_masks_and_reference_values(obj)
            %sets the masks for further link selection.
            if (obj.beats_loaded && obj.pems.is_loaded)
                sensor_link = obj.beats_simulation.scenario_ptr.get_sensor_link_map;
                good_sensor_mask_pems_r = all(~isnan(obj.pems.data.flw), 1);
                good_sensor_ids_r=obj.pems.vds2id(good_sensor_mask_pems_r,2);
                good_sensor_link_r=sensor_link(ismember(sensor_link(:,1), good_sensor_ids_r),:);
                good_sensor_link=zeros(1,2);
                k=1;
                for i= 1:size(good_sensor_link_r(:,2),1)
                    if (~ismember(good_sensor_link_r(i,2),good_sensor_link(:,2)))
                        good_sensor_link(k,:)=good_sensor_link_r(i,:);
                        k=k+1;
                    else
                        obj.two_sensors_links(end+1)=good_sensor_link_r(i,2);
                    end    
                end
                good_sensor_ids=good_sensor_link(:,1);
                obj.good_sensor_mask_pems=reshape(ismember(obj.pems.vds2id(:,2),good_sensor_ids),1,[]);
                good_sensor_link_ids=good_sensor_link(:,2);
                mainline_link_ids=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('freeway');
                obj.mainline_mask_beats=ismember(obj.link_ids_beats, mainline_link_ids);
                obj.source_mask_beats=obj.beats_simulation.scenario_ptr.is_source_link;
                obj.sink_mask_beats=obj.beats_simulation.scenario_ptr.is_sink_link;
                source_link_ids=obj.link_ids_beats(1,obj.source_mask_beats);
                sink_link_ids=obj.link_ids_beats(1,obj.sink_mask_beats);
                obj.mainline_mask_pems=reshape(ismember(sensor_link(:,2), mainline_link_ids),1,[]);
                obj.source_mask_pems=reshape(ismember(sensor_link(:,2), source_link_ids),1,[]);
                obj.sink_mask_pems=reshape(ismember(sensor_link(:,2), sink_link_ids),1,[]);
                obj.good_sensor_mask_beats=ismember(obj.link_ids_beats, good_sensor_link_ids);
                obj.good_mainline_mask_beats=logical(obj.good_sensor_mask_beats.*obj.mainline_mask_beats);
                obj.good_source_mask_beats=logical(obj.good_sensor_mask_beats.*obj.source_mask_beats);
                obj.good_sink_mask_beats=logical(obj.good_sensor_mask_beats.*obj.sink_mask_beats);
                obj.good_mainline_mask_pems=logical(obj.good_sensor_mask_pems.*obj.mainline_mask_pems);
                obj.good_source_mask_pems=logical(obj.good_sensor_mask_pems.*obj.source_mask_pems);
                obj.good_sink_mask_pems=logical(obj.good_sensor_mask_pems.*obj.sink_mask_pems);
                TVmiles=TVM(obj);
                obj.TVM_reference_values.beats=TVmiles.calculate_from_beats;
                obj.TVM_reference_values.pems=TVmiles.calculate_from_pems;
                obj.masks_loaded=1;
            else
                error('Beats simulation and PeMS data must be loaded before setting the masks and reference values.');
            end    
        end    %sets the masks for further link selection and smoothens pems flow values.
        
        function [] = reset_beats(obj)
            obj.beats_simulation.beats.reset();
            obj.knobs.set_knobs_persistent(ones(size(obj.knobs.link_ids,1),1));
            disp('RUNNING BEATS A FIRST TIME FOR REFERENCE DATA.');
            obj.beats_simulation.run_beats_persistent;
        end
        
        function [] = reset_for_new_run(obj)
            obj.error_function.reset_for_new_run;
            obj.knobs.knobs_history=[];
            obj.knobs.zeroten_knobs_history=[];
            obj.knobs.zeroten_knobs_history;
        end    
        
        %get link lengths in beats or pems data matching format............
        function [lengths] = get_link_lengths_miles_pems(obj,link_mask_pems, same_link_mask_beats)
            all_lengths=obj.beats_simulation.scenario_ptr.get_link_lengths('us')*0.0001893935;
            lengths=zeros(1,sum(link_mask_pems));
            ordered_link_ids=obj.pems.link_id(link_mask_pems);
            k=1;
            for i=1:size(ordered_link_ids,2)
                link_mask=ismember(obj.link_ids_beats,ordered_link_ids(1,i));
                if ~isempty(find(link_mask.*same_link_mask_beats))
                    lengths(1,k)=all_lengths(1,logical(link_mask.*same_link_mask_beats));
                    k=k+1;
                end    
            end
        end %get an array with the lengths of the links pointed by link_mask_pems, when applied to a 'pems format' link ids array. Same_link_mask_beats must be the the same link mask for beats foramt.
        
        function [lengths] = get_link_lengths_miles_beats(obj,link_mask_beats)
            link_length_miles = obj.beats_simulation.scenario_ptr.get_link_lengths('us')*0.0001893935;
            lengths = link_length_miles(link_mask_beats);
        end %get an array with the lengths of the links pointed by link_mask_beats, when applied to a 'beats format' link ids array.
        
        %get remaining monitored mainline link ids.........................
        function [mainline_link_id]=get_next_mainline_link_id_deprecated(obj, input_link_id)
%             if ismember(input_link_id,obj.link_ids_beats(logical(obj.source_mask_beats.*~obj.mainline_mask_beats)))
%                 output_node_id=obj.beats_simulation.scenario_ptr.get_link_byID(input_link_id).end.ATTRIBUTE.node_id;
%                 output_node=obj.beats_simulation.scenario_ptr.get_node_byID(output_node_id);
%                 mainline_link_ids=obj.link_ids_beats(obj.mainline_mask_beats);
%                 output_link_ids=output_node.outputs.output;
%                 node_output_links=[];
%                 for i=1:size(output_link_ids,2)
%                     node_output_links=output_node.outputs.output(i).ATTRIBUTE.link_id;
%                 end
%                 mainline_link_id=node_output_links(ismember(node_output_links,mainline_link_ids));
%             elseif ismember(input_link_id,obj.link_ids_beats(logical(obj.sink_mask_beats.*~obj.mainline_mask_beats)))
%                 input_node_id=obj.beats_simulation.scenario_ptr.get_link_byID(input_link_id).begin.ATTRIBUTE.node_id;
%                 input_node=obj.beats_simulation.scenario_ptr.get_node_byID(input_node_id);
%                 mainline_link_ids=obj.link_ids_beats(obj.mainline_mask_beats);
%                 output_link_ids=input_node.outputs.output;
%                 node_output_links=[];
%                 for i=1:size(output_link_ids,2)
%                     node_output_links=input_node.outputs.output(i).ATTRIBUTE.link_id;
%                 end
%                 mainline_link_id=node_output_links(ismember(node_output_links,mainline_link_ids));
%             else error('Input link must be non-mainline sink or source');        
%             end    
         end % gets the id of the mainline link just after the node connecting the input_link_id ramp to the freeway.

        function [mainline_link_id]=get_next_mainline_link_id(obj, input_link_id)
            index=find(obj.linear_link_ids==input_link_id);
            is_mainline=0;
            i=0;
            while (is_mainline==0)
                i=i+1;
                mainline_link_id=obj.linear_link_ids(index+i);
                is_mainline=ismember(mainline_link_id, obj.link_ids_beats(obj.mainline_mask_beats));
            end
        end
        
        function [remaining_mainline_length]=get_remaining_monitored_mainline_length(obj, first_mainline_link_id)
            k=1;
            while obj.linear_link_ids(k)~=first_mainline_link_id && k<=size(obj.linear_link_ids,2)
                k=k+1;
            end
            remaining_link_ids=obj.linear_link_ids(k:size(obj.linear_link_ids,2));
            remaining_link_ids_mask=ismember(obj.link_ids_beats,remaining_link_ids);
            remaining_monitored_mainline_links_mask=logical(remaining_link_ids_mask.*obj.good_mainline_mask_beats);
            remaining_mainline_length=sum(obj.get_link_lengths_miles_beats(remaining_monitored_mainline_links_mask));
        end  %gets the remaining mainline length after the mainline link first_mainline_link_id.

        %project the algorithm input to correct total TVM subspace.........
        function [sum_of_template] = get_sum_of_template_in_veh(obj,link_id) 
            dp=obj.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(link_id);
            sum_of_template=sum(dp.demand)*dp.dt;
        end   %returns the sum over time of the template of the link id, in vehicles.
        
        function [knobs_on_correct_subspace] = project_on_correct_TVM_subspace(obj,vector) % Project vector on the hyperplan of vectors that will make beats output have the same TVM as pems.
            equation_coefficients_tuple=[]; 
            %N tuple that will contain the coefficients of the equation of 
            %the hyperplan. We will call them alpha(i) : alpha(i)= (sum over time of the template values of the demand profile of knob(i))*(remaining mainline length from the corresponding link) 
            %The equation is [(knob1)*alpha(1)+(knob2)*alpha(2)+...+(knobN)*alpha(N)-sum(alpha(i))]+[TVM value given by beats output when all knobs are set to one]=pems TVM value
            %(the substraction of sum of alphaIs removes the extra contribution of the links tuned in beats TVM)
            sze=size(obj.knobs.link_ids,1);
            for i=1:sze %fill the tuple
                if (ismember(obj.knobs.link_ids(i),obj.link_ids_beats(obj.source_mask_beats)))
                    sign=1;
                else
                    sign=-1;
                end
                equation_coefficients_tuple(1,i)=sign*obj.get_sum_of_template_in_veh(obj.knobs.link_ids(i,1))*obj.get_remaining_monitored_mainline_length(obj.get_next_mainline_link_id(obj.knobs.link_ids(i)));  
            end
            equation_rest_of_left_side=obj.TVM_reference_values.beats-sum(equation_coefficients_tuple); %second term between brackets of the left side
            [knobs_on_correct_subspace,fval]=quadprog(eye(sze),-reshape(vector,1,[]),[],[],equation_coefficients_tuple, obj.TVM_reference_values.pems-equation_rest_of_left_side,obj.knobs.boundaries_min,obj.knobs.boundaries_max); % minimization program
        end    
  
        %Transform masks to fit linear link ids............................
        function [linear_mask] = send_mask_beats_to_linear_space(obj, mask_beats)
            linear_mask=ismember(obj.linear_link_ids,obj.link_ids_beats(mask_beats));
        end    
        
        function [linear_mask_in_mainline_space] = send_linear_mask_to_mainline_space(obj, linear_mask) %if ramp, the designated mainline link will be the precedent one.
            ordered_mainline_link_ids=obj.linear_link_ids(ismember(obj.linear_link_ids,obj.link_ids_beats(obj.mainline_mask_beats)));
            nonlinear_mask=ismember(obj.link_ids_beats,obj.linear_link_ids(linear_mask));
            linear_mask_in_mainline_space = ismember(ordered_mainline_link_ids,obj.linear_link_ids(linear_mask));
            ramp_link_ids=obj.link_ids_beats(logical(nonlinear_mask.*(obj.source_mask_beats+obj.sink_mask_beats).*~obj.mainline_mask_beats));
            indices=find(ismember(obj.linear_link_ids,ramp_link_ids));
            linear_mainline_mask=ismember(obj.linear_link_ids,obj.link_ids_beats(obj.mainline_mask_beats));
            for i=1:size(indices,2)
                left=0;
                l=1;
                while left==0;
                    if linear_mainline_mask(indices(i)-l)==1
                        index=find(ordered_mainline_link_ids==obj.linear_link_ids(indices(i)-l));
                        linear_mask_in_mainline_space(index)=1;
                        left=1;
                    else l=l+1;
                    end
                end    
%                 r=1;
%                 right=0;
%                 while right==0;
%                     if linear_mainline_mask(indices(i)+r)==1
%                         index=find(ordered_mainline_link_ids==obj.linear_link_ids(indices(i)+r));
%                         linear_mask_in_mainline_space(index)=1;
%                         right=1;
%                     else r=r+1;
%                     end
%                 end
            end       
        end  
        
        function [linear_mask_in_mainline_space] = send_mask_beats_to_linear_mainline_space(obj,mask_beats)
            linear_mask_in_mainline_space=obj.send_linear_mask_to_mainline_space(obj.send_mask_beats_to_linear_space( mask_beats));
        end   

        function [linear_mask_in_mainline_space] = send_mask_pems_to_linear_mainline_space(obj, mask_pems)
            mainline_link_ids=obj.link_ids_beats(obj.mainline_mask_beats);
            mainline_masked_link_ids=obj.link_ids_pems(mask_pems);
            linear_mask_in_mainline_space = ismember(mainline_link_ids,mainline_masked_link_ids);
        end    
        
        %temporary.........................................................        
        function [res] = compute_TVM_with_knobs_vector(obj,vector)
            %assumes units are in SI
            alphaIs_tuple=[];
            for i=1:size(obj.knobs.link_ids) %fill the tuple
                if (ismember(obj.knobs.link_ids(i),obj.link_ids_beats(obj.source_mask_beats)))
                    sign=1;
                else
                    sign=-1;
                end
                alphaIs_tuple(1,i)=sign*obj.get_sum_of_template_in_veh(obj.knobs.link_ids(i,1))*obj.get_remaining_monitored_mainline_length(obj.get_next_mainline_link_id(obj.knobs.link_ids(i))); 
            end
            res=obj.TVM_reference_values.beats+alphaIs_tuple*(vector-1);
       end   % Computes TVM with the knobs vector.
       
        function [absciss] = get_linear_absciss_for_link_id(obj,link_id)
           if ~ismember(link_id,obj.link_ids_beats(obj.mainline_mask_beats))
               link_id=obj.get_next_mainline_link_id(link_id);
           end    
           absciss=find(obj.error_function.performance_calculators{1}.send_mask_beats_to_linear_mainline_space(obj.link_ids_beats==link_id));
        end    
       
        function [type] = get_type(obj,link_id)
            if (ismember(link_id,obj.link_ids_beats(obj.source_mask_beats)))
                type='On-Ramp';
            elseif ismember(link_id,obj.link_ids_beats(obj.sink_mask_beats))
                type='Off-Ramp';
            else 
                type='Freeway';
            end    
        end   
       
    end
    
    methods (Hidden, Access = public)
        
        function [] = remove_field_from_property(obj, property, field)
           eval(strcat('obj.',property,'=rmfield(obj.',property,',',Utilities.char2char('field'),');'));
        end    
        
        %saving data......................................................
        function [] = save_figures_and_movie_data(obj)
            obj.plot_zeroten_knobs_history(1);
            obj.plot_result_history(2);
            obj.plot_all_performance_calculators(3);
            plotcmaesdat(324);
            h=figure(324);
            p=[900,0,450,350];
            set(h, 'Position', p);
            figures=findobj(0,'type','figure');
            fig_name= [pwd,'\',obj.algorithm_name,'_reports\',obj.dated_name,'.fig'];
            savefig(figures,fig_name);
            zeroten_knobs_history=obj.knobs.zeroten_knobs_history;
            result_history=obj.error_function.result_history(:,1);
            save([pwd,'\movies\',obj.dated_name,'\zeroten_knobs_history.mat'],'zeroten_knobs_history');
            save([pwd,'\movies\',obj.dated_name,'\result_history.mat'],'result_history');
        end    
        
        function [] = save_congestionPattern_matrix(obj)
            CPindex=obj.error_function.find_performance_calculator('CongestionPattern');
            obj.error_function.performance_calculators{CPindex}.save_plot;
        end    
        
    end    
     
end    



