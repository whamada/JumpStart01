function checksum = getModelChecksum(modelName, varargin)
%getModelChecksum Get checksum of model
%   Return checksum of the model.
%
%   getModelChecksum(ModelName)
%   getModelChecksum(ModelName, 'TreatAsTopMdl')

%   Copyright 2021 The MathWorks, Inc.

if exist(['DD_', modelName], 'file')
    % Load data dictionary if it exists.
    evalin('base', ['DD_', modelName]);
end
load_system(modelName);
if nargin > 1
    checksum = do178c.internal.getModelChecksum(modelName, true);
else
    checksum = do178c.internal.getModelChecksum(modelName, false);
end

end
