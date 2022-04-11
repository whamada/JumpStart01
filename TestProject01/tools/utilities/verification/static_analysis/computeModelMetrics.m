function computeModelMetrics(modelName, varargin)
%computeModelMetrics Compute metrics for model
%   Compute metrics for the model, and then generate the Model Advisor
%   report.
%
%   computeModelMetrics(ModelName)
%   computeModelMetrics(ModelName, 'TreatAsTopMdl')

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Check')
    error('A Simulink Check license is not available.');
end

% Close all models.
bdclose('all');

% Delete the old report if it exists.
pdfFile = fullfile(prjDirStruct.getDirPath('model metrics', modelName), [prjNameConv.getNameStr('model metrics report', modelName), '.pdf']);
if exist(pdfFile, 'file')
    delete(pdfFile);
end

% Check for prerequisites.
if ~exist(prjNameConv.getNameStr('load command', modelName), 'file')
    error(['Model startup script ''', prjNameConv.getNameStr('load command', modelName), ''' not found.']);
end

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', prjNameConv.getNameStr('load command', modelName));

% Meaasure the model against enabled metrics in the Model Advisor configuration.
if nargin > 1
    ModelAdvisor.run(modelName, 'Configuration', 'modelMetrics.json', 'Force', 'on', 'TreatAsMdlRef', 'off');
else
    ModelAdvisor.run(modelName, 'Configuration', 'modelMetrics.json', 'Force', 'on', 'TreatAsMdlRef', 'on');
end

% Create a configuration for Modl Advisor report generation.
rptCfg = ModelAdvisor.ExportPDFDialog.getInstance;
rptCfg.TaskNode = Simulink.ModelAdvisor.getModelAdvisor(modelName).TaskAdvisorRoot;
rptCfg.ReportFormat = 'pdf';
rptCfg.ReportName = prjNameConv.getNameStr('model metrics report', modelName);
rptCfg.ReportPath = prjDirStruct.getDirPath('model metrics', modelName);

% Generate the report.
rptCfg.Generate;

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp(['Model metrics report for ', modelName, ' is successfully generated.']);

end
