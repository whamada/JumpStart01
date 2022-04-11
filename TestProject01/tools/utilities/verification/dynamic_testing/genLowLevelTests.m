function genLowLevelTests(modelName, varargin)
%genLowLevelTests Generate low-level test for model
%   Generate low-level tests for the model based on existing coverage data,
%   and then generate the Design Verifier report.
%
%   genLowLevelTests(ModelName)
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'Decision')
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'ConditionDecision')
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC')
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'Auto')
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'IndividualObjectives')
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'LongTestCases')
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'LargeModel (Nonlinear Extended)')
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'IndividualObjectives', 'AbsTol', 1e-6, 'RelTol', 1e-3)
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'IndividualObjectives', 'AbsTol', 1e-6, 'RelTol', 1e-3, 'MaxProcessTime', 300)
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'IndividualObjectives', 'AbsTol', 1e-6, 'RelTol', 1e-3, 'MaxProcessTime', 300, 'CI', true)
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'IndividualObjectives', 'AbsTol', 1e-6, 'RelTol', 1e-3, 'CI', true)
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'TestSuiteOptimization', 'IndividualObjectives', 'MaxProcessTime', 300, 'CI', true)
%   genLowLevelTests(ModelName, 'ModelCoverageObjectives', 'MCDC', 'AbsTol', 1e-6, 'RelTol', 1e-3, 'MaxProcessTime', 300, 'CI', true)
%   genLowLevelTests(ModelName, 'TestSuiteOptimization', 'IndividualObjectives', 'AbsTol', 1e-6, 'RelTol', 1e-3, 'MaxProcessTime', 300, 'CI', true)
%   genLowLevelTests(ModelName, 'TestSuiteOptimization', 'IndividualObjectives', 'AbsTol', 1e-6, 'RelTol', 1e-3, 'MaxProcessTime', 300)
%   genLowLevelTests(ModelName, 'TestSuiteOptimization', 'IndividualObjectives', 'AbsTol', 1e-6, 'RelTol', 1e-3)
%   genLowLevelTests(ModelName, 'TestSuiteOptimization', 'IndividualObjectives')
%   genLowLevelTests(ModelName, 'AbsTol', 1e-6, 'RelTol', 1e-3)
%   genLowLevelTests(ModelName, 'MaxProcessTime', 300)
%   genLowLevelTests(ModelName, 'CI', true)

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Design Verifier')
    error('A Simulink Design Verifier license is not available.');
end
if ~dig.isProductInstalled('Simulink Test')
    error('A Simulink Test license is not available.');
end
if ~dig.isProductInstalled('Simulink Coverage')
    error('A Simulink Coverage license is not available.');
end

% Close all models.
bdclose('all');

% Clear all coverage data.
cvexit();

% Administer options.
ci = false;
maxProcessTime = 300;
modelCoverageObjectives = 'MCDC';
testSuiteOptimization = 'IndividualObjectives';
absTol = 1e-6;
relTol = 1e-3;
if nargin > 1
    options = varargin(1:end);
    numOptions = numel(options)/2;
    for k = 1:numOptions
        opt = options{2*k-1};
        val = options{2*k};
        if strcmpi(opt, 'ModelCoverageObjectives') && isa(val, 'char')
            if strcmpi(val, 'Decision') || strcmpi(val, 'ConditionDecision') || strcmpi(val, 'MCDC')
                modelCoverageObjectives = val;
            else
                error('Incorrect ModelCoverageObjectives setting.');
            end
        elseif strcmpi(opt, 'TestSuiteOptimization') && isa(val, 'char')
            if strcmpi(val, 'Auto') || strcmpi(val, 'IndividualObjectives') || strcmpi(val, 'LongTestCases') || strcmpi(val, 'LargeModel (Nonlinear Extended)')
                testSuiteOptimization = val;
            else
                error('Incorrect TestSuiteOptimization setting.');
            end
        elseif strcmpi(opt, 'AbsTol') && isa(val, 'double') && isscalar(val)
            absTol = val;
        elseif strcmpi(opt, 'RelTol') && isa(val, 'double') && isscalar(val)
            relTol = val;
        elseif strcmpi(opt, 'MaxProcessTime') && isa(val, 'double') && isscalar(val)
            maxProcessTime = val;
        elseif strcmpi(opt, 'CI') && islogical(val) && isscalar(val)
            ci = val;
        else
            error('Incorrect option-value pair.');
        end
    end
