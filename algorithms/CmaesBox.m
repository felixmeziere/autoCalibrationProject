classdef CmaesBox < EvolutionnaryAlgorithmBox
    %CmaesAlgorithmBox : Subclass of EvolutionnaryAlgorithmBox 
    %   Contains the specific properties and methods used by the cmaes
    %   algorithm.
    
    %Required for loading from xls :
    
    
    %    -> insigma | [real between 2 and 5]
    
    
    %Exhaustive list of all the parameters required for loading this
    %algorithm from xls (compilation of all objects' requirements):
    
    %    -> scenario_ptr | ['adress of the xml scenario file']
    %    -> number_runs | [integer]
    %    -> maxEval | [integer]
    %    -> stopFValue | [real number]
    %    -> beats_parameters.DURATION | [integer]
    %       Should be 86400.
    %    -> beats_parameters.OUTPUT_DT | [integer]
    %       Should be 300.
    %    -> beats_parameters.SIM_DT | [integer]
    %       Should be 4.
    %    -> starting_point | [knob#1value;knob#2value;...;knob#nvalue]
    %       To use only if obj.initialization_method is 'manual'.
    %       Discouraged.
    %    -> multiple_sensor_vds_to_use | [vds#1,vds#2,...,vds#p]
    %    -> vds_sensors_to_delete | [vds#1,vds#2,...,vds#k]
    
    
    
    
    %   -> pems.days | e.g. : [datenum('2014/10/14'),datenum('2014/10/21'),datenum('2014/11/18'),datenum('2014/11/25'),datenum('2014/12/16')]
    %   -> pems.district | [integer]
    %   -> pems.processed_folder | ['adress of the folder']
    %   -> pems.mainline_uncertainty | [fraction of one]
    %   -> pems.monitored_source_sink_uncertainty | [fraction of one]
    
    
    
    
    
    %    -> initial_population_size | [integer] 
    %       Does not change much. Setting it to 4 + floor(3*log([number of
    %       knobs])) which is the size used in CMAES is a good idea.
    %    -> initialization_method | ['uniform'], ['normal'] or ['manual'].
    %       For CMAES, 'uniform' should be used in order to center the starting_point : the initialization doesn't matter very much if sigma is set between reasonable bound (2:5)
    %    -> maxIter | [integer]
    
    %    -> starting_point | [knob#1value;knob#2value;...;knob#nvalue] 
    %       REQUIRED ONLY IF obj.initialization_method is 'manual'
    %    -> normopts.SIGMAS | [sigma#1;sigma#2;...;sigma#n]
    %       REQUIRED ONLY IF obj.initialization_method is 'normal'
    %    -> normopts.CENTERS | [center#1;center#2;...;center#n]
    %       REQUIRED ONLY IF obj.initialization_method is 'normal'
    
    
    
    
    %    -> insigma | [real between 2 and 5]

    
    
    
    %    -> knobs.is_uncertainty_for_monitored_ramps | [0] or [1] DEFAULT:0
    %    -> knobs.link_ids | [link_id#1;link_id#2;...;link_id#n]
    %    -> knobs.force_manual_knob_boundaries | [0] or [1] DEFAULT:0
    %    -> knobs.isnaive_boundaries | [0] or [1] DEFAULT:0
    %    -> knobs.underevaluation_tolerance_coefficient | [coeff] 
    %       coeff should be between 0 and 1 (will multiply perfect value).
    %    -> knobs.overevaluation_tolerance_coefficient | [coeff] 
    %       coeff should be greater than 1 (will multiply perfect value).
    %    -> pems.mainline_uncertainty | [fraction of one]
    %       e.g.: 0.05 for 5%. DEFAULT : 0.1
    %    -> pems.monitored_source_sink_uncertainty | [fraction of one]
    %       e.g.:0.02 for 2%. DEFAULT:0 NOT REQUIRED IF is_uncertainty_for_monitored_ramps==0
    
    %    -> knobs.boundaries_min | [kb#1;...;kb#n] NOT REQUIRED IF force_manual_knob_boundaries==0. 
    %    -> knobs.boundaries_max | [kb#1;...;kb#n] NOT REQUIRED IF force_manual_knob_boundaries==0.
    
    
    
    
    %(NPCSC#k is name of kth PerformanceCalculator subclass and NNSC#k is name of kth Norm subclass)
    
    %    -> settings.error_function.performance_calculators | struct('NPCSC#1',[weight#1], 'NPCSC#2',[weight#2],...,'NPCSC#n',[weight#n])       
    %    -> settings.error_function.norms | {'NNSC#1','NNSC#2',...,'NNSC#n'}
    %    -> error_function.pcs_uncertainty | [fraction of 1]
    
    
    
    %    -> settings.congestion_pattern.false_positive_coefficient | [fraction of 1]
    %    -> settings.congestion_pattern.false_negative_coefficient | [fraction of 1]
    %    -> settings.rectangles | cell(n,1)       
    %    For i from 1 to number of rectangles:    
    %       -> settings.congestion_pattern.rectangles{i,1}.left_absciss | [integer]
    %       -> settings.congestion_pattern.rectangles{i,1}.right_absciss | [integer]
    %       -> settings.congestion_pattern.rectangles{i,1}.up_ordinate | [integer]
    %       -> settings.congestion_pattern.rectangles{i,1}.down_ordinate | [integer]

    
    
    

    
    properties (Constant)
        
        algorithm_name='cmaes';
        
    end
    
    properties (Access = public)
        
        insigma
        
    end    
    
    properties (Hidden, SetAccess = private)
        
        inopts=struct;
        
    end    
    
    properties (SetAccess = private)
        
        bestEver
        
    end    
    
    methods (Access = public)

        function [] = ask_for_algorithm_parameters(obj)
            obj.insigma = input(['Enter initial standard deviation for cmaes (all knob boundaries have been set to a zero to ten scale so value should be between 2 and 5): ']);
            obj.maxIter= input(['Enter the maximum number of cmaes iterations : ']);
            obj.maxEval = input(['Enter the maximum number of beats simulations runs : ']);
            obj.stopFValue = input(['Enter the error value under which the algorithm will stop : ']);
        end  % defined in AlgorithmBox
        
        function [] = set_cmaes_inopts(obj, inopts)
            %to set additional inopts. Be careful, MaxFunEvals, MaxIter,
            %StopFitness, UBounds and LBounds will be overwritten by their 
            %equivalent in AlorithmBox when running the algorithm.
            if (isa(inopts,'struct'))
                obj.inopts=inopts;
            else
                error('inopts must be a struct array');
            end    
        end  % set inopts, a specific parameters struct for cmaes.
        
        function [] = set_cmaes_inopts_field(obj, FIELD, value)
            %to set an additional inopts field. Be careful, MaxFunEvals, MaxIter,
            %StopFitness, UBounds and LBounds will be overwritten by their 
            %equivalent in AlorithmBox when running the algorithm.
            eval(strcat('obj.inopts.',FIELD,'=',num2str(value),';'));
        end  % set a field of inopts.
        
        function [] = run_algorithm(obj)
                  obj.numberOfIterations=1;
                  obj.numberOfEvaluations=1;
                  obj.reset_for_new_run;
                  obj.inopts.MaxFunEvals = obj.maxEval;
                  obj.inopts.MaxIter = obj.maxIter;
                  obj.inopts.StopFitness = obj.stopFValue;
                  obj.inopts.UBounds = ones(obj.knobs.nKnobs,1)*10;
                  obj.inopts.LBounds = zeros(obj.knobs.nKnobs,1);
                  if obj.knobs.is_uncertainty_for_monitored_ramps
                    obj.inopts.UBounds = [obj.inopts.UBounds;ones(size(obj.knobs.monitored_ramp_link_ids,1),1)*10];
                    obj.inopts.LBounds = [obj.inopts.LBounds;zeros(size(obj.knobs.monitored_ramp_link_ids,1),1)];                  
                  end    
                  xstart=obj.knobs.rescale_knobs(obj.starting_point,1);
                  obj.population_size=(4 + floor(3*log(size(xstart,1))));
                  try
                      [lastPoint, lastValue, obj.numberOfEvaluations, obj.stopFlag, obj.out, bestever]=cmaes(@(x)obj.evaluate_error_function(x,1), xstart, obj.insigma, obj.inopts);  
                  catch exception
                      disp(exception);
                      obj.stopFlag='Manual stop or unexpected error';
                  end    
                  load variablescmaes.mat
                  if ~obj.knobs.isnaive_boundaries
                      bestever.x=obj.knobs.project_involved_knob_groups_on_correct_flow_subspace(obj.knobs.rescale_knobs(bestever.x,0));
                  end
                  bestever.x=obj.project_on_correct_TVM_subspace(bestever.x);
                  obj.bestEverPoint=bestever.x;
                  obj.bestEver=bestever;
                  obj.bestEverErrorFunctionValue=bestever.f;
                  obj.numberOfIterations=countiter;
                  obj.set_genmean_data;
                  obj.save_data;
        end   % defined in AlgorithmBox   
   
        function [] = set_result_for_xls(obj)
            %This function should be changed manually to fit the format
            %choosen in the excel file.
            %load 'variablescmaes.mat';
            obj.result_for_xls{1}=obj.error_function.name;
            obj.result_for_xls{2}=Utilities.cellArray2char(obj.settings.error_function.norms);
            obj.result_for_xls{3}=size(obj.starting_point,2);
            obj.result_for_xls{4}=obj.initialization_method;
            obj.result_for_xls{5}=Utilities.double2char(obj.normopts.CENTERS);
            obj.result_for_xls{6}=Utilities.double2char(obj.normopts.SIGMAS);
            obj.result_for_xls{7}=Utilities.double2char(obj.starting_point);
            obj.result_for_xls{8}=obj.insigma;
            obj.result_for_xls{9}=obj.knobs.underevaluation_tolerance_coefficient;
            obj.result_for_xls{10}=obj.knobs.overevaluation_tolerance_coefficient;
            obj.result_for_xls{11}=Utilities.double2char(obj.knobs.boundaries_min);
            obj.result_for_xls{12}=Utilities.double2char(obj.knobs.boundaries_max);
            obj.result_for_xls{13}=obj.maxIter;
            obj.result_for_xls{14}=obj.maxEval;
            obj.result_for_xls{15}=obj.stopFValue;
            obj.result_for_xls{16}=Utilities.double2char(obj.bestEverPoint);
            obj.result_for_xls{17}=obj.bestEverErrorFunctionValue;
            obj.result_for_xls{18}=Utilities.cellArray2char(obj.stopFlag);
            obj.result_for_xls{19}=obj.numberOfIterations;
            obj.result_for_xls{20}=obj.numberOfEvaluations;
            obj.result_for_xls{21}=obj.convergence;
        end % defined in AlgorithmBox
       
    end
    
    methods (Access = protected)
    
        function [figure_title] = get_figure_title(obj)
            figure_title=['CMA-ES: ','Sig=',num2str(obj.insigma),', PeMS Uncertainty=',num2str(obj.pems.uncertainty*100),'%',', Tolerance range=', ...
                '[',num2str(obj.knobs.underevaluation_tolerance_coefficient),',',num2str(obj.knobs.overevaluation_tolerance_coefficient),']',...
                ', FitFun=',obj.error_function.name];
        end    
        
    end    
    
    methods (Static, Access = public)
        function [] = plot_algorithm_data(figureNumber) % plots data on the last running of cmaes.
            if nargin==1
                plotcmaesdat(figureNumber)
            else    
                plotcmaesdat;
            end
        end
    end
        
end

