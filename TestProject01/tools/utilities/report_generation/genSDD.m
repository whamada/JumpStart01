function genSDD(modelName, varargin)
%genSDD Generate a System Design Description (SDD) report from model
%   Generate a System Design Description (SDD) report from the model.
%
%   genSDD(ModelName)
%   genSDD(ModelName, AuthorNames)
%   genSDD(ModelName, AuthorNames, 'CI')
%   genSDD(ModelName, [], 'CI')

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Report Generator')
    error('A Simulink Report Generator license is not available.');
end

% Close all models.
bdclose('all');

% Check for prerequisites.
if ~exist(['open_', modelName], 'file')
    error(['Model startup script ''open_', modelName, ''' not found.']);
end

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', ['open_', modelName]);

% % Load libraries in the dependency to avoid warnings in the requirement
% % section.
% libs = getLibDependency(modelName);
% load_system(libs);

% Create a configuration for SDD report generation.
sddCfg = StdRpt.SDD(modelName);
% sddCfg.rootSystem = modelName;
sddCfg.title = modelName;
sddCfg.subtitle = 'Design Description';
if nargin > 1 && ~isempty(varargin{1})
    sddCfg.authorNames = varargin{1};
else
    % Leave it at default.
end
sddCfg.titleImgPath = ''; % To be customized.
sddCfg.legalNotice = ''; % To be customized.
sddCfg.timeFormat = ''; % To be customized.
sddCfg.includeDetails = true;
sddCfg.includeModelRefs = false;
sddCfg.includeCustomLibraries = false; % To be customized.
sddCfg.includeLookupTables = true;
sddCfg.includeRequirementsLinks = true;
sddCfg.includeGlossary = true;
sddCfg.outputFormat = 9;
sddCfg.stylesheetIndex = 1;
sddCfg.outputName = [modelName, '_SDD']; % To be customized.
sddCfg.outputDir = fullfile(fileparts(which(modelName)), 'documents');
sddCfg.incrOutputName = 0;
sddCfg.packageType = 1;
sddCfg.UseStatusWindow = false;
if nargin > 2 && ~isempty(varargin{2})
    sddCfg.displayReport = false;
else
    sddCfg.displayReport = true;
end

% Generate the report.
sddCfg.run();

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp(['SDD report for ', modelName, ' is successfully generated.']);

end
