function addModelFolder(modelName, varargin)
%addModelFolder Create a new model folder
%   Create a new model folder based on a design folder template. The model
%   is assumed to be multi-instantiable unless a second argument is
%   specified.
%
%   addModelFolder(ModelName)
%   addModelFolder(ModelName, 'Nonreusable')
%   addModelFolder(ModelName, 'Nonreusable', 'QM')
%   addModelFolder(ModelName, [], 'QM')
%   addModelFolder(ModelName, [], 'ASILA')
%   addModelFolder(ModelName, [], 'ASILB')
%   addModelFolder(ModelName, [], 'ASILC')
%   addModelFolder(ModelName, [], 'ASILD')

%   Copyright 2021 The MathWorks, Inc.

% Set slddLink to true to link model to data dictionary instead of using
% base workspace. Otherwise, set slddLink to false.
slddLink = true;

if nargin < 1
    % Query the model name if none is provided.
    modelName = char(inputdlg('Enter model name.', 'Model Name', [1 50]));
    if isempty(modelName)
        return;
    end
    % Query if the model is multi-instantiable.
    reuse = strcmpi(questdlg('Is the model multi-instantiable?', 'Reusability', 'Yes', 'No', 'Yes'), 'Yes');
    % Query the ASIL of the model.
    asil = char(inputdlg('Enter the ASIL (N/A, QM, ASILA, ASILB, ASILC, or ASILD)', 'ASIL', [1 50], {'N/A'}));
    if isempty(asil)
        asil = 'N/A';
    end
else
    % Check if the model is multi-instantiable.
    if nargin > 1 && ~isempty(varargin{1})
        reuse = false;
    else
        reuse = true;
    end
    % Check if the ASIL is specified.
    if nargin > 2 && ~isempty(varargin{2})
        asil = varargin{2};
    else
        asil = 'N/A';
    end
end

% Check if the model name is valid.
if ~isvarname(modelName)
    error([modelName, ' is an invalid model name. The model name must be a valid MATLAB variable name. See MATLAB help documentation for variable naming rules.']);
end

