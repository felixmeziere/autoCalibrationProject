classdef cmaesAlgorithm < algorithm
    %UNTITLED26 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)
        parameters_required='[fitfun, xstart, insigma]';
        parameters_optional='[inopts,varargin]';
        result_format='[xmin, fmin, counteval, stopflag, out, bestever]';
        algo=cmaes;
    end
    
    properties (Access = public)
        parameters
    end
    
    properties (SetAccess = private)

    end    
    
    methods
    end
    
end

