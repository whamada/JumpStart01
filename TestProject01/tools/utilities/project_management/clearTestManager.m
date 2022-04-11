function clearTestManager()
%clearTestManager Clear Test Manager
%   Clear all test files and result sets loaded in Test Manager.
%
%   clearTestManager()

%   Copyright 2021 The MathWorks, Inc.

if dig.isProductInstalled('Simulink Test')
    sltest.testmanager.clear();
    sltest.testmanager.clearResults();
else
    warning('A Simulink Test license is not available.');
end

end
