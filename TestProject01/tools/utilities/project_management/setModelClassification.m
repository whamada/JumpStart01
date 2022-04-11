function setModelClassification()
%setModelClassification Set model classification
%   Configure the project labels for use by the Model Testing Dashboard.
%
%   setModelClassification()

%   Copyright 2021 The MathWorks, Inc.

if dig.isProductInstalled('Simulink Check')
    % Set the classification for component interface.
    SwClassifier = struct("name", "SW_COMPONENT_CLASSIFIER", "category", "Design Model", "label", "Component");
    prjService = alm.ProjectService.get(prjDirStruct.getDirPath('root'));
    prjService.serviceCall("setSoftwareClassifier", jsonencode(SwClassifier));
    % Set the classification for unit interface.
    SwClassifier = struct("name", "SW_UNIT_CLASSIFIER", "category", "Design Model", "label", "Unit");
    prjService = alm.ProjectService.get(prjDirStruct.getDirPath('root'));
    prjService.serviceCall("setSoftwareClassifier", jsonencode(SwClassifier));
end

end
