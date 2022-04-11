function demoSetup()
%demoSetup Set up demo
%   Set up the demo. This function is set to run at startup.
%
%   demoSetup()

%   Copyright 2021 The MathWorks, Inc.

% Open the demo live script.
if ~batchStartupOptionUsed && exist('runDemo.mlx', 'file')
    open('runDemo.mlx');
end

end
