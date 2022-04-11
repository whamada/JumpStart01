function prjSetup()
%prjSetup Set up environment
%   Customize the environment for the current project. This function is set
%   to run at Startup.
%
%   prjSetup()

%   Copyright 2021 The MathWorks, Inc.

% Clear the workspace.
evalin('base', 'clear;');
% Close all figures.
close('all');
% Close all models.
bdclose('all');
% Close all requirement and link sets.
if dig.isProductInstalled('Simulink Requirements')
    slreq.clear();
end
% Close all test files and test results.
if dig.isProductInstalled('Simulink Test')
    sltest.testmanager.clear();
    sltest.testmanager.clearResults();
end
% Clear all coverage data.
if dig.isProductInstalled('Simulink Coverage')
    cvexit();
end
% Set slddLink to true to link model to data dictionary instead of using
% base workspace. Otherwise, set slddLink to false.
slddLink = true;

% Specify the folders where simulation and code generation artifacts are
% placed. Simulation and code generation artifacts are placed in
% CacheFolder and CodeGenFolder, respectively. For convenience, place
% CacheFolder in the working directory.
workDir = prjDirStruct.getDirPath('work');
cacheDir = fullfile(workDir, 'cache');
if ~exist(cacheDir, 'dir')
    mkdir(cacheDir);
end
codeGenDir = prjDirStruct.getDirPath('code');
if ~exist(codeGenDir, 'dir')
    mkdir(codeGenDir);
end
Simulink.fileGenControl('set', 'CacheFolder', cacheDir, 'CodeGenFolder', codeGenDir);

% CD to the working directory.
cd(workDir);

if ~slddLink
    % Load model configurations into base worksapce if model configurations
    % are defined using MATLAB data files instead of Simulink data
    % dictionary files.
    evalin('base', 'nonreusableModelConfig;');
    evalin('base', 'reusableModelConfig;');
end

% Set up RMI.
if dig.isProductInstalled('Simulink Requirements')
    rmiSetup();
else
    warning('A Simulink Requirements license is not available. Setup of RMI skipped.');
end

if dig.isProductInstalled('Simulink Check')
    % Add custom Model Advisor checks.
    Advisor.Manager.refresh_customizations;
%     % Set the default Model Advisor configuration to project settings.
%     setDefaultMdlAdvCfg();
    % Set model classification for use by the Model Testing Dashboard.
    setModelClassification();
else
    warning('A Simulink Check license is not available.');
end

% Refreshes all Simulink customizations.
sl_refresh_customizations();

end
