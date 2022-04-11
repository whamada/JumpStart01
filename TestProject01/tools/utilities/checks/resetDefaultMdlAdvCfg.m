function resetDefaultMdlAdvCfg()
%resetDefaultMdlAdvCfg Reset the default Model Advisor configuration
%
% Note: Changes to the default Model Advisor configuration are kept across
% MATLAB sessions.

%   Copyright 2021 The MathWorks, Inc.

if dig.isProductInstalled('Simulink Check')
    % Close all models.
    bdclose('all');
    % Set default Model Advisor configuration.
    ModelAdvisor.setDefaultConfiguration('');
    disp('Reset the default Model Advisor configuration to factory settings.')
else
    warning('A Simulink Check license is not available.');
end

end
