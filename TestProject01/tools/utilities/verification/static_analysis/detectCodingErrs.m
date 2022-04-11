function varargout = detectCodingErrs(modelName, varargin)
%detectCodingErrs Detect coding errors in generated code
%   Detect coding errors in the generated code, and then generate the Bug
%   Finder report.
%
%   detectCodingErrs(ModelName)
%   detectCodingErrs(ModelName, 'TreatAsTopMdl')
%   detectCodingErrs(ModelName, 'TreatAsTopMdl', 'CI')
%   detectCodingErrs(ModelName, [], 'CI')

%   Copyright 2021 The MathWorks, Inc.

% if ~license('test', 'Polyspace_BF')
%     DAStudio.error('certqualkit:engine:PSBFMissLicense');
% end
if isempty(ver('psbugfinder')) && isempty(ver('psbugfinderserver'))
    error('Link to either Polyspace Bug Finder or Polyspace Bug Finder Server is not available. See "Integrate Polyspace with MATLAB and Simulink" for more information.');
end

% Close all models.
bdclose('all');

% Capture useful folder/file paths and names.
psprjDir = prjDirStruct.getDirPath('bug finder', modelName);
resultDir = fullfile(psprjDir, modelName);
tmplDir = fullfile(polyspaceroot, 'toolbox', 'polyspace', 'psrptgen', 'templates', 'bug_finder');

% Create model specific folder if it does not exist.
if ~exist(psprjDir, 'dir')
    mkdir(psprjDir);
end

% Check for prerequisites.
if ~exist(prjNameConv.getNameStr('load command', modelName), 'file')
    error(['Model startup script ''', prjNameConv.getNameStr('load command', modelName), ''' not found.']);
end
% Bug Finder automatically checks if the generated code exist.

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', prjNameConv.getNameStr('load command', modelName));

% Create a configuration for Bug Finder (Bug Finder Analysis only).
disp(['Analyzing code of Simulink model ', modelName, '.']);
psCfg = pslinkoptions(modelName);
psCfg.VerificationMode = 'BugFinder';
psCfg.VerificationSettings = 'PrjConfig';
psCfg.CxxVerificationSettings = 'PrjConfig';
psCfg.EnableAdditionalFileList = false;
psCfg.AdditionalFileList = {};
psCfg.AutoStubLUT = true;
psCfg.InputRangeMode = 'DesignMinMax';
psCfg.ParamRangeMode = 'None';
psCfg.OutputRangeMode = 'None';
psCfg.ModelRefVerifDepth = 'Current model only';
psCfg.ModelRefByModelRefVerif = false;
psCfg.AddSuffixToResultDir = false;
psCfg.AddToSimulinkProject = false;
psCfg.OpenProjectManager = false;
psCfg.CheckconfigBeforeAnalysis = 'OnWarn';

if nargin > 1 && ~isempty(varargin{1})
    psprjCfg = polyspace.ModelLinkOptions(modelName, psCfg, false);
    tempDir = ['results_', modelName];
else
    psprjCfg = polyspace.ModelLinkOptions(modelName, psCfg, true);
    tempDir = ['results_mr_', modelName];
end
if contains(get_param(modelName, 'TargetLangStandard'), 'C90')
    psprjCfg.TargetCompiler.NoLanguageExtensions = true; % Respect C90 standard if true.
else
    psprjCfg.TargetCompiler.NoLanguageExtensions = false; % Otherwise default to C99.
end
psprjCfg.BugFinderAnalysis.EnableCheckers = true;
psprjCfg.CodingRulesCodeMetrics.CodeMetrics = false;
psprjCfg.CodingRulesCodeMetrics.EnableMisraC3 = false;
psprjCfg.CodingRulesCodeMetrics.Misra3AgcMode = false;
psprjCfg.CodingRulesCodeMetrics.BooleanTypes = {'boolean_T'};
psprjCfg.Macros.DefinedMacros = {'main=main_rtwec', '__restrict__='};
% psprjCfg.InputsStubbing.GenerateResultsFor = 'all-headers';
% psprjCfg.Advanced.Additional = '-stub-embedded-coder-lookup-table-functions';
psprjCfg.ResultsDir = resultDir;
psprjCfg.generateProject(fullfile(psprjDir, [modelName, '_CodingErrorsOnly_config.psprj']));

% Inspect the generated code against enabled analysis in the Bug Finder configuration.
psprj = polyspace.Project();
psprj.Configuration = psprjCfg;
psprj.run('bugFinder');

if nargin > 2 && ~isempty(varargin{2})
    openReport = false;
    result.Method = 'detectCodingErrs';
    result.Component = modelName;
    resObj = psprj.Results;
    defectsSummary = resObj.getSummary('defects');
    if ~isempty(defectsSummary)
        result.NumRed = sum(defectsSummary.Total);
    else
        result.NumRed = 0;
    end
    if result.NumRed > 0
        result.Outcome = -1;
    else
        result.Outcome = 1;
    end
    result.Results.Defects = defectsSummary;
    varargout{1} = result;
else
    openReport = true;
end

% Generate the Bug Finder report.
tmplFile = fullfile(tmplDir, 'BugFinder.rpt');
rptFile = fullfile(psprjDir, [prjNameConv.getNameStr('bug finder report', modelName), '.pdf']);
polyspace_report('-template', tmplFile, '-format', 'PDF', '-output-name', rptFile, '-results-dir', resultDir, '-noview');
if openReport && exist(rptFile, 'file')
    open(rptFile);
end

% Delete the temporary result folder.
if exist(tempDir, 'dir')
    rmdir(tempDir, 's');
end

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp(['Bug Finder report for ', modelName, ' is successfully generated.']);

end
