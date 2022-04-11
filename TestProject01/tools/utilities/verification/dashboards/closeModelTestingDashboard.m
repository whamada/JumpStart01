function closeModelTestingDashboard()
%closeModelTestingDashboard Close the Model Testing Dashboard
%   Close the Model Testing Dashboard.
%
%   closeModelTestingDashboard()

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Check')
    error('A Simulink Check license is not available.');
end

% Close the dashboard.
dashboard.internal.closeDashboard();

end
