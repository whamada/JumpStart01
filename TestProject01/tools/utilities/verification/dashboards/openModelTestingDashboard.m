function openModelTestingDashboard(varargin)
%openModelTestingDashboard Open the Model Testing Dashboard
%   Open the Model Testing Dashboard. Display metric results of the model
%   if specified.
%
%   openModelTestingDashboard()
%   openModelTestingDashboard(ModelName)

%   Copyright 2021 The MathWorks, Inc.

if ~dig.isProductInstalled('Simulink Check')
    error('A Simulink Check license is not available.');
end

% Close the dashboard.
% Note that the dashboard does not renavigate if it is already opened.
closeModelTestingDashboard();

% Open the dashboard.
if nargin > 0 && ~isempty(varargin{1})
    modelTestingDashboard(which(varargin{1}));
else
    modelTestingDashboard();
end

end
