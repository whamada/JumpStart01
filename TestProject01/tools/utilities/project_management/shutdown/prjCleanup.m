function prjCleanup()
%prjCleanup Clean up environment
%   Restore the environment before exiting the current project. This
%   function is set to run at Shutdown.
%
%   prjCleanup()

%   Copyright 2021 The MathWorks, Inc.

% Clear the workspace.
evalin('base', 'clear;');

% Close all figures.
close('all');

% Close all models.
bdclose('all');

% Close all requirement and link sets.
if dig.isProductInstalled('Simulink Requirements')
    slreq.clear();
    % restore RMI preference settings
    if exist('prev_rmipref','var')
        rmipref('BiDirectionalLinking',         prev_rmipref.BiDirectionalLinking);
        rmipref('CustomSettings',               prev_rmipref.CustomSettings);
        rmipref('DocumentPathReference',        prev_rmipref.DocumentPathReference);
        rmipref('DuplicateOnCopy',              prev_rmipref.DuplicateOnCopy);
        rmipref('FilterEnable',                 prev_rmipref.FilterEnable);
        rmipref('FilterRequireTags',            prev_rmipref.FilterRequireTags);
        rmipref('FilterExcludeTags',            prev_rmipref.FilterExcludeTags);
        rmipref('FilterMenusByTags',            prev_rmipref.FilterMenusByTags);
        rmipref('FilterConsistencyChecking',    prev_rmipref.FilterConsistencyChecking);
        rmipref('LinkIconFilePath',             prev_rmipref.LinkIconFilePath);
        rmipref('ModelPathReference',           prev_rmipref.ModelPathReference);
        rmipref('ReqDocPathBase',               prev_rmipref.ReqDocPathBase);
        rmipref('OslcServerAddress',            prev_rmipref.OslcServerAddress);
        rmipref('OslcServerUser',               prev_rmipref.OslcServerUser);
        rmipref('OslcLabelTemplate',            prev_rmipref.OslcLabelTemplate);
        rmipref('OslcServerVersion',            prev_rmipref.OslcServerVersion);
        rmipref('OslcServerContextParamName',   prev_rmipref.OslcServerContextParamName);
        rmipref('ReportFollowLibraryLinks',     prev_rmipref.ReportFollowLibraryLinks);
        rmipref('ReportHighlightSnapshots',     prev_rmipref.ReportHighlightSnapshots);
        rmipref('ReportNoLinkItems',            prev_rmipref.ReportNoLinkItems);
        rmipref('ReportUseDocIndex',            prev_rmipref.ReportUseDocIndex);
        rmipref('ReportIncludeTags',            prev_rmipref.ReportIncludeTags);
        rmipref('ReportDocDetails',             prev_rmipref.ReportDocDetails);
        rmipref('ReportLinkToObjects',          prev_rmipref.ReportLinkToObjects);
        rmipref('ReportNavUseMatlab',           prev_rmipref.ReportNavUseMatlab);
        rmipref('ReportUseRelativePath',        prev_rmipref.ReportUseRelativePath);
        rmipref('ResourcePathBase',             prev_rmipref.ResourcePathBase);
        rmipref('SelectionLinkWord',            prev_rmipref.SelectionLinkWord);
        rmipref('SelectionLinkExcel',           prev_rmipref.SelectionLinkExcel);
        rmipref('SelectionLinkDoors',           prev_rmipref.SelectionLinkDoors);
        rmipref('SelectionLinkTag',             prev_rmipref.SelectionLinkTag);
        rmipref('ShowDetailsWhenHighlighted',   prev_rmipref.ShowDetailsWhenHighlighted);
        rmipref('StoreDataExternally',          prev_rmipref.StoreDataExternally);
        rmipref('UnsecureHttpRequests',         prev_rmipref.UnsecureHttpRequests);
        rmipref('UseActiveXButtons',            prev_rmipref.UseActiveXButtons);
        rmipref('OslcServerStripDefaultPort',   prev_rmipref.OslcServerStripDefaultPort);
        rmipref('OslcMatchBrowserContext',      prev_rmipref.OslcMatchBrowserContext);
        rmipref('PolarionServerAddress',        prev_rmipref.PolarionServerAddress);
        rmipref('PolarionProjectId',            prev_rmipref.PolarionProjectId);
        rmipref('DoorsModuleID',                prev_rmipref.DoorsModuleID);
        rmi.settings_mgr('set', 'filterSettings', prev_rmipref.filterSettings);
    end
    rmiReset();
end

% Close all test files and test results.
if dig.isProductInstalled('Simulink Test')
    sltest.testmanager.clear();
    sltest.testmanager.clearResults();
    sltest.testmanager.close();
end

% Clear all coverage data.
if dig.isProductInstalled('Simulink Coverage')
    cvexit();
end

% % Reset the default Model Advisor configuration to factory settings.
% if dig.isProductInstalled('Simulink Check')
%     configFile = ModelAdvisor.getDefaultConfiguration();
%     prjConfigFile = fullfile(prjDirStruct.getDirPath('project configuration root'), 'checks', [prjNameConv.getNameStr('model advisor configuration'), '.json']);
%     if strcmp(configFile, prjConfigFile)
%         resetDefaultMdlAdvCfg();
%     end
% end

% Reset the CacheFolder and CodeGenFolder back to the default.
Simulink.fileGenControl('reset');

% Close the demo live script.
if ~isempty(which('runDemo.mlx'))
    matlab.desktop.editor.findOpenDocument(which('runDemo.mlx')).closeNoPrompt();
end

% Clear the the MATLAB Command Window.
home();

end
