function varargout = verifyModel2Reqs(modelName, top, varargin)
%verifyModel2Reqs Verify model against requirements
%   Verify if the model complies with the high-level software requirements,
%   and then perform model coverage analysis. All tests exercise the
%   compiled model on the host computer via standard simulations.
%
%   verifyModel2Reqs(ModelName)
%   verifyModel2Reqs(ModelName, 'TreatAsTopMdl')
%   verifyModel2Reqs(ModelName, 'TreatAsTopMdl', AuthorNames)
%   verifyModel2Reqs(ModelName, 'TreatAsTopMdl', AuthorNames, 'CI')
%   verifyModel2Reqs(ModelName, 'TreatAsTopMdl', [], 'CI')
%   verifyModel2Reqs(ModelName, [], AuthorNames, 'CI')
%	verifyModel2Reqs(ModelName, [], [], 'CI')

%   Copyright 2021 The MathWorks, Inc.

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
if nargin > 1 && ~isempty(top)
    isTop = true;
else
    isTop = false;
end

% Delete the old results and reports if they exist.
resultFile = fullfile(prjDirStruct.getDirPath('HLR sim results', modelName), [prjNameConv.getNameStr('HLR sim results', modelName), '.mldatx']);
if exist(resultFile, 'file')
    delete(resultFile);
end
rptFile = fullfile(prjDirStruct.getDirPath('HLR sim results', modelName), [prjNameConv.getNameStr('HLR sim report', modelName), '.pdf']);
if exist(rptFile, 'file')
    delete(rptFile);
end
docDir = fullfile(prjDirStruct.getDirPath('HLR sim results', modelName), prjNameConv.getNameStr('HLR sim report', modelName));
if exist(docDir, 'dir')
    rmdir(docDir, 's');
end
cvtFile = fullfile(prjDirStruct.getDirPath('HLR model coverage', modelName), [prjNameConv.getNameStr('HLR model coverage', modelName), '.cvt']);
if exist(cvtFile, 'file')
    delete(cvtFile);
end
htmlFile = fullfile(prjDirStruct.getDirPath('HLR model coverage', modelName), [prjNameConv.getNameStr('HLR model coverage report', modelName), '.html']);
if exist(htmlFile, 'file')
    delete(htmlFile);
end
gifDir = fullfile(prjDirStruct.getDirPath('HLR model coverage', modelName), 'scv_images');
if exist(gifDir, 'dir')
    rmdir(gifDir, 's');
end

% Check for prerequisites.
RBTTestFile = fullfile(prjDirStruct.getDirPath('HLR test cases', modelName), [prjNameConv.getNameStr('HLR test cases', modelName), '.mldatx']);
if ~exist(RBTTestFile, 'file')
    error(['Test file ''', RBTTestFile, ''' not found.']);
end

% Get model information.
% If any of the test case in the test file needs to perform a load_system
% on the test harness, querying the checksum after loading the test file
% leads to an error. To avoid the potential error, get the checksum
% information before loading the test file.
load_system(modelName);
modelVersion = get_param(modelName, 'ModelVersion');
modifiedDate = get_param(modelName, 'LastModifiedDate');
% if isTop
%     modelChecksum = getModelChecksum(modelName, 'TreatAsTopMdl');
% else
%     modelChecksum = getModelChecksum(modelName);
% end

% Verify the model against HLR test cases in the test file.
disp(['Running tests on Simulink model ', modelName, '.']);
sltest.testmanager.clear();
sltest.testmanager.clearResults();
testFile = sltest.testmanager.load(RBTTestFile);
testResult = testFile.run;

% Attach model checksum information to test results.
checksumStr = sprintf(['Model Version: ', modelVersion, '\n\n', ...
    'Model Last Modified On: ', datestr(modifiedDate(5:end), 'dd-mmm-yyyy HH:MM:SS')]);
% if isTop
%     checksumStr = sprintf(['Model Version: ', modelVersion, '\n\n', ...
%         'Model Last Modified On: ', datestr(modifiedDate(5:end), 'dd-mmm-yyyy HH:MM:SS'), '\n\n', ...
%         'Checksum when Compiled as Top Model: ', num2str(modelChecksum')]);
% else
%     checksumStr = sprintf(['Model Version: ', modelVersion, '\n\n', ...
%         'Model Last Modified On: ', datestr(modifiedDate(5:end), 'dd-mmm-yyyy HH:MM:SS'), '\n\n', ...
%         'Checksum when Compiled as Referenced Model: ', num2str(modelChecksum')]);
% end
testResult.getTestFileResults.Description = checksumStr;

% Save test results.
sltest.testmanager.exportResults(testResult, resultFile);

% Save coverage results.
if ~isempty(testResult.CoverageResults)
    cvsave(cvtFile, cv.cvdatagroup(testResult.CoverageResults));
end

if nargin > 2 && ~isempty(varargin{1})
    authors = varargin{1};
else
    authors = '';
end
if nargin > 3 && ~isempty(varargin{2})
    LaunchReport = false;
    cvhtmlOption = '-sRT=0';
    result.Method = 'verifyModel2Reqs';
    result.Component = modelName;
    result.NumTotal = testResult.getTestFileResults().NumTotal;
    result.NumPass = testResult.getTestFileResults().NumPassed;
    result.NumWarn = testResult.getTestFileResults().NumIncomplete;
    result.NumFail = testResult.getTestFileResults().NumFailed;
    if result.NumFail > 0
        result.Outcome = -1;
    elseif result.NumWarn > 0
        result.Outcome = 0;
    else
        result.Outcome = 1;
    end
    if ~isempty(testResult.CoverageResults)
        cov = cv.cvdatagroup(testResult.CoverageResults);
        result.ExecutionCov = executioninfo(cov, modelName);
        result.DecisionCov = decisioninfo(cov, modelName);
        result.ConditionCov = conditioninfo(cov, modelName);
        result.MCDCCov = mcdcinfo(cov, modelName);
    end
    result.Results = testResult.getTestFileResults();
    varargout{1} = result;
else
    LaunchReport = true;
    cvhtmlOption = '-sRT=1';
end

% Generate the test report.
sltest.testmanager.report(testResult, rptFile, ...
    'Author', authors, ...
    'Title',[modelName, ' REQ-Based Tests'], ...
    'IncludeMLVersion', true, ...
    'IncludeTestRequirement', true, ...
    'IncludeSimulationSignalPlots', true, ...
    'IncludeComparisonSignalPlots', false, ...
    'IncludeErrorMessages', true, ...
    'IncludeTestResults', 0, ...
    'IncludeCoverageResult', true, ...
    'IncludeSimulationMetadata', true, ...
    'LaunchReport', LaunchReport);

% Generate the coverage report.
if ~isempty(testResult.CoverageResults)
    cvhtml(htmlFile, cv.cvdatagroup(testResult.CoverageResults), cvhtmlOption);
end

disp(['Requirement-based simulation test report for ', modelName, ' is successfully generated.']);

end
