function varargout = detectDesignErrs(modelName, varargin)
%detectDesignErrs Detect design errors or dead logic in model
%   Detect design errors or dead logic in the model, and then generate the
%   Design Verifier report.
%
%   detectDesignErrs(ModelName)
%   detectDesignErrs(ModelName, 'DetectActiveLogic')
%   detectDesignErrs(ModelName, 'DetectActiveLogic', 300)
%   detectDesignErrs(ModelName, 'DetectActiveLogic', 300, 'CI')
%   detectDesignErrs(ModelName, 'DetectActiveLogic', [], 'CI')
%   detectDesignErrs(ModelName, [], 300, 'CI')
%   detectDesignErrs(ModelName, [], [], 'CI')
%   detectDesignErrs(ModelName, [], [], 'DEV')

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Design Verifier')
    error('A Simulink Design Verifier license is not available.');
end

% Close all models.
bdclose('all');

% Capture useful folder/file paths and names.
outputDir = prjDirStruct.getDirPath('design error detection', modelName);
resultFileName = prjNameConv.getNameStr('design error detection results', modelName);
rptFileName = prjNameConv.getNameStr('design error detection report', modelName);

% Check for prerequisites.
if ~exist(prjNameConv.getNameStr('load command', modelName), 'file')
    error(['Model startup script ''', prjNameConv.getNameStr('load command', modelName), ''' not found.']);
end

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', prjNameConv.getNameStr('load command', modelName));

% Create a configuration for Design Verifier Design Error Detection.
sldvCfg = sldvoptions;
sldvCfg.Mode = 'DesignErrorDetection';
if nargin > 2 && ~isempty(varargin{2})
    sldvCfg.MaxProcessTime = varargin{2};
end
sldvCfg.OutputDir = outputDir;
sldvCfg.MakeOutputFilesUnique = 'off';
sldvCfg.DetectDeadLogic = 'on';
if nargin > 1 && ~isempty(varargin{1})
    % DetectActiveLogic is enabled.
    sldvCfg.DetectActiveLogic = 'on';
else
    % DetectActiveLogic is disabled.
    sldvCfg.DetectActiveLogic = 'off';
end
sldvCfg.DetectOutOfBounds = 'on';
sldvCfg.DetectDSMAccessViolations = 'off'; % Disabled (not qualified).
sldvCfg.DetectDivisionByZero = 'on';
sldvCfg.DetectIntegerOverflow = 'on';
sldvCfg.DetectInfNaN = 'off'; % Disabled (not qualified).
sldvCfg.DetectSubnormal = 'off'; % Disabled (not qualified).
sldvCfg.DesignMinMaxCheck = 'on';
sldvCfg.DetectBlockInputRangeViolations = 'on';
sldvCfg.DetectHISMViolationsHisl_0002 = 'off'; % Disabled (covered by Model Advisor)
sldvCfg.DetectHISMViolationsHisl_0003 = 'off'; % Disabled (covered by Model Advisor)
sldvCfg.DetectHISMViolationsHisl_0004 = 'off'; % Disabled (covered by Model Advisor)
sldvCfg.DetectHISMViolationsHisl_0028 = 'off'; % Disabled (covered by Model Advisor)
sldvCfg.SaveDataFile = 'on';
sldvCfg.DataFileName = resultFileName;
sldvCfg.SaveReport = 'on';
sldvCfg.ReportPDFFormat = 'on';
sldvCfg.ReportFileName = rptFileName;
sldvCfg.DisplayReport = 'off';

% Inspect the model against enabled analysis in the Design Verifier configuration.
[status, files] = sldvrun(modelName, sldvCfg);

if nargin > 3 && ~isempty(varargin{3}) && ~strcmpi(varargin{3}, 'DEV')
    result.Method = 'checkModelStds';
    result.Component = modelName;
    result.NumTotal = 0;
    result.NumPass = 0;
    result.NumWarn = 0;
    result.NumFail = 0;
    result.Results = [];
    % Results exist if the analysis either completes normally (status = 1) or
    % exceeds the maximum processing time (status = -1).
    if status
        load(files.DataFile, 'sldvData');
        if isfield(sldvData, 'Objectives')
            for i = 1:length(sldvData.Objectives)
                if ~strcmpi(sldvData.Objectives(i).type, 'Range')
                    result.NumTotal = result.NumTotal + 1;
                    % Status values are copied from matlab\toolbox\sldv\sldv\+Sldv\+InspectorWorkflow\InspectorUtils.m.
                    switch sldvData.Objectives(i).status
                        case {'Valid', ...
                              'Valid within bound', ...
                              'Satisfied', ...
                              'Active Logic', ...
                              'Satisfied - No Test Case', ...
                              'Satisfied by coverage data', ...
                              'Satisfied by existing testcase', ...
                              'Excluded', ...
                              'Justified'}
                            result.NumPass = result.NumPass + 1;
                        case {'Undecided', ...
                              'Undecided due to stubbing', ...
                              'Undecided due to nonlinearities', ...
                              'Undecided due to division by zero', ...
                              'Valid under approximation',...
                              'Unsatisfiable under approximation',...
                              'Undecided due to approximations', ...
                              'Satisfied - needs simulation', ...
                              'Active Logic - needs simulation', ...
                              'Undecided with testcase', ...
                              'Undecided with counterexample', ...
                              'Undecided due to runtime error', ...
                              'Undecided due to array out of bounds', ...
                              'Produced error'}
                            result.NumWarn = result.NumWarn + 1;
                        case {'Falsified', ...
                              'Falsified - needs simulation', ...
                              'Falsified - No Counterexample', ...
                              'Unsatisfiable', ...
                              'Dead Logic', ...
                              'Dead Logic under approximation'}
                            result.NumFail = result.NumFail + 1;
                        otherwise
                            % Unknown status.
                    end
                end
                if result.NumFail > 0
                    result.Outcome = -1;
                elseif result.NumWarn > 0
                    result.Outcome = 0;
                else
                    result.Outcome = 1;
                end
                result.Results = sldvData;
            end
        end
    end
    varargout{1} = result;
elseif nargin > 3 && ~isempty(varargin{3}) && strcmpi(varargin{3}, 'DEV')
    % Open the report (HTML).
    open(files.Report);
else
    % Open the report (PDF).
    open(files.PDFReport);
end

% Delete the temporary folder.
if exist('rtwgen_tlc', 'dir')
    rmdir('rtwgen_tlc', 's');
end

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp(['Design error detection report for ', modelName, ' is successfully generated.']);

end
