function varargout = proveCodeQuality(modelName, varargin)
%proveCodeQuality Prove the absence of defects in generated code
%   Prove the absence of defects in the generated code, and then generate
%   the Code Prover report.
%
%   proveCodeQuality(ModelName)
%   proveCodeQuality(ModelName, 'CI')
%   proveCodeQuality(ModelName, 'TreatAsTopMdl')
%   proveCodeQuality(ModelName, 'TreatAsTopMdl', 'CI')
%   proveCodeQuality(ModelName, 'IncludeAllChildMdls')
%   proveCodeQuality(ModelName, 'IncludeAllChildMdls', 'CI')
%   proveCodeQuality(ModelName, 'TreatAsTopMdl', 'IncludeAllChildMdls')
%   proveCodeQuality(ModelName, 'TreatAsTopMdl', 'IncludeAllChildMdls', 'CI')

%   Copyright 2021 The MathWorks, Inc.

% if ~license('test', 'Polyspace_CP')
%     DAStudio.error('certqualkit:engine:PSCPMissLicense');
% end
if isempty(ver('pscodeprover')) && isempty(ver('pscodeproverserver'))
    error('Link to either Polyspace Code Prover or Polyspace Code Prover Server is not available. See "Integrate Polyspace with MATLAB and Simulink" for more information.');
end

% Close all models.
bdclose('all');

% Capture useful folder/file paths and names.
psprjDir = prjDirStruct.getDirPath('code prover', modelName);
resultDir = fullfile(psprjDir, modelName);
tmplDir = fullfile(polyspaceroot, 'toolbox', 'polyspace', 'psrptgen', 'templates');

% Create model specific folder if it does not exist.
if ~exist(psprjDir, 'dir')
    mkdir(psprjDir);
end

