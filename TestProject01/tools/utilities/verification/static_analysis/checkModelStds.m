function varargout = checkModelStds(modelName, varargin)
%checkModelStds Check model against model standards
%   Check the model against model standards, and then generate the Model
%   Advisor report.
%
%   checkModelStds(ModelName)
%   checkModelStds(ModelName, 'TreatAsTopMdl')
%   checkModelStds(ModelName, 'TreatAsTopMdl', 'CI')
%   checkModelStds(ModelName, [], 'CI')
%   checkModelStds(ModelName, [], 'DEV')

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Check')
    error('A Simulink Check license is not available.');
end

% Close all models.
bdclose('all');

% Delete the old report if it exists.
pdfFile = fullfile(prjDirStruct.getDirPath('model standards', modelName), [prjNameConv.getNameStr('model standards report', modelName), '.pdf']);
if exist(pdfFile, 'file')
    delete(pdfFile);
end
htmlFile = fullfile(prjDirStruct.getDirPath('model standards', modelName), [prjNameConv.getNameStr('model standards report', modelName), '.html']);
if exist(htmlFile, 'file')
    delete(htmlFile);
end

% Check for prerequisites.
if ~exist(prjNameConv.getNameStr('load command', modelName), 'file')
    error(['Model startup script ''', prjNameConv.getNameStr('load command', modelName), ''' not found.']);
end

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', prjNameConv.getNameStr('load command', modelName));

% Inspect the model against enabled checks in the Model Advisor configuration.
if nargin > 1 && ~isempty(varargin{1})
    checkResult = ModelAdvisor.run(modelName, 'Configuration', [prjNameConv.getNameStr('model advisor configuration'), '.json'], 'Force', 'on', 'TreatAsMdlRef', 'off');
else
    checkResult = ModelAdvisor.run(modelName, 'Configuration', [prjNameConv.getNameStr('model advisor configuration'), '.json'], 'Force', 'on', 'TreatAsMdlRef', 'on');
end

% Create a configuration for Model Advisor report generation.
rptCfg = ModelAdvisor.ExportPDFDialog.getInstance;
rptCfg.TaskNode = Simulink.ModelAdvisor.getModelAdvisor(modelName).TaskAdvisorRoot;
if nargin > 2 && ~isempty(varargin{2})
    % Report generation fails in Jenkins if the format is PDF.
    rptCfg.ReportFormat = 'html';
else
    rptCfg.ReportFormat = 'pdf';
end
rptCfg.ReportName = prjNameConv.getNameStr('model standards report', modelName);
rptCfg.ReportPath = prjDirStruct.getDirPath('model standards', modelName);

if nargin > 2 && ~isempty(varargin{2}) && ~strcmpi(varargin{2}, 'DEV')
    rptCfg.ViewReport = false;
    result.Method = 'checkModelStds';
    result.Component = modelName;
    result.NumTotal = 0;
    result.NumPass = 0;
    result.NumWarn = 0;
    result.NumFail = 0;
    result.Results = [];
    for i = 1:length(checkResult)
        if strcmpi(checkResult{i}.system, modelName)
            result.NumTotal = checkResult{i}.geninfo.allCt;
            result.NumPass = checkResult{i}.geninfo.passCt;
            result.NumWarn = checkResult{i}.geninfo.warnCt;
            result.NumFail = checkResult{i}.geninfo.failCt;
            if result.NumFail > 0
                result.Outcome = -1;
            elseif result.NumWarn > 0
                result.Outcome = 0;
            else
                result.Outcome = 1;
            end
            result.Results = checkResult{i};
            break;
        end
    end
    varargout{1} = result;
else
    rptCfg.ViewReport = true;
end

% Generate the report.
rptCfg.Generate;

% Delete the temporary folders.
if exist('rtwgen_tlc', 'dir')
    rmdir('rtwgen_tlc', 's');
end
if exist('sldv_output', 'dir')
    rmdir('sldv_output', 's')
end

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp(['Model Advisor report for ', modelName, ' is successfully generated.']);

end
