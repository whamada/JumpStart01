function clearCoverageData()
%clearCoverageData Clear coverage data
%   Clear all model and code coverage data.
%
%   clearCoverageData()

%   Copyright 2021 The MathWorks, Inc.

if dig.isProductInstalled('Simulink Coverage')
    cvexit();
else
    warning('A Simulink Coverage license is not available.');
end

end