% Check for prerequisites.
if ~exist(prjNameConv.getNameStr('load command', modelName), 'file')
    error(['Model startup script ''', prjNameConv.getNameStr('load command', modelName), ''' not found.']);
end
% Code Prover automatically checks if the generated code exist.

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', prjNameConv.getNameStr('load command', modelName));

% Create a configuration for Code Prover.
disp(['Analyzing code of Simulink model ', modelName, '.']);
psCfg = pslinkoptions(modelName);
psCfg.VerificationMode = 'CodeProver';
psCfg.VerificationSettings = 'PrjConfig';
psCfg.CxxVerificationSettings = 'PrjConfig';
psCfg.EnableAdditionalFileList = false;
psCfg.AdditionalFileList = {};
psCfg.AutoStubLUT = true;
psCfg.InputRangeMode = 'DesignMinMax';
psCfg.ParamRangeMode = 'None';
psCfg.OutputRangeMode = 'None';
if any(strcmpi(varargin, 'IncludeAllChildMdls'))
    psCfg.ModelRefVerifDepth = 'All';
else
    psCfg.ModelRefVerifDepth = 'Current model only';
end
psCfg.ModelRefByModelRefVerif = false;
% psCfg.ResultDir = psprjDir;
psCfg.AddSuffixToResultDir = false;
psCfg.AddToSimulinkProject = false;
psCfg.OpenProjectManager = false;
psCfg.CheckconfigBeforeAnalysis = 'OnWarn';

if any(strcmpi(varargin, 'TreatAsTopMdl'))
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
psprjCfg.CodingRulesCodeMetrics.CodeMetrics = true;
psprjCfg.CodingRulesCodeMetrics.EnableMisraC3 = true;
psprjCfg.CodingRulesCodeMetrics.Misra3AgcMode = true;
psprjCfg.CodingRulesCodeMetrics.MisraC3Subset = 'mandatory-required';
% psprjCfg.CodingRulesCodeMetrics.MisraC3Subset = 'from-file';
% psprjCfg.CodingRulesCodeMetrics.EnableCheckersSelectionByFile = true;
% psprjCfg.CodingRulesCodeMetrics.CheckersSelectionByFile = fullfile(prjDirStruct.getDirPath('project configuration root'), 'checks', 'MISRA_C_2012_ACG.xml');
psprjCfg.CodingRulesCodeMetrics.BooleanTypes = {'boolean_T'};
psprjCfg.ChecksAssumption.SignedIntegerOverflows = 'warn-with-wrap-around';
psprjCfg.ChecksAssumption.UnsignedIntegerOverflows = 'warn-with-wrap-around';
psprjCfg.ChecksAssumption.UncalledFunctionCheck = 'called-from-unreachable';
psprjCfg.Macros.DefinedMacros = {'main=main_rtwec', '__restrict__='};
% psprjCfg.InputsStubbing.GenerateResultsFor = 'all-headers';
% psprjCfg.Advanced.Additional = '-stub-embedded-coder-lookup-table-functions';
psprjCfg.ResultsDir = resultDir;
psprjCfg.generateProject(fullfile(psprjDir, [modelName, '_CompleteCodeAnalysis_config.psprj']));

% Inspect the generated code against enabled analysis in the Code Prover configuration.
psprj = polyspace.Project();
psprj.Configuration = psprjCfg;
psprj.run('codeProver');

if any(strcmpi(varargin, 'CI'))
    openReport = false;
    result.Method = 'proveCodeQuality';
    result.Component = modelName;
    resObj = psprj.Results;
    runtimeSummary = resObj.getSummary('runtime');
    result.NumGreen = str2double(char(runtimeSummary.Green(end)));
    result.NumOrange = str2double(char(runtimeSummary.Orange(end)));
    result.NumRed = str2double(char(runtimeSummary.Red(end)));
    result.NumGray = str2double(char(runtimeSummary.Gray(end)));
    misraC2012Summary = resObj.getSummary('misraC2012');
    if ~isempty(misraC2012Summary)
        result.NumPurple = sum(misraC2012Summary.Total);
    else
        result.NumPurple = 0;
    end
    if result.NumRed > 0 || result.NumGray > 0
        result.Outcome = -1;
    elseif result.NumOrange > 0 || result.NumPurple > 0
        result.Outcome = 0;
    else
        result.Outcome = 1;
    end
    result.Results.Runtime = runtimeSummary;
    result.Results.MisraC2012 = misraC2012Summary;
    varargout{1} = result;
else
    openReport = true;
end

% Generate the developer, call hierarchy, and variable access reports.
tmplFiles = {fullfile(tmplDir, 'Developer.rpt'), ...
             fullfile(tmplDir, 'CallHierarchy.rpt'), ...
             fullfile(tmplDir, 'VariableAccess.rpt')};
rptFiles = {fullfile(psprjDir, [prjNameConv.getNameStr('code prover report', modelName), '.pdf']), ...
            fullfile(psprjDir, [prjNameConv.getNameStr('call hierarchy report', modelName), '.pdf']), ...
            fullfile(psprjDir, [prjNameConv.getNameStr('variable access report', modelName), '.pdf'])};
defaultFiles = {fullfile(psprjDir, 'PolyspaceProject_Developer.pdf'), ...
                fullfile(psprjDir, 'PolyspaceProject_CallHierarchy.pdf'), ...
                fullfile(psprjDir, 'PolyspaceProject_VariableAccess.pdf')};
% Note that the -output-name option cannot accept a cell array.
polyspace_report('-template', tmplFiles, '-format', 'PDF', '-output-name', psprjDir, '-results-dir', resultDir, '-noview');
for i = 1:length(defaultFiles)
    if exist(defaultFiles{i}, 'file')
        movefile(defaultFiles{i}, rptFiles{i}, 'f');
    end
    if openReport && exist(rptFiles{i}, 'file')
        open(rptFiles{i});
    end
end

% Delete the temporary result folder.
if exist(tempDir, 'dir')
    rmdir(tempDir, 's');
end

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp(['Code Prover reports for ', modelName, ' are successfully generated.']);

end