end

% Capture useful folder/file paths and names.
cvtFile = fullfile(prjDirStruct.getDirPath('HLR model coverage', modelName), [prjNameConv.getNameStr('HLR model coverage', modelName), '.cvt']);
outputDir = prjDirStruct.getDirPath('LLR test cases', modelName);
% rptFileName = '$ModelName$_Test_Generation_Report';
rptFileName = prjNameConv.getNameStr('test generation report', modelName);
% testFileName = '$ModelName$_SLDV_Based_Test';
testFileName = prjNameConv.getNameStr('LLR test cases', modelName);
% harnessName = '$ModelName$_Harness_SLDV';
harnessName = prjNameConv.getNameStr('LLR test harness', modelName);

% Delete the old test file and baseline data if they exist.
% harness = fullfile(fileparts(which(modelName)), [harnessName, '.slx']);
% if exist(harness, 'file')
%     delete(harness);
% end
testFile = fullfile(outputDir, [testFileName, '.mldatx']);
if exist(testFile, 'file')
    delete(testFile);
end
bslDir = fullfile(outputDir, 'sl_test_baselines');
if exist(bslDir, 'dir')
    rmdir(bslDir, 's');
end

% Check for prerequisites.
if ~exist(prjNameConv.getNameStr('load command', modelName), 'file')
    error(['Model startup script ''', prjNameConv.getNameStr('load command', modelName), ''' not found.']);
end

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', prjNameConv.getNameStr('load command', modelName));

% Remove the old harness if it exists.
if ~isempty(sltest.harness.find(modelName, 'Name', harnessName))
    sltest.harness.delete(modelName, harnessName);
end

% Create a configuration for Design Verifier Test Generation.
sldvCfg = sldvoptions;
sldvCfg.Mode = 'TestGeneration';
sldvCfg.MaxProcessTime = maxProcessTime;
sldvCfg.DisplayUnsatisfiableObjectives = 'on';
sldvCfg.OutputDir = outputDir;
sldvCfg.MakeOutputFilesUnique = 'off';
sldvCfg.ModelCoverageObjectives = modelCoverageObjectives;
sldvCfg.TestConditions = 'UseLocalSettings';
sldvCfg.TestObjectives = 'UseLocalSettings';
sldvCfg.MaxTestCaseSteps = 10000;
sldvCfg.TestSuiteOptimization = testSuiteOptimization;
sldvCfg.ExtendExistingTests = 'off';
sldvCfg.ExistingTestFile = '';
sldvCfg.IgnoreExistTestSatisfied = 'on';
if exist(cvtFile, 'file')
    % Existing coverage data is available.
    sldvCfg.IgnoreCovSatisfied = 'on';
    sldvCfg.CoverageDataFile = cvtFile;
else
    % Existing coverage data is not available.
    sldvCfg.IgnoreCovSatisfied = 'off';
    sldvCfg.CoverageDataFile = '';
end
sldvCfg.CovFilter = 'off';
sldvCfg.CovFilterFileName = '';
sldvCfg.IncludeRelationalBoundary = 'on';
sldvCfg.AbsoluteTolerance = 1e-05;
sldvCfg.Relativetolerance = 0.01;
sldvCfg.SaveExpectedOutput = 'on';
sldvCfg.SlTestFileName = testFileName;
sldvCfg.SlTestHarnessName = harnessName;
sldvCfg.SaveReport = 'on';
sldvCfg.ReportPDFFormat = 'on';
sldvCfg.ReportFileName = rptFileName;
sldvCfg.DisplayReport = 'off';

% Generate tests from the model based on coverage objectives in the Design Verifier configuration.
[status, files] = sldvrun(modelName, sldvCfg);

% If results exist, export results to a test file with a new test harness.
% Results exist if the analysis either completes normally (status = 1) or
% exceeds the maximum processing time (status = -1).
if status
    % Note that if the analysis completes normally, no test case is
    % generated if there is no satisfied objective. Obviously if the
    % analysis exceeds the maximum processing time, there is no guarantee
    % that any test case is generated at all. Therefore, we must check if
    % sldvData in the result data file contains a TestCases field. If not,
    % the result does not produce any test case.
    load(files.DataFile,'sldvData');
    if isfield(sldvData, 'TestCases') && ~isempty(sldvData.TestCases)
        sltest.testmanager.clear();
        sltest.testmanager.clearResults();
        [~, newHarness] = sltest.import.sldvData(files.DataFile, ...
            'CreateHarness', true, ...
            'TestHarnessName', harnessName, ...
            'TestFileName', testFile);
        load_system(newHarness);
        set_param(newHarness, 'Description', 'Test harness for SLDV generated test cases.');
        set_param(newHarness, 'CovEnable', 'off');
%%%%%%%%% Consider adding an argument for TreatAsTopMdl. %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%         % Set the code interface to "Top model" for SIL/PIL.
%         modelBlk = find_system(newHarness, 'BlockType', 'ModelReference', 'Name', modelName);
%         set_param(modelBlk{1}, 'CodeInterface', 'Top model');
%         % Must NOT set CovEnable to off for top model.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        save_system(newHarness);
        movefile(which(newHarness), fullfile(outputDir, [harnessName, '.slx']));
        
        % Resolve G1467475 (R2016b).
        testFile = sltest.testmanager.TestFile(testFile, false);
        testSuite = testFile.getTestSuites();
        testCase = testSuite.getTestCases();
        bslCriteria = testCase.getBaselineCriteria();
        for bslIdx = 1:length(bslCriteria)
            bslCriteria(bslIdx).remove();
        end
        currentDir = pwd();
        cd(outputDir);
        bslFiles = dir(fullfile('sl_test_baselines', '*.mat'));
        for bslIdx = 1:length(bslFiles)
            testCase.addBaselineCriteria(fullfile('.', 'sl_test_baselines', bslFiles(bslIdx).name));
        end
        cd(currentDir);
        
        % Rename the test suite.
        testSuite.Name = 'SLDV-Based Test';
        
        % Rename the test case.
        testCase.Name = 'Generated Test';
        
        % Modify DESCRIPTION of the test case.
        testCase.Description = 'Simulation test generated by SLDV.';
        
        % Modify CALLBACKS of the test case.
        if isempty(get_param(modelName, 'DataDictionary')) && exist(['DD_', modelName], 'file')
            % Insert command to load data into base workspace if data is
            % defined using MATLAB data file instead of Simulink data
            % dictionary file.
            callback = testCase.getProperty('PostloadCallback');
            callback = [callback, sprintf(['\nDD_', modelName, ';\n'])];
            testCase.setProperty('PostloadCallback', callback);
        end
%         % Override CodeGenFolder for SIL/PIL if necessary.
%         postloadCallback = testCase.getProperty('PostloadCallback');
%         cleanupCallback = testCase.getProperty('CleanupCallback');
%         postloadCallback = [postloadCallback, sprintf(['Simulink.fileGenControl(''set'', ''CodeGenFolder'', prjDirStruct.getDirPath(''xil'', ''', modelName, '''), ''createDir'', true);'])];
%         cleanupCallback = [cleanupCallback, sprintf('Simulink.fileGenControl(''set'', ''CodeGenFolder'', prjDirStruct.getDirPath(''code''));')];
%         testCase.setProperty('PostloadCallback', postloadCallback);
%         testCase.setProperty('CleanupCallback', cleanupCallback);
        
        % Modify BASELINE CRITERIA of the test case.
        bslCriteria = testCase.getBaselineCriteria();
        for bslIdx = 1:length(bslCriteria)
            bslCriteria(bslIdx).AbsTol = absTol;
            bslCriteria(bslIdx).RelTol = relTol;
        end
        
        % Modify ITERATIONS of the test case.
        testCase.setProperty('FastRestart', true);
        
        % Modify COVERAGE SETTINGS of the test case.
        covSettings = testFile.getCoverageSettings();
        covSettings.RecordCoverage = false;
        covSettings.MdlRefCoverage = true;
        covSettings.MetricSettings = 'dcmtroib';
        
        % Write changes back to test file.
        testFile.saveToFile();
    end
end

if ~ci
    % Open the report.
    open(files.PDFReport);
end

% Delete the temporary folder.
if exist('sldv_covoutput', 'dir')
    rmdir('sldv_covoutput', 's');
end

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp(['Test generation report for ', modelName, ' is successfully generated.']);

end
