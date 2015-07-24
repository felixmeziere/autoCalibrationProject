% directory='cmaes_reports\';
% dates=cell(1,3);
% dates={'18-Jul-2015','19-Jul-2015','20-Jul-2015'};
% 
% for j=1:size(dates,2)
%     for i=1:3
%         dated_name=[dates{j},'_',num2str(i)];
%         load([directory,dated_name,'\',dated_name,'_allvariables']);
%         close all
%         obj.knobs.plot_zeroten_knobs_genmean_history(1);
%         figure(1);
%         print(['paper_figures\',dated_name,'_genmean_knobs'],'-dsvg');
%         clear obj
%     end   
% end        




% directory='cmaes_reports\';
% dates={'18-Jul-2015','19-Jul-2015','20-Jul-2015'};
% 
% for j=1:size(dates,2)
%     for i=1:3
%         dated_name=[dates{j},'_',num2str(i)];
%         load([directory,dated_name,'\',dated_name,'_allvariables']);
%         close all
%         obj.plot_performance_calculator_if_exists('CongestionPattern');
%         figure(1);
%         print(['paper_figures\',dated_name,'_cp'],'-dsvg');
%         clear obj
%     end   
% end        



directory='cmaes_reports\';
dates={'09-Jul-2015_1','10-Jul-2015_1','10-Jul-2015_2','10-Jul-2015_4','11-Jul-2015_1','11-Jul-2015_2','11-Jul-2015_3','11-Jul-2015_4','11-Jul-2015_5','12-Jul-2015_1',...
'12-Jul-2015_2','12-Jul-2015_3','12-Jul-2015_4','12-Jul-2015_5','13-Jul-2015_1','13-Jul-2015_2','14-Jul-2015_1','15-Jul-2015_1','14-Jul-2015_2',...
'16-Jul-2015_1','16-Jul-2015_2','17-Jul-2015_1','17-Jul-2015_2','17-Jul-2015_3'};

for j=1:size(dates,2)
        dated_name=dates{j};
        load([directory,dated_name,'\',dated_name,'_allvariables']);
        close all
        obj.knobs.plot_zeroten_knobs_history(1);
        figure(1);
        print(['C:\Users\Felix\Documents\paper\figures\results_figures\Comparing_convergence_time_changing_sigma\','I=',num2str(obj.pems.mainline_uncertainty),'_bnd=[',num2str(obj.knobs.underevaluation_tolerance_coefficient),',',num2str(obj.knobs.overevaluation_tolerance_coefficient),']','_sigma=',num2str(obj.insigma),'_',dated_name,'.svg'],'-dsvg');
        clear obj
end        