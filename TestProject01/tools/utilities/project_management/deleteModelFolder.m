function deleteModelFolder(modelName)
%deleteModelFolder Delete model folder
%   Delete the model folder.
%
%   deleteModelFolder(ModelName)

%   Copyright 2021 The MathWorks, Inc.

if nargin < 1
    % Query for the model name if none is provided.
    modelName = char(inputdlg('Enter model name.', 'Model Name', [1 50]));
end

% Check if the model name is valid.
if ~isvarname(modelName)
    error([modelName, ' is an invalid model name. The model name must be a valid MATLAB variable name. See MATLAB help documentation for variable naming rules.']);
end

try
    % Close the model and data dictionary that may still linger in memory.
    bdclose(modelName);
    Simulink.data.dictionary.closeAll(['DD_', modelName, '.sldd'], '-discard');
catch
end

% Get the model folder.
% prj = currentProject();
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
    % Delete folders from project.
    if exist(modelDir, 'dir')
        try
            rmdir(modelDir, 's');
        catch
            warning(['Unable to delete ''', modelDir, ''' from project.']);
        end
    end
    for dirIdx = 1:length(codeDirs)
        if exist(codeDirs{dirIdx}, 'dir')
            try
                rmdir(codeDirs{dirIdx}, 's');
            catch
                warning(['Unable to delete ''', codeDirs{dirIdx}, ''' from project.']);
            end
        end
    end
catch
    error(['Unable to delete ''', modelDir, ''' from project.']);
end

disp(['Model folder ', modelDir, ' is successfully deleted.']);

end
