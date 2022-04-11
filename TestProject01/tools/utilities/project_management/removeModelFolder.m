function removeModelFolder(modelName)
%removeModelFolder Remove model folder
%   Remove the model folder from the current project.
%
%   removeModelFolder(ModelName)

%   Copyright 2021 The MathWorks, Inc.

if nargin < 1
    % Query for the model name if none is provided.
    modelName = char(inputdlg('Enter model name.', 'Model Name', [1 50]));
end

% Check if the model name is valid.
if ~isvarname(modelName)
    error([modelName, ' is an invalid model name. The model name must be a valid MATLAB variable name. See MATLAB help documentation for variable naming rules.']);
end

% Check if the model exists.
if ~exist(modelName)
    error(['Model ''', modelName, ''' does not exists.']);
end

% Get the model folder.
prj = currentProject();
% prjRoot = char(prj.RootFolder);
% modelDir = fullfile(prjRoot, 'ISO_04_Design', modelName);
modelDir = prjDirStruct.getDirPath('model root', modelName);

% Get the build and code verification folders for the model.
codeDirs = {prjDirStruct.getDirPath('top model code', modelName), ...
            prjDirStruct.getDirPath('ref model code', modelName), ...
            prjDirStruct.getDirPath('code coverage', modelName), ...
            prjDirStruct.getDirPath('code metrics', modelName), ...
            prjDirStruct.getDirPath('code prover', modelName), ...
            prjDirStruct.getDirPath('code standards', modelName), ...
            prjDirStruct.getDirPath('bug finder', modelName), ...
            prjDirStruct.getDirPath('test results', modelName)};

try
    % Remove folders from project path.
    modelRecDirStr = genpath(modelDir);
    modelRecDirs = regexp(modelRecDirStr, ';', 'split');
    modelRecDirs = modelRecDirs(~cellfun('isempty', modelRecDirs));
    for recDirIdx = 1:length(modelRecDirs)
        if exist(modelRecDirs{recDirIdx}, 'dir')
            try
                prj.removePath(modelRecDirs{recDirIdx}); % Use try in case the path is already removed.
            catch
                warning(['Unable to remove ''', modelRecDirs{recDirIdx}, ''' from project path.']);
            end
        end
    end
    for dirIdx = 1:length(codeDirs)
        codeRecDirStr = genpath(codeDirs{dirIdx});
        codeRecDirs = regexp(codeRecDirStr, ';', 'split');
        codeRecDirs = codeRecDirs(~cellfun('isempty', codeRecDirs));
        for recDirIdx = 1:length(codeRecDirs)
            if exist(codeRecDirs{recDirIdx}, 'dir')
                try
                    prj.removePath(codeRecDirs{recDirIdx}); % Use try in case the path is already removed.
                catch
                    warning(['Unable to remove ''', codeRecDirs{recDirIdx}, ''' from project path.']);
                end
            end
        end
    end
    
    % Remove folders from project.
    if exist(modelDir, 'dir')
        try
            prj.removeFile(modelDir); % Use try in case the folder is already removed from project.
        catch
            warning(['Unable to remove ''', modelDir, ''' from project.']);
        end
    end
    for dirIdx = 1:length(codeDirs)
        if exist(codeDirs{dirIdx}, 'dir')
            try
                prj.removeFile(codeDirs{dirIdx}); % Use try in case the folder is already removed from project.
            catch
                warning(['Unable to remove ''', codeDirs{dirIdx}, ''' from project.']);
            end
        end
    end
catch
    error(['Unable to remove ''', modelDir, ''' from project.']);
end

disp(['Model folder ', modelDir, ' is successfully removed from the current project.']);

end
