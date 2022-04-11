function genSrcCode(modelName, varargin)
%genSrcCode Generate source code from model
%   Generate source code from the model.
%
%   genSrcCode(ModelName)
%   genSrcCode(ModelName, 'TreatAsTopMdl')

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Embedded Coder')
    error('An Embedded Coder license is not available.');
end

% Close all models.
bdclose('all');

% Check for prerequisites.
if ~exist(['open_', modelName], 'file')
    error(['Model startup script ''open_', modelName, ''' not found.']);
end

% Change directory to the work folder.
cd(prjDirStruct.getDirPath('work'));

% Remove left over slprj folder in the work folder.
items = dir(pwd);
itemNames = {items.name};
if any(strcmp('slprj', itemNames))
    rmdir('slprj', 's');
end

% Open the model.
disp(['Opening Simulink model ', modelName, '.']);
evalin('base', ['open_', modelName]);

% Generate code.
if nargin > 1
    codeType = 'Top model';
    slbuild(modelName);
else
    codeType = 'Model reference';
    slbuild(modelName, 'ModelReferenceCoderTargetOnly');
end

% Close the model.
disp(['Closing Simulink model ', modelName, '.']);
close_system(modelName, 0);

disp([codeType, ' code for ', modelName, ' is successfully generated.']);

end
