% a=CmaesBox;
% a.load_xls('C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_program.xlsx','C:\Users\Felix\code\autoCalibrationProject\xls\Cmaes_210E_Results.xlsx');
a.evaluate_error_function(ones(11,1)*1.05);
b=a.error_function.error_calculator;
c=a.error_function.performance_calculators{1};
d=a.error_function.performance_calculators{2};
disp('Congestion Pattern');
disp(b.calculate(c.result_from_beats,c.result_from_pems)*a.error_function.weights(1));
disp('TVH');
disp(b.calculate(d.result_from_beats,d.result_from_pems)*a.error_function.weights(2));

