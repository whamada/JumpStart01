function createChecklist(modelName, checklist)
%createChecklist Create checklist from template
%   Make a copy of the checklist from its template.
%
%   createChecklist(ModelName, 'model review checklist')
%   createChecklist(ModelName, 'gate review checklist')
%   createChecklist(ModelName, 'test review checklist')

%   Copyright 2021 The MathWorks, Inc.

% Copy the checklist.
switch checklist
    case 'model review checklist'
        srcChecklist = fullfile(prjDirStruct.getDirPath('checklists'), 'ModelReviewChecklist.xlsx');
        dstChecklist = fullfile(prjDirStruct.getDirPath('model review', modelName), [prjNameConv.getNameStr(checklist, modelName), '.xlsx']);
    case 'gate review checklist'
        srcChecklist = fullfile(prjDirStruct.getDirPath('checklists'), 'ModelGateReviewChecklist.xlsx');
        dstChecklist = fullfile(prjDirStruct.getDirPath('code review', modelName), [prjNameConv.getNameStr(checklist, modelName), '.xlsx']);
    case 'test review checklist'
        srcChecklist = fullfile(prjDirStruct.getDirPath('checklists'), 'SoftwareUnitVerificationReviewChecklist.xlsx');
        dstChecklist = fullfile(prjDirStruct.getDirPath('test cases', modelName), [prjNameConv.getNameStr(checklist, modelName), '.xlsx']);
    otherwise
        warning(['Template for ''', checklist, ''' does not exist.']);
        return;
end

% Check if the checklist already exists.
success = false;
if exist(dstChecklist, 'file') == 2
    answer = questdlg('Existing checklist found. Do you still want to reset the checklist?', ...
        'Checklist Reset Permission', 'Yes', 'No', 'No');
    if strcmp(answer, 'Yes')
        success = resetFile(srcChecklist, dstChecklist);
    end
else
    copyfile(srcChecklist, dstChecklist, 'f');
    success = true;
end

if success
    disp(['Checklist ', [prjNameConv.getNameStr(checklist, modelName), '.xlsx'], ' is successfully added.']);
end

% Open the checklist.
winopen(dstChecklist);

end
