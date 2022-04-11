function success = resetFile(srcFileName, dstFileName)
%resetFile Reset an existing file
%   Replace an existing file with a fresh one. Prompt the user to close the
%   existing file when denied permission to overwrite file.
%
%   resetFile(SrcFileName, DstFileName)

%   Copyright 2021 The MathWorks, Inc.

success = false;
try
    copyfile(srcFileName, dstFileName, 'f');
    success = true;
catch
    answer = questdlg(['Access denied. Please check if the existing file is in use. ', ...
        'Close the file and select "Continue" to proceed. Select "Cancel" to abort.'], ...
        'File Permission', 'Continue', 'Cancel', 'Cancel');
    if strcmp(answer, 'Continue')
        resetFile(srcFileName, dstFileName);
    end
end

end
