classdef (Abstract) AlgorithmBox < handle
    %AlgorithmBox : used by any algorithm.
    %   Contains the properties and methods that are used by any algorithm for
    %   the automatic calibration problem (for now, tuning only source and
    %   sink knobs). This allows you to run a program set in an excel
    %   file and automaticlly registers the results in another excel file.
    
    properties (Abstract, Constant)
        
        algorithm_name %name used sometimes.
        
    end    
    
    properties (Abstract, Access = public)
        
        starting_point %starting vector or matrix. If the starting point is a matrix (e.g. if is a population for an evolutionnary algorithm), the columns are vectors (individuals) and the rows are knobs.
        
    end    
    
    properties (Access = public)
        
        performance_calculator@PerformanceCalculator % a PerformanceCalculator subclass, which is a quantity measured in pems or outputed by beats (e.g. TVM).
        error_calculator@ErrorCalculator % an ErrorCalculator subclass, which is a way of comparing two performance calculator values (e.g. L1 norm).
        beats_simulation@BeatsSimulation % the BeatsSimulation object that will run and be overwritten at each algorithm iteration.
        beats_parameters=struct; % the parameters passed to BeatsSimulation.run_beats(beats_parameters).
        pems=struct; % the pems data to compare with the beats results. Input fields : 'days' (e.g. datenum(2014,10,1):datenum(2014,10,10)); 'district' (e.g. 7); 'processed_folder'(e.g. C:\Code). Output Fields : 'data';'TVM'. 
        knobs=struct; % struct with four array fields : (nx1) 'knob_link_ids' containing the ids of the n knobs to tune, (nx1) 'knob_demand_ids' containing their respective demand profile ids, (nx1) 'knob_boundaries_min' containing the value of the minimum and (n x 1) 'knob_boundaries_max' containing the values of the maximum value allowed for each knob (in the same order as in 'knob_link_ids').
        number_runs=1; % the number of times the algorithm will run before going to the next column if an xls program is run. 
        initialization_method@char % initialization method must be 'normal', 'uniform' or 'manual'.
        maxEval=90; % maximum number of times that beats will run.
        maxIter=30; % maximum number of iterations of the algorithm (can be different in Evolutionnary Algorithms for example).
        stopFValue=1000; % the algorithm will stop if a smaller value is reached by error_calculator (this is the goal).
        xls_program % cell array corresponding to the excel file containing configs in the columns, with the same format as given in the template.
        xls_results@char % address of the excel file containing the results, with a format that fits to the method obj.send_result_to_xls.
        current_xls_program_column=2; % in the xls program, number (not 'B' as in Excel) of the config column currently used.
        
    end
                
    properties (SetAccess = protected)
        
        result_for_xls@cell % result of the algorithm to be outputed to the xls file.
        out % struct with various histories and solutions.
        bestEverErrorFunctionValue % smallest error_calculator value reached during the execution. Extracted from out.
        bestEverPoint % vector of knob values that gave the best (smallest) ever function value.
        numberOfFlops % number of flops for the execution. Probably won't be used as BeatsSimulation is way longer than any other function used here : it is the limiting factor and is uncompressible : the number of times BeatsSimulation was run seems enough to measure time or flops.
        numberOfEvaluations % number of times beats ran a simulation. Extracted from out.
        stopFlag; % reason why the algorithm stopped. Extracted from out.
        convergence % convergence speed.
        
    end
    
    properties (Hidden, SetAccess = protected)
        
        %masks pointing at the links with working sensors used on beats 
        %output or on pems data.
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
        
        current_day=1; %current day used in the pems data loaded.
        force_manual_knob_boundaries=0; % 1 if knob boundaries are set manually, 0 if they are set to [link's FD max capacity*number of lanes]/[max value of the link's demand template].
        TVM_beats_all_knobs_set_to_one; % reference value of TVM before tuning the knobs (for initial constraint purposes).
        link_ids % all the link ids of the scenario. For practical reasons.
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
        
        function [obj] = AlgorithmBox()
            obj.knobs.knob_link_ids=[];
            obj.knobs.knob_boundaries_min = [];
            obj.knobs.knob_boundaries_max = [];
        end % useless constructor.
        
        function [] = run_assistant(obj) % assistant to set all the parameters for a single run in the command window.
            obj.ask_for_beats_simulation;
            obj.ask_for_errorFunction;
            obj.ask_for_pems_data;
            obj.ask_for_knob_link_ids;
            obj.ask_for_algorithm_parameters;
            obj.ask_for_starting_point;
        end
        
        function [] = load_properties_from_xls(obj) % load the properties from an excel file in the format described underneath.
            %properties file : an xls file containing the AlgorithmBox
            %properties in the first column and the corresponding
            %expressions to be evaluated by Matlab in the 'current' column
            %(column 2 for a single run).
            %Empty cells in the current column will be ignored.
            for i=1:size(obj.xls_program,1)
                if ~strcmp(obj.xls_program(i,obj.current_xls_program_column),'')
                    eval(strcat('obj.',char(obj.xls_program(i,1)),'=',char(obj.xls_program(i,obj.current_xls_program_column)),';'));
                end
            end
            obj.link_ids=obj.beats_simulation.scenario_ptr.get_link_ids;
            obj.beats_simulation.run_beats(obj.beats_parameters);
            obj.set_knob_demand_ids;
            if (obj.force_manual_knob_boundaries==0)
                obj.set_auto_knob_boundaries;
            end    
            obj.set_starting_point(obj.initialization_method);
        end    
               
        function [] = ask_for_beats_simulation(obj) % ask the user to enter a beats scenario and beats run parameters.
            scenario_ptr = input('Address of the scenario xml file : ', 's');
            obj.beats_simulation = BeatsSimulation;
            obj.beats_simulation.load_scenario(scenario_ptr);
            obj.link_ids=obj.beats_simulation.scenario_ptr.get_link_ids;
            obj.beats_parameters=input(['Enter a struct containing the beats simulation properties (like struct("DURATION",86000,"SIM_DT",5)) : ']);
            obj.beats_simulation.run_beats(obj.beats_parameters);
        end   
        
        function [] = ask_for_pems_data(obj) % ask the user for the pems info (still not implemented).
            startyear=input(['Enter pems data beginning year (integer) : ']);
            startmonth=input(['Enter pems data beginning month (integer) : ']);
            startday=input(['Enter pems data beginning day (integer) : ']);
            endyear=input(['Enter pems data end year (integer) : ']);
            endmonth=input(['Enter pems data end month (integer) : ']);
            endday=input(['Enter pems data end day (integer) : ']);
            obj.pems.days = (datenum(startyear, startmonth, startday):datenum(endyear, endmonth, endday));
            obj.pems.district = input(['Enter district : ']);
            obj.pems.processed_folder = input(['Enter the adress of the peMS processed folder : '], 's');
            obj.load_pems_data;
        end 
        
        function [] = ask_for_knob_link_ids(obj) % set the ids of the knobs to tune in the command window.
            if (size(obj.beats_simulation)~=0)
                obj.knobs.knob_link_ids=[];
                demand2link=obj.beats_simulation.scenario_ptr.get_demandprofile_link_map;
                bad_sources=obj.link_ids(1,logical(~obj.good_source_mask_beats.*obj.source_mask_beats));
                bad_sources=demand2link(ismember(demand2link(:,2),bad_sources),:);
                bad_sinks=obj.link_ids(1,logical(~obj.good_sink_mask_beats.*obj.sink_mask_beats));
                bad_sinks=demand2link(ismember(demand2link(:,2), bad_sinks),:);
                numberOfKnobs=size(bad_sources,1)+size(bad_sinks,1);
                numberMissingKnobs = input(strcat(['Among the ', num2str(numberOfKnobs), ' sources and sinks without sensors, how many knobs have to be tuned ? :']));
                disp(['List of sources (on-ramps or interconnects) without working sensor demand ids and corresponding link ids : ']);
                disp(' ');
                disp(['Demand Id :','     ', 'Link Id :']);
                disp(' ');
                disp(bad_sources);
                disp(' ');
                disp(['List of sinks (off-ramps or interconnects) without working sensor demand ids and corresponding link ids : ']);
                disp(' ');
                disp(['Demand Id :','     ', 'Link Id :']);                                
                disp(' ');
                disp(bad_sinks);
                disp('Link Id (again, for copy-paste) :');
                disp(' ');
                disp([bad_sources(:,2); bad_sinks(:,2)]);
                disp('You can directly select and copy-paste several at a time from the second lists which contains only the link ids.');
                for i=1:numberMissingKnobs
                    obj.knobs.knob_link_ids(i,1)=input(strcat(['knob ', num2str(i),' link id :']));
                end
                obj.set_knob_demand_ids;
                obj.ask_for_knob_boundaries;
            else
                error('No Beats Simulation loaded');
            end    
        end
        
        function [] = ask_for_knob_boundaries(obj) % set the knob boundaries (in the same order as the knob ids) in the command window.
            if (isfield(obj.knobs, 'knob_link_ids'))
                mode='';
                while (~strcmp(mode,'auto') && ~strcmp(mode,'manual'))
                    mode=input('How should the knob boundaries be set ? (auto/manual)','s');
                end    
                if (strcmp(mode,'auto'))
                    obj.set_auto_knob_boundaries;
                elseif (strcmp(mode,'manual'))     
                    obj.knobs.knob_boundaries_max=[];
                    obj.knobs.knob_boundaries_min=[];
                    for i=1:size(obj.knobs.knob_link_ids,1)
                        obj.knobs.knob_boundaries_min(i,1)=input(['Knob ', num2str(obj.knobs.knob_demand_ids(i,1)), ' | ', num2str(obj.knobs.knob_link_ids(i,1)), ' minimum value : ']);
                        obj.knobs.knob_boundaries_max(i,1)=input(['Knob ', num2str(obj.knobs.knob_demand_ids(i,1)), ' | ', num2str(obj.knobs.knob_link_ids(i,1)), ' maximum value : ']);
                    end
                else     
                end
            else
                error('The knobs to tune ids : obj.knobs.knob_link_ids has to be set first.');
            end    
        end    
               
        function [] = ask_for_errorFunction (obj) % set the performance calculator and error calculator in the command window.
            obj.performance_calculator=input(['Enter the name of a "PerformanceCalculator" subclass (like TVM) : ']);
            obj.error_calculator=input(['Enter the name of an "ErrorCalculator" subclass (like L1) : ']);
        end
          
    end
    
    methods (Access = private)
        
        function [] = load_pems_data(obj)   %loads pems data once all the inputs have been given to the object
            obj.pems.peMS5minData= PeMS5minData;
            obj.set_masks_and_pems_data;
            obj.performance_calculator.calculate_from_pems(obj.pems,obj.good_mainline_mask_pems,obj.get_link_length_miles(obj.good_mainline_mask_beats));
            TVmiles=TVM;
            TVmiles.calculate_from_beats(obj.beats_simulation,obj.good_mainline_mask_beats);
            obj.TVM_beats_all_knobs_set_to_one=TVmiles.result_from_beats;
            TVmiles=TVM;
            TVmiles.calculate_from_pems(obj.pems, obj.good_mainline_mask_pems,obj.get_link_length_miles(obj.good_mainline_mask_beats));
            obj.pems.TVM=TVmiles.result_from_pems;
            disp('PeMS data loaded');
        end
        
        function [] = set_auto_knob_boundaries(obj) %sets automatically the knob minimums to zero and maximums to [link's FD max capacity*number of lanes]/[max value of the link's demand template]
            disp('Knob boundaries set automatically :');
            for i=1:size(obj.knobs.knob_link_ids)    
                maxTemplateValue=max(obj.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(obj.knobs.knob_link_ids(i)).demand);       
                lanes=obj.beats_simulation.scenario_ptr.get_link_byID(obj.knobs.knob_link_ids(i)).ATTRIBUTE.lanes;
                FDcapacity=obj.beats_simulation.scenario_ptr.get_fds_with_linkIDs(obj.knobs.knob_link_ids(i)).capacity*lanes;
                obj.knobs.knob_boundaries_min(i,1)=0;
                obj.knobs.knob_boundaries_max(i,1)=FDcapacity/maxTemplateValue;
                disp(['Knob ', num2str(obj.knobs.knob_demand_ids(i,1)), ' | ', num2str(obj.knobs.knob_link_ids(i,1)), ' minimum value : ','0']);
                disp(['Knob ', num2str(obj.knobs.knob_demand_ids(i,1)), ' | ', num2str(obj.knobs.knob_link_ids(i,1)), ' maximum value : ',num2str(FDcapacity/maxTemplateValue)]);
            end    
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
            if ~exist('xls_results_adress','var')
                xls_results_adress='';
            end
            [useless,obj.xls_program,useless] = xlsread(xls_program_adress);
            obj.xls_results=xls_results_adress;
            obj.beats_simulation = BeatsSimulation;
            obj.load_properties_from_xls;
            obj.load_pems_data;
        end
    
        function [] = send_result_to_xls(obj, filename)
            %the legend in the xls file should be written manually.
            %the counter for current cell should be in cell AZ1.
            obj.set_result_for_xls;
            [useless1,useless2,xls]=xlsread(filename, obj.algorithm_name);
            id=xls{1,52};
            xlswrite(filename,id,obj.algorithm_name, strcat('A',num2str(id+1)));
            xlswrite(filename, obj.result_for_xls, obj.algorithm_name, strcat('B',num2str(id+1)));
            xlswrite(filename, id+1,obj.algorithm_name,'AZ1');
        end  % send result of an execution of the algorithm to the output Excel file.
        
    end    
       
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Running algorithm and program                                      %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Abstract, Access = public)
        
        [] = run_algorithm(obj) % single run of the algorithm.
    
    end    
    
    methods (Access = public)
        
        function [result] = errorFunction(obj, knob_values) % the error function used by the algorithm. Compares the beats simulation result and pems data.
            %knob_values : n x 1 array where n is the number of knobs
            %to tune, containing the new values of the knobs.
            disp('Knobs vector and values being tested:');
            disp(' ');
            disp(['Demand Id :','     ', 'Link Id :','     ', 'Value :']);
            disp(' ');
            disp([obj.knobs.knob_demand_ids,obj.knobs.knob_link_ids, knob_values]);
            if (size(knob_values,1)==size(obj.knobs.knob_link_ids,1))
              obj.beats_simulation.scenario_ptr.set_knob_values(obj.knobs.knob_demand_ids, knob_values)
              obj.beats_simulation.run_beats(obj.beats_parameters);
              obj.performance_calculator.calculate_from_beats(obj.beats_simulation, obj.good_mainline_mask_beats);
              result = obj.error_calculator.calculate(obj.performance_calculator.result_from_beats, obj.performance_calculator.result_from_pems);
            else
                error('The matrix with knobs values given does not match the number of knobs to tune or is not a column array.');
            end    
        end
        
        function [] = run_program(obj, firstColumn, lastColumn)
            %run the program set in the program Excel file and print the
            %results in the results Excel file.
            obj.current_xls_program_column=firstColumn;
            while (obj.current_xls_program_column<=lastColumn)
                disp(strcat(['PROGRAM COLUMN ', num2str(obj.current_xls_program_column)]));
                obj.load_properties_from_xls;
                counter=obj.number_runs;          
                while (counter > 0)
                    disp([num2str(counter), ' RUNS REMAINING FOR THESE SETTINGS']);
                    obj.run_algorithm;
                    obj.send_result_to_xls(obj.xls_results);
                    counter=counter-1;
                end
                obj.current_xls_program_column=obj.current_xls_program_column+1; 
           end    
        end % run the program defined by the input Excel file and write its results in the output Excel file.        
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  Utilities                                                          %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    methods (Access = public)
    
        function [length] = get_link_length_miles(obj,link_mask)
            link_length_miles = obj.beats_simulation.scenario_ptr.get_link_lengths('us');
            length = link_length_miles(link_mask);
        end 
    
    end    
    
    methods (Access = public) %supposed to be private but public for debug reasons
        
        function [bool] = is_set_knobs(obj) %check if the knobs struct is set.

            bool = 0;
            if (size(obj.knobs.knob_link_ids,2)~=0 && size(obj.knobs.knob_boundaries_max,2)~=0 && size(obj.knobs.knob_boundaries_min,2)~=0 && size(obj.knobs.knob_demand_ids,2)~=0)
                bool=1;
            end    
        end 
        
        function [] = set_masks_and_pems_data(obj)
            %sets the masks for further link selection and smoothens pems 
            %data. Ugly code...
            sensor_link = obj.beats_simulation.scenario_ptr.get_sensor_link_map;
            vds2id = obj.beats_simulation.scenario_ptr.get_sensor_vds2id_map;
            obj.pems.peMS5minData.load(obj.pems.processed_folder,  vds2id(:,1), obj.pems.days);
            obj.pems.data=obj.pems.peMS5minData.get_data_batch_aggregate(vds2id(:,1), obj.pems.days(obj.current_day), 'smooth', true);
            good_sensor_mask_pems_r = all(~isnan(obj.pems.data.flw), 1);
            good_sensor_ids_r=vds2id(good_sensor_mask_pems_r,2);
            good_sensor_link_r=sensor_link(ismember(sensor_link(:,1), good_sensor_ids_r),:);
            good_sensor_link=zeros(1,2);
            k=1;
            for i= 1:size(good_sensor_link_r(:,2),1)
                if (~ismember(good_sensor_link_r(i,2),good_sensor_link(:,2)))
                    good_sensor_link(k,:)=good_sensor_link_r(i,:);
                    k=k+1;
                end    
            end
            good_sensor_ids=good_sensor_link(:,1);
            obj.good_sensor_mask_pems=reshape(ismember(vds2id(:,2),good_sensor_ids),1,[]);
            good_sensor_link_ids=good_sensor_link(:,2);
            mainline_link_ids=obj.beats_simulation.scenario_ptr.get_link_ids_by_type('freeway');
            obj.mainline_mask_beats=ismember(obj.link_ids, mainline_link_ids);
            obj.source_mask_beats=obj.beats_simulation.scenario_ptr.is_source_link;
            obj.sink_mask_beats=obj.beats_simulation.scenario_ptr.is_sink_link;
            source_link_ids=obj.link_ids(1,obj.source_mask_beats);
            sink_link_ids=obj.link_ids(1,obj.sink_mask_beats);
            obj.mainline_mask_pems=reshape(ismember(sensor_link(:,2), mainline_link_ids),1,[]);
            obj.source_mask_pems=reshape(ismember(sensor_link(:,2), source_link_ids),1,[]);
            obj.sink_mask_pems=reshape(ismember(sensor_link(:,2), sink_link_ids),1,[]);
            obj.good_sensor_mask_beats=ismember(obj.link_ids, good_sensor_link_ids);
            obj.good_mainline_mask_beats=logical(obj.good_sensor_mask_beats.*obj.mainline_mask_beats);
            obj.good_source_mask_beats=logical(obj.good_sensor_mask_beats.*obj.source_mask_beats);
            obj.good_sink_mask_beats=logical(obj.good_sensor_mask_beats.*obj.sink_mask_beats);
            obj.good_mainline_mask_pems=logical(obj.good_sensor_mask_pems.*obj.mainline_mask_pems);
            obj.good_source_mask_pems=logical(obj.good_sensor_mask_pems.*obj.source_mask_pems);
            obj.good_sink_mask_pems=logical(obj.good_sensor_mask_pems.*obj.sink_mask_pems);
            
        end    %sets the masks for further link selection and smoothens flow values.
       
        function [knobs_on_correct_subspace] = project_on_correct_TVM_subspace(obj,vector) % Project vector on the hyperplan of vectors that will make beats output have the same TVM as pems.
            equation_coefficients_tuple=[]; 
            %N tuple that will contain the coefficients of the equation of 
            %the hyperplan. We will call them alpha(i) : alpha(i)= (sum over time of the template values of the demand profile of knob(i))*(remaining mainline length from the corresponding link) 
            %The equation is [(knob1)*alpha(1)+(knob2)*alpha(2)+...+(knobN)*alpha(N)]+[(TVM value given by beats output when all knobs are set to one)-(alpha(1)+...+alpha(N)(this removes the extra contribution of the knobs links this beats TVM))]=pems TVM value
            for i=1:size(obj.knobs.knob_link_ids) %fill the tuple
                if (ismember(obj.knobs.knob_link_ids(i),obj.link_ids(obj.source_mask_beats)))
                    sign=1;
                else
                    sign=-1;
                end
                equation_coefficients_tuple(1,i)=sign*sum(obj.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(obj.knobs.knob_link_ids(i,1)).demand)*obj.get_remaining_mainline_length(obj.get_next_mainline_link_id(obj.knobs.knob_link_ids(i))); 
            end
            equation_rest_of_left_side=obj.TVM_beats_all_knobs_set_to_one-sum(equation_coefficients_tuple); %second term between brackets of the left side
            [knobs_on_correct_subspace,fval]=fmincon(@(x)Utilities.euclidianDistance(x,vector),vector,[],[],equation_coefficients_tuple, obj.pems.TVM-equation_rest_of_left_side,obj.knobs.knob_boundaries_min,obj.knobs.knob_boundaries_max); % minimization program
            
        end    
            
        function []=set_knob_demand_ids(obj)
            obj.knobs.knob_demand_ids=[];
            for i=1:size(obj.knobs.knob_link_ids,1)
                dps=obj.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(obj.knobs.knob_link_ids);
                obj.knobs.knob_demand_ids(i,1)=dps(i).id;
            end
        end
        
        function [mainline_link_id]=get_next_mainline_link_id(obj,input_link_id)
            if ismember(input_link_id,obj.link_ids(logical(obj.source_mask_beats.*~obj.mainline_mask_beats)))
                output_node_id=obj.beats_simulation.scenario_ptr.get_link_byID(input_link_id).end.ATTRIBUTE.node_id;
                output_node=obj.beats_simulation.scenario_ptr.get_node_byID(output_node_id);
                mainline_link_ids=obj.link_ids(obj.mainline_mask_beats);
                output_link_ids=output_node.outputs.output;
                node_output_links=[];
                for i=1:size(output_link_ids,2)
                    node_output_links=output_node.outputs.output(i).ATTRIBUTE.link_id;
                end
                mainline_link_id=node_output_links(ismember(node_output_links,mainline_link_ids));
            elseif ismember(input_link_id,obj.link_ids(logical(obj.sink_mask_beats.*~obj.mainline_mask_beats)))
                input_node_id=obj.beats_simulation.scenario_ptr.get_link_byID(input_link_id).begin.ATTRIBUTE.node_id;
                input_node=obj.beats_simulation.scenario_ptr.get_node_byID(input_node_id);
                mainline_link_ids=obj.link_ids(obj.mainline_mask_beats);
                output_link_ids=input_node.outputs.output;
                node_output_links=[];
                for i=1:size(output_link_ids,2)
                    node_output_links=input_node.outputs.output(i).ATTRIBUTE.link_id;
                end
                mainline_link_id=node_output_links(ismember(node_output_links,mainline_link_ids));
            else error('Input link must be non-mainline sink or source');        
            end    
        end % gets the id of the mainline link just after the node connecting the ramp to the freeway.
        
        function [remaining_mainline_length]=get_remaining_mainline_length(obj, first_mainline_link_id)
            remaining_mask=zeros(1,size(obj.link_ids,2));
            k=1;
            while obj.link_ids(k)~=first_mainline_link_id && k<=size(obj.link_ids,2)
                k=k+1;
            end
            for i=k:size(obj.link_ids,2)
                remaining_mask(i)=1;
            end
            remaining_mainline_links_mask=logical(remaining_mask.*obj.mainline_mask_beats);
            remaining_mainline_length=sum(obj.get_link_length_miles(remaining_mainline_links_mask));
        end 
        
        function [res] = compute_TVM_with_knobs_vector(obj,vector)
            equation_coefficients_tuple=[];
            for i=1:size(obj.knobs.knob_link_ids) %fill the tuple
                if (ismember(obj.knobs.knob_link_ids(i),obj.link_ids(obj.source_mask_beats)))
                    sign=1;
                else
                    sign=-1;
                end
                equation_coefficients_tuple(1,i)=sign*sum(obj.beats_simulation.scenario_ptr.get_demandprofiles_with_linkIDs(obj.knobs.knob_link_ids(i,1)).demand)*obj.get_remaining_mainline_length(obj.get_next_mainline_link_id(obj.knobs.knob_link_ids(i))); 
            end
            res=obj.TVM_beats_all_knobs_set_to_one+equation_coefficients_tuple*(vector-ones(size(vector,1),1));
        end    
            
     end
 
end    


