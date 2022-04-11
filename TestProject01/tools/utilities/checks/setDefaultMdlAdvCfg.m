function setDefaultMdlAdvCfg()
%setDefaultMdlAdvCfg Set the default Model Advisor configuration
%
% Note: Changes to the default Model Advisor configuration are kept across
% MATLAB sessions.

%   Copyright 2021 The MathWorks, Inc.

if dig.isProductInstalled('Simulink Check')
    % Close all models.
    bdclose('all');
    % Set default Model Advisor configuration.
    configFile = [prjNameConv.getNameStr('model advisor configuration'), '.json'];
    ModelAdvisor.setDefaultConfiguration(configFile);
    disp(['Set the default Model Advisor configuration to settings of "', configFile, '".'])
else
    warning('A Simulink Check license is not available.');
end

end