% Check if the model already exists.
if exist(modelName)
    error(['Model ''', modelName, ''' already exists.']);
end

try
    % Close the model and data dictionary that may still linger in memory.
    bdclose(modelName);
%     Simulink.data.dictionary.closeAll(['DD_', modelName, '.sldd'], '-discard');
    Simulink.data.dictionary.closeAll([prjNameConv.getNameStr('model data', modelName), '.sldd'], '-discard');
catch
end

% Create a new model folder.
prj = currentProject();
% prjRoot = char(prj.RootFolder);
% dirName = fullfile(prjRoot, 'ISO_04_Design');
% srcDirName = fullfile(dirName, 'sample_model');
% dstDirName = fullfile(dirName, modelName);
srcDirName = prjDirStruct.getDirPath('model root', 'sample_model');
dstDirName = prjDirStruct.getDirPath('model root', modelName);
copyfile(srcDirName, dstDirName);

% Create a new model.
% model = Simulink.createFromTemplate('isoModelTemplate.sltx', 'Name', modelName);
model = Simulink.createFromTemplate([prjNameConv.getNameStr('model template'), '.sltx'], 'Name', modelName);
% save_system(model, fullfile(dstDirName, 'specification', modelName));
save_system(model, fullfile(prjDirStruct.getDirPath('model', modelName), modelName));

% Create a MATLAB data file for defining model data in model workspace if
% the model is multi-instantiable.
if reuse
%     fid = fopen(fullfile(dstDirName, 'specification', 'data', ['localDD_', modelName, '.m']), 'w');
    fid = fopen(fullfile(prjDirStruct.getDirPath('model data', modelName), [prjNameConv.getNameStr('local model data', modelName), '.m']), 'w');
    fprintf(fid, '%% Define data to be loaded into model workspace here.\n');
    fclose(fid);
end

if slddLink
    % Create a Simulink data dictionary file for defining model data if the
    % model is not multi-instantiable. This dictionary must include the
    % dictionary that contains the proper model configuration.
%     dataDictionary = Simulink.data.dictionary.create(fullfile(dstDirName, 'specification', 'data', ['DD_', modelName, '.sldd']));
    dataDictionary = Simulink.data.dictionary.create(fullfile(prjDirStruct.getDirPath('model data', modelName), [prjNameConv.getNameStr('model data', modelName), '.sldd']));
    if reuse
        dataDictionary.addDataSource('csMultiInstance.sldd');
    else
        dataDictionary.addDataSource('csSingleInstance.sldd');
    end
    dataDictionary.saveChanges;
else
    % Create a MATLAB data file for defining model data in base workspace
    % if the model is not multi-instantiable.
    if ~reuse
%         fid = fopen(fullfile(dstDirName, 'specification', 'data', ['DD_', modelName, '.m']), 'w');
        fid = fopen(fullfile(prjDirStruct.getDirPath('model data', modelName), [prjNameConv.getNameStr('model data', modelName), '.m']), 'w');
        fprintf(fid, 'if ~exist(''%s__'', ''var'')\n', ['DD_', modelName]);
        fprintf(fid, '    %s__ = true;\n', ['DD_', modelName]);
        fprintf(fid, '    %% Define data to be loaded into base workspace here.\n');
        fprintf(fid, 'end\n');
        fclose(fid);
    end
end

% Create a script for opening the model.
% fid = fopen(fullfile(dstDirName, 'specification', ['open_', modelName, '.m']), 'w');
fid = fopen(fullfile(prjDirStruct.getDirPath('model', modelName), [prjNameConv.getNameStr('load command', modelName), '.m']), 'w');
if reuse
    fprintf(fid, '%% Data is automatically loaded into model workspace.\n');
else
    fprintf(fid, '%% Uncomment the next line to load data into base worksapce if data is\n');
    fprintf(fid, '%% defined using MATLAB data file instead of Simulink data dictionary file.\n');
    if slddLink
        fprintf(fid, '%% ');
    end
    fprintf(fid, '%s;\n', ['DD_', modelName]);
end
fprintf(fid, '%s;\n',  modelName);
fclose(fid);

% Add code verification folders for the new model.
% verifyDir = fullfile(Simulink.fileGenControl('get', 'CodeGenFolder'), '..', 'verification_results');
% verifyDir = erase(verifyDir, [filesep, fullfile('specification', '..')]); % To avoid \.. in the path.
% codeDirs = {'code_coverages', 'code_metrics', 'code_proving', 'code_reviews', ...
%     'code_standard_checks', 'coding_error_detections', 'eoc_test_results'};
codeDirs = {prjDirStruct.getDirPath('code coverage', modelName), ...
            prjDirStruct.getDirPath('code metrics', modelName), ...
            prjDirStruct.getDirPath('code prover', modelName), ...
            prjDirStruct.getDirPath('code standards', modelName), ...
            prjDirStruct.getDirPath('bug finder', modelName), ...
            prjDirStruct.getDirPath('test results', modelName)};
for dirIdx = 1:length(codeDirs)
%     codeDirs{dirIdx} = fullfile(verifyDir, codeDirs{dirIdx}, modelName);
    mkdir(codeDirs{dirIdx});
end

try
    % Add new folders to project.
    prj.addFolderIncludingChildFiles(dstDirName);
    for dirIdx = 1:length(codeDirs)
        prj.addFolderIncludingChildFiles(codeDirs{dirIdx});
    end
    
    % Add new folders to project path.
    modelPaths = genpath(dstDirName);
    dirList = regexp(modelPaths, pathsep, 'split');
    dirList = union(dirList, codeDirs);
    for dirIdx = 1:length(dirList)
        if isfolder(dirList{dirIdx})
            prj.addPath(dirList{dirIdx});
        end
    end
catch
    error(['Unable to add ''', dstDirName, ''' to project.']);
end

% Load data into model workspace from data source if the model is
% multi-instantiable.
if reuse
    ws = get_param(model, 'ModelWorkspace');
    ws.DataSource = 'MATLAB Code';
    ws.MATLABCode = ['localDD_', modelName, ';'];
    ws.reload();
end

if slddLink
    % Link the model to data dictionary.
    set_param(model, 'DataDictionary', ['DD_', modelName, '.sldd']);
    set_param(model, 'EnableAccessToBaseWorkspace', 'off');
else
    % Link the model to coder dictionary.
    set_param(model, 'DataDictionary', 'coderDictionary.sldd');
    set_param(model, 'EnableAccessToBaseWorkspace', 'on');
end

% Create a model configuration reference of the proper model configuration
% and attach it to the model.
Reference = Simulink.ConfigSetRef;
if reuse
    Reference.SourceName = 'csMultiInstance';
else
    Reference.SourceName = 'csSingleInstance';
end
attachConfigSet(modelName, Reference);
setActiveConfigSet(modelName, 'Reference');

% Format the identifier of shared utilities based on the ASIL.
coder.mapping.create(model);
switch asil
    case {'QM', 'ASILA', 'ASILB', 'ASILC', 'ASILD'}
        coder.mapping.defaults.set(model, 'SharedUtility', 'FunctionCustomizationTemplate', asil);
    otherwise
        coder.mapping.defaults.set(model, 'SharedUtility', 'FunctionCustomizationTemplate', 'Dictionary default');
end

% Resave the model.
save_system(model);

disp(['New model folder ', dstDirName, ' is successfully created and added to the current project.']);

end
