function runModelTestingDashboard(varargin)
%runModelTestingDashboard Collect Model Testing Dashboard results
%   Analyze requirements, test cases, and test results of all models in the
%   project for collection of metric data related to testing quality. Limit
%   the scope of analysis to the model if specified.
%
%   runModelTestingDashboard()
%   runModelTestingDashboard(ModelName)

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Check')
    error('A Simulink Check license is not available.');
end

% Close all models.
bdclose('all');

% Close all requirement and link sets.
slreq.clear();

% Close all test files and test results.
if dig.isProductInstalled('Simulink Test')
    sltest.testmanager.clear();
    sltest.testmanager.clearResults();
end

% Check if the dashboard is opened.
dashboardUIService = dashboard.UiService.get();
dashboardIsOpen = ~isempty(dashboardUIService.Windows) && dashboardUIService.Windows.isOpen();

% Collect metric data for the dashboard.
% To view the association of metric IDS to widgets in the dahboard, see
% web(fullfile(docroot, 'slcheck/ref/model-testing-metrics.html'))
metricEngine = metric.Engine();
metricIDs = metricEngine.getAvailableMetricIds();
% metricIDs = ["ConditionCoverageBreakdown", ...
%              "DecisionCoverageBreakdown", ...
%              "ExecutionCoverageBreakdown", ...
%              "MCDCCoverageBreakdown", ...
%              "RequirementWithTestCaseDistribution", ...
%              "RequirementWithTestCasePercentage", ...
%              "RequirementsPerTestCaseDistribution", ...
%              "TestCaseStatusDistribution", ...
%              "TestCaseStatusPercentage", ...
%              "TestCaseTagDistribution", ...
%              "TestCaseTypeDistribution", ...
%              "TestCaseVerificationStatusDistribution", ...
%              "TestCaseWithRequirementDistribution", ...
%              "TestCaseWithRequirementPercentage", ...
%              "TestCasesPerRequirementDistribution"];
if nargin > 0 && ~isempty(varargin{1})
    modelName = varargin{1};
    execute(metricEngine, metricIDs, 'ArtifactScope', {which(modelName), modelName});
else
    modelName = '';
    execute(metricEngine, metricIDs);
end

% Reopen the dashboard.
if dashboardIsOpen
    openModelTestingDashboard(modelName);
end

end
