classdef ISODemoTasks < JenkinsJob
    %ISODemoTasks Create a Jenkins build job for the ISO Project
    %   Create a Jenkins build job that exercises all tasks of the ISO
    %   Project.
    
    %   Copyright 2021 The MathWorks, Inc.
    
    properties
        JobDir;      % Directory in which the build job is located.
        ReportDir;   % Directory in which reports for the build job are placed.
        ProjectDir;  % Directory in which the project is located.
        ProjectName; % Name of the project.
        Project;     % Handle to the Project.
        ModelNames;  % Names of models in the ISO_04_Design directory.
    end
    
    properties
        TaskSequence = ["taskGenReqReport"
                        "taskGenSDD"
                        "taskVerifyModel2Reqs"
                        "taskCheckModelStds"
                        "taskDetectDesignErrs"
                        "taskGenSrcCode"
                        "taskCheckCodeStds"
                        "taskProveCodeQuality"
                        "taskVerifyObjCode2Reqs"
                        "taskGenLowLevelTests"
                        "taskVerifyObjCode2LowLevelTests"
                        "taskMergeCodeCoverage"];
    end
    
    methods
        function setupJob(this)
            % Equivalent to (TestClassSetup) of matlab.unittest.TestCase.
            this.JobDir = fileparts(mfilename('fullpath'));
            this.ReportDir = regexprep(this.JobDir, 'job$', 'reports');
            addpath(this.JobDir);
            this.clearCache();
            this.loadProject();
            this.getModelNames();
        end
        
        function setupTask(this)
            % Equivalent to (TestMethodSetup) of matlab.unittest.TestCase.
        end
        
        function cleanupTask(this)
            % Equivalent to (TestMethodTeardown) of matlab.unittest.TestCase.
        end
        
        function cleanupJob(this)
            % Equivalent to (TestClassTeardown) of matlab.unittest.TestCase.
            this.closeProject();
            this.restoreDir();
        end
    end
    
    methods % For use by setupJob.
        function clearCache(this)
            % The MATLAB Compiler Runtime (MCR) cache can cause errors with
            % Polyspace in certain installations. Delete the entire cache
            % to avoid running into this problem.
            cacheDir = fullfile(tempdir, getenv('username'));
            if exist(cacheDir, 'dir')
                rmdir(cacheDir, 's');
            end
        end
        
        function loadProject(this)
            prj = dir(fullfile(this.JobDir, '..', '..', '*.prj'));
            this.ProjectDir = prj.folder;
            this.ProjectName = prj.name;
            this.Project = matlab.project.loadProject(fullfile(this.ProjectDir, this.ProjectName));
        end
        
        function getModelNames(this)
            designDir = prjDirStruct.getDirPath('design root');
            dirList = dir(designDir);
            
            % Ignore common, sample_model, and names that are not a folder such as ".", "..", and ".svn".
            ignoreDir = arrayfun(@(x) (x.isdir == 0) || strcmpi(x.name, 'sample_model') || strcmpi(x.name, 'common') || contains(x.name, '.'), dirList);
            dirList = dirList(~ignoreDir);
            this.ModelNames = arrayfun(@(x) (x.name), dirList, 'UniformOutput', false);
        end
    end
    
    methods % For use by setupTask.
    end
    
    methods % For use by cleanupTask.
    end
    
    methods % For use by cleanupJob.
        function closeProject(this)
            this.Project.close();
        end
        
        function restoreDir(this)
            cd(this.JobDir);
        end
    end
    
    methods % For use by assertion.
        function [newOutcome, newMsg, newCounter] = verifyOutcome(this, outcome, msg, lastMsg, lastOutcome, lastCounter)
            newOutcome = min(outcome, lastOutcome);
            if outcome == 1
                newCounter = lastCounter;
                newMsg = lastMsg;
            else
                % Append failure or warning to exception.
                newCounter = lastCounter + 1;
                if outcome == 0
                    tag = ['(', num2str(newCounter), ') WARNING: '];
                else
                    tag = ['(', num2str(newCounter), ') FAILURE: '];
                end
                if isempty(lastMsg)
                    newMsg = [tag, msg];
                else
                    newMsg = sprintf([lastMsg, '\n', tag, msg]);
                end
            end
        end
        
        function [newOutcome, newMsg, newCounter] = verifyFile(this, file, msg, lastMsg, lastOutcome, lastCounter)
            if exist(file, 'file')
                newOutcome = lastOutcome;
                newCounter = lastCounter;
                newMsg = lastMsg;
            else
                newOutcome = -1;
                % Append failure or warning to exception.
                newCounter = lastCounter + 1;
                tag = ['(', num2str(newCounter), ') FAILURE: '];
                if isempty(lastMsg)
                    newMsg = [tag, msg];
                else
                    newMsg = sprintf([lastMsg, '\n', tag, msg]);
                end
            end
        end
    end
    
    methods % For general use.
        function result = isTopModel(this, model)
            % List all top-level models in the cell array below. Note that
            % a top-level model must not be referenced by another design
            % model. However, it may appear as a referenced model in a test
            % harness.
            allTopModels = {};
            result = any(strcmpi(allTopModels, model));
        end
    end
    
    methods % Equivalent to (Test) of matlab.unittest.TestCase.
        function taskGenReqReport(this)
            % This test point checks if Requirements Reports generated from
            % requirement sets are successfully created by "genReqReport".
            
            % NOTE: Requirements Reports are .docx files prior to R2020a.
            % They are .pdf files starting in R2020a.
            if verLessThan('matlab', '9.8')
                fileExt = 'docx';
            else
                fileExt = 'pdf';
            end
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Requirements Reports from requirement
                % sets in the project.
                reqSets = dir(fullfile(this.ProjectDir, 'ISO_02_Requirements', 'specification', '**', '*.slreqx'));
                for i = 1:numel(reqSets)
                    [~, reqSetName] = fileparts(reqSets(i).name);
                    genReqReport(reqSetName, [], 'CI');
                    file = fullfile(this.ProjectDir, 'ISO_02_Requirements', 'specification', 'documents', [reqSetName, '_ReqReport.', fileExt]);
                    msg = ['Requirements Report not created: ', reqSetName, '_ReqReport.', fileExt, '.'];
                    [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                end
                
                % Capture task execution outcome.
                this.TaskOutcomes('taskGenReqReport') = outcome;
                this.TaskExceptions('taskGenReqReport') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskGenSDD(this)
            % This test point checks if SDD Reports generated from models
            % are successfully created by "genSDD".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of SDD Reports from models in the
                % project.
                for i = 1:numel(this.ModelNames)
                    genSDD(this.ModelNames{i}, [], 'CI');
                    file = fullfile(prjDirStruct.getDirPath('SDD report', this.ModelNames{i}), [prjNameConv.getNameStr('SDD report', this.ModelNames{i}), '.pdf']);
                    msg = ['SDD Report not created: ', this.ModelNames{i}, '_SDD.pdf.'];
                    [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                end
                
                % Capture task execution outcome.
                this.TaskOutcomes('taskGenSDD') = outcome;
                this.TaskExceptions('taskGenSDD') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskVerifyModel2Reqs(this)
            % This test point checks if Simulink Test and Model Coverage
            % Reports generated from models are successfully created by
            % "verifyModel2Reqs".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Simulink Test and Model Coverage
                % Reports (for HLR Simulation Tests) from models in the
                % project.
                title = 'HLR Simulation Tests';
                headers = {'Model Name', 'Num Pass', 'Num Warn', 'Num Fail', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    if exist(fullfile(prjDirStruct.getDirPath('HLR test cases', this.ModelNames{i}), [prjNameConv.getNameStr('HLR test cases', this.ModelNames{i}), '.mldatx']), 'file')
                        if this.isTopModel(this.ModelNames{i})
                            res = verifyModel2Reqs(this.ModelNames{i}, 'TreatAsTopMdl', [], 'CI');
                        else
                            res = verifyModel2Reqs(this.ModelNames{i}, [], [], 'CI');
                        end
                        data(i,:) = {this.ModelNames{i}, res.NumPass, res.NumWarn, res.NumFail, res.Outcome};
                        msg = ['One or more high-level simulation test cases failed on ', this.ModelNames{i}, '.'];
                        [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                        file = fullfile(prjDirStruct.getDirPath('HLR sim results', this.ModelNames{i}), [prjNameConv.getNameStr('HLR sim report', this.ModelNames{i}), '.pdf']);
                        msg = ['Simulation Test Report not created: ', prjNameConv.getNameStr('HLR sim report', this.ModelNames{i}), '.pdf.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                        file = fullfile(prjDirStruct.getDirPath('HLR model coverage', this.ModelNames{i}), [prjNameConv.getNameStr('HLR model coverage report', this.ModelNames{i}), '.html']);
                        msg = ['Model Coverage Report not created: ', prjNameConv.getNameStr('HLR model coverage report', this.ModelNames{i}), '.html.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                    else
                        data(i,:) = {this.ModelNames{i}, [], [], [], []};
                    end
                end
                
                % Capture summary table data.
                this.TaskResults('taskVerifyModel2Reqs') = {title, headers, data};
                
                % Capture task execution outcome.
                this.TaskOutcomes('taskVerifyModel2Reqs') = outcome;
                this.TaskExceptions('taskVerifyModel2Reqs') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskCheckModelStds(this)
            % This test point checks if Model Advisor Reports generated
            % from models are successfully created by "checkModelStds".
            
            % Remove cache if it exists.
            if exist(fullfile(this.ProjectDir, 'work', 'cache', 'slprj', 'modeladvisor'), 'dir')
                rmdir(fullfile(this.ProjectDir, 'work', 'cache', 'slprj', 'modeladvisor'), 's');
            end
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Model Advisor Reports from models in
                % the project.
                title = 'Modeling Standards';
                headers = {'Model Name', 'Num Pass', 'Num Warn', 'Num Fail', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    if this.isTopModel(this.ModelNames{i})
                        res = checkModelStds(this.ModelNames{i}, 'TreatAsTopMdl', 'CI');
                    else
                        res = checkModelStds(this.ModelNames{i}, [], 'CI');
                    end
                    data(i,:) = {this.ModelNames{i}, res.NumPass, res.NumWarn, res.NumFail, res.Outcome};
                    msg = ['One or more modeling standard violations found on ', this.ModelNames{i}, '.'];
                    [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                    file = fullfile(prjDirStruct.getDirPath('model standards', this.ModelNames{i}), [prjNameConv.getNameStr('model standards report', this.ModelNames{i}), '.html']);
                    msg = ['Model Advisor Report not created: ', prjNameConv.getNameStr('model standards report', this.ModelNames{i}), '.html.'];
                    [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                end
                
                % Capture summary table data.
                this.TaskResults('taskCheckModelStds') = {title, headers, data};
                
                % Capture execution outcome.
                this.TaskOutcomes('taskCheckModelStds') = outcome;
                this.TaskExceptions('taskCheckModelStds') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskDetectDesignErrs(this)
            % This test point checks if Design Error Detection Reports
            % generated from models are successfully created by
            % "detectDesignErrs".
            
%             % NOTE: Simulink Design Verifier analysis for detecting design
%             % errors and dead logic must be performed separately prior to
%             % R2019b. They can be analyzed together starting in R2019b.
%             if verLessThan('matlab', '9.7')
%                 reportDir = 'design_error';
%             else
%                 reportDir = '';
%             end
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Design Error Detection Reports from
                % models in the project.
                title = 'Design Error Detection';
                headers = {'Model Name', 'Num Pass', 'Num Warn', 'Num Fail', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    res = detectDesignErrs(this.ModelNames{i}, [], [], 'CI');
                    data(i,:) = {this.ModelNames{i}, res.NumPass, res.NumWarn, res.NumFail, res.Outcome};
                    msg = ['One or more design errors found on ', this.ModelNames{i}, '.'];
                    [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                    file = fullfile(prjDirStruct.getDirPath('design error detection', this.ModelNames{i}), [prjNameConv.getNameStr('design error detection report', this.ModelNames{i}), '.pdf']);
                    msg = ['Design Error Detection Report not created: ', prjNameConv.getNameStr('design error detection report', this.ModelNames{i}), '.pdf.'];
                    [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                end
                
                % Capture summary table data.
                this.TaskResults('taskDetectDesignErrs') = {title, headers, data};
                
                % Capture execution outcome.
                this.TaskOutcomes('taskDetectDesignErrs') = outcome;
                this.TaskExceptions('taskDetectDesignErrs') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskGenSrcCode(this)
            % This test point checks if Code Generation Reports generated
            % from models are successfully created by "genSrcCode".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Code Generation Reports from models in
                % the project.
                for i = 1:numel(this.ModelNames)
                    if this.isTopModel(this.ModelNames{i})
                        genSrcCode(this.ModelNames{i}, 'TreatAsTopMdl');
                        file = fullfile(prjDirStruct.getDirPath('top model code', this.ModelNames{i}), 'html', [prjNameConv.getNameStr('code report', this.ModelNames{i}), '.html']);
                    else
                        genSrcCode(this.ModelNames{i});
                        file = fullfile(prjDirStruct.getDirPath('ref model code', this.ModelNames{i}), 'html', [prjNameConv.getNameStr('code report', this.ModelNames{i}), '.html']);
                    end
                    msg = ['Code Generation Report not created: ', prjNameConv.getNameStr('code report', this.ModelNames{i}), '.html.'];
                    [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                end
                
                % Capture execution outcome.
                this.TaskOutcomes('taskGenSrcCode') = outcome;
                this.TaskExceptions('taskGenSrcCode') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
                
        function taskCheckCodeStds(this)
            % This test point checks if Bug Finder Reports generated from
            % models are successfully created by "checkCodeStds".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Bug Finder Reports from models in the
                % project.
                title = 'Coding Standards';
                headers = {'Model Name', 'Num MISRA violations', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    if this.isTopModel(this.ModelNames{i})
                        res = checkCodeStds(this.ModelNames{i}, 'TreatAsTopMdl', 'CI');
                    else
                        res = checkCodeStds(this.ModelNames{i}, [], 'CI');
                    end
                    data(i,:) = {this.ModelNames{i}, res.NumPurple, res.Outcome};
                    msg = ['One or more coding rule violations found on ', this.ModelNames{i}, '.'];
                    [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                    file = fullfile(prjDirStruct.getDirPath('code standards', this.ModelNames{i}), [prjNameConv.getNameStr('code standards report', this.ModelNames{i}), '.pdf']);
                    msg = ['Bug Finder Report not created: ', prjNameConv.getNameStr('code standards report', this.ModelNames{i}), '.pdf.'];
                    [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                end
                
                % Capture summary table data.
                this.TaskResults('taskCheckCodeStds') = {title, headers, data};
                
                % Capture execution outcome.
                this.TaskOutcomes('taskCheckCodeStds') = outcome;
                this.TaskExceptions('taskCheckCodeStds') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskProveCodeQuality(this)
            % This test point checks if Code Prover Reports generated from
            % models are successfully created by "proveCodeQuality".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Code Prover Reports from models in the
                % project.
                title = 'Code Prover Analysis';
                headers = {'Model Name', 'Num Green', 'Num Orange', 'Num Red', 'Num Gray', 'Num MISRA violations', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    if this.isTopModel(this.ModelNames{i})
                        res = proveCodeQuality(this.ModelNames{i}, 'TreatAsTopMdl', 'IncludeAllChildMdls', 'CI');
                    else
                        res = proveCodeQuality(this.ModelNames{i}, 'IncludeAllChildMdls', 'CI');
                    end
                    data(i,:) = {this.ModelNames{i}, res.NumGreen, res.NumOrange, res.NumRed, res.NumGray, res.NumPurple, res.Outcome};
                    msg = ['One or more coding defects found on ', this.ModelNames{i}, '.'];
                    [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                    file = fullfile(prjDirStruct.getDirPath('code prover', this.ModelNames{i}), [prjNameConv.getNameStr('code prover report', this.ModelNames{i}), '.pdf']);
                    msg = ['Code Prover Report not created: ', prjNameConv.getNameStr('code prover report', this.ModelNames{i}), '.pdf.'];
                    [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                end
                
                % Capture summary table data.
                this.TaskResults('taskProveCodeQuality') = {title, headers, data};
                
                % Capture execution outcome.
                this.TaskOutcomes('taskProveCodeQuality') = outcome;
                this.TaskExceptions('taskProveCodeQuality') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskVerifyObjCode2Reqs(this)
            % This test point checks if Simulink Test and Code Coverage
            % Reports generated from models are successfully created by
            % "verifyObjCode2Reqs".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Simulink Test and Code Coverage
                % Reports (for HLR EOC Tests) from models in the project.
                title = 'HLR SIL Tests';
                headers = {'Model Name', 'Num Pass', 'Num Warn', 'Num Fail', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    if exist(fullfile(prjDirStruct.getDirPath('HLR test cases', this.ModelNames{i}), [prjNameConv.getNameStr('HLR test cases', this.ModelNames{i}), '.mldatx']), 'file')
                        if this.isTopModel(this.ModelNames{i})
                            res = verifyObjCode2Reqs(this.ModelNames{i}, 'SIL', [], 'TreatAsTopMdl', [], 'CI');
                        else
                            res = verifyObjCode2Reqs(this.ModelNames{i}, 'SIL', [], [], [], 'CI');
                        end
                        data(i,:) = {this.ModelNames{i}, res.NumPass, res.NumWarn, res.NumFail, res.Outcome};
                        msg = ['One or more high-level software-in-the-loop test cases failed on ', this.ModelNames{i}, '.'];
                        [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                        file = fullfile(prjDirStruct.getDirPath('HLR SIL results', this.ModelNames{i}), [prjNameConv.getNameStr('HLR SIL report', this.ModelNames{i}), '.pdf']);
                        msg = ['Simulation Test Report not created: ', prjNameConv.getNameStr('HLR SIL report', this.ModelNames{i}), '.pdf.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                        file = fullfile(prjDirStruct.getDirPath('HLR SIL coverage', this.ModelNames{i}), [prjNameConv.getNameStr('HLR code coverage report', this.ModelNames{i}), '.html']);
                        msg = ['Model Coverage Report not created: ', prjNameConv.getNameStr('HLR code coverage report', this.ModelNames{i}), '.html.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                    else
                        data(i,:) = {this.ModelNames{i}, [], [], [], []};
                    end
                end
                
                % Capture summary table data.
                this.TaskResults('taskVerifyObjCode2Reqs') = {title, headers, data};
                
                % Capture execution outcome.
                this.TaskOutcomes('taskVerifyObjCode2Reqs') = outcome;
                this.TaskExceptions('taskVerifyObjCode2Reqs') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskGenLowLevelTests(this)
            % This test point checks if Test Generation Reports generated
            % from models are successfully created by "genLowLevelTests".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Test Generation Reports from models in
                % the project.
                for i = 1:numel(this.ModelNames)
                    if exist(fullfile(prjDirStruct.getDirPath('HLR model coverage', this.ModelNames{i}), [prjNameConv.getNameStr('HLR model coverage', this.ModelNames{i}), '.cvt']), 'file')
                        genLowLevelTests(this.ModelNames{i}, 'CI', true);
                        file = fullfile(prjDirStruct.getDirPath('LLR test cases', this.ModelNames{i}), [prjNameConv.getNameStr('test generation report', this.ModelNames{i}), '.pdf']);
                        msg = ['Test Generation Report not created: ', prjNameConv.getNameStr('test generation report', this.ModelNames{i}), '.pdf.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                    end
                end
                
                % Capture execution outcome.
                this.TaskOutcomes('taskGenLowLevelTests') = outcome;
                this.TaskExceptions('taskGenLowLevelTests') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskVerifyObjCode2LowLevelTests(this)
            % This test point checks if Simulink Test and Code Coverage
            % Reports generated from models are successfully created by
            % "verifyObjCode2LowLevelTests".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Simulink Test and Code Coverage
                % Reports (for LLR EOC Tests) from models in the project.
                title = 'LLR SIL Tests';
                headers = {'Model Name', 'Num Pass', 'Num Warn', 'Num Fail', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    if exist(fullfile(prjDirStruct.getDirPath('LLR test cases', this.ModelNames{i}), [prjNameConv.getNameStr('LLR test cases', this.ModelNames{i}), '.mldatx']), 'file')
                        if this.isTopModel(this.ModelNames{i})
                            res = verifyObjCode2LowLevelTests(this.ModelNames{i}, 'SIL', [], 'TreatAsTopMdl', [], 'CI');
                        else
                            res = verifyObjCode2LowLevelTests(this.ModelNames{i}, 'SIL', [], [], [], 'CI');
                        end
                        data(i,:) = {this.ModelNames{i}, res.NumPass, res.NumWarn, res.NumFail, res.Outcome};
                        msg = ['One or more low-level software-in-the-loop test cases failed on ', this.ModelNames{i}, '.'];
                        [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                        file = fullfile(prjDirStruct.getDirPath('LLR SIL results', this.ModelNames{i}), [prjNameConv.getNameStr('LLR SIL report', this.ModelNames{i}), '.pdf']);
                        msg = ['Simulation Test Report not created: ', prjNameConv.getNameStr('LLR SIL report', this.ModelNames{i}), '.pdf.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                        file = fullfile(prjDirStruct.getDirPath('LLR SIL coverage', this.ModelNames{i}), [prjNameConv.getNameStr('LLR code coverage report', this.ModelNames{i}), '.html']);
                        msg = ['Model Coverage Report not created: ', prjNameConv.getNameStr('LLR code coverage report', this.ModelNames{i}), '.html.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                    else
                        data(i,:) = {this.ModelNames{i}, [], [], [], []};
                    end
                end
                
                % Capture summary table data.
                this.TaskResults('taskVerifyObjCode2LowLevelTests') = {title, headers, data};
                
                % Capture execution outcome.
                this.TaskOutcomes('taskVerifyObjCode2LowLevelTests') = outcome;
                this.TaskExceptions('taskVerifyObjCode2LowLevelTests') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
        
        function taskMergeCodeCoverage(this)
            % This test point checks if Cumulative Code Coverage Reports
            % generated from models are successfully created by
            % "mergeCodeCoverage".
            
            outcome = 1;
            exception = '';
            counter = 0;
            try
                % Test generation of Cumulative Code Coverage Reports from
                % models in the project.
                title = 'Cumulative Code Coverage';
                headers = {'Model Name', 'Statement', 'Decision', 'Condition', 'MCDC', 'Outcome'};
                data = {};
                for i = 1:numel(this.ModelNames)
                    if exist(fullfile(prjDirStruct.getDirPath('HLR SIL results', this.ModelNames{i}), [prjNameConv.getNameStr('HLR SIL results', this.ModelNames{i}), '.mldatx']), 'file') ...
                            && exist(fullfile(prjDirStruct.getDirPath('LLR SIL results', this.ModelNames{i}), [prjNameConv.getNameStr('LLR SIL results', this.ModelNames{i}), '.mldatx']), 'file')
                        res = mergeCodeCoverage(this.ModelNames{i}, 'SIL', 'CI');
                        data(i,:) = {this.ModelNames{i}, res.CumulativeExecutionCov, res.CumulativeDecisionCov, res.CumulativeConditionCov, res.CumulativeMCDCCov, res.Outcome};
                        msg = ['One or more code coverage objectives not achieved on ', this.ModelNames{i}, '.'];
                        [outcome, exception, counter] = this.verifyOutcome(res.Outcome, msg, exception, outcome, counter);
                        file = fullfile(prjDirStruct.getDirPath('SIL coverage', this.ModelNames{i}), [prjNameConv.getNameStr('code coverage report', this.ModelNames{i}), '.html']);
                        msg = ['Cumulative Code Coverage Report not created: ', prjNameConv.getNameStr('code coverage report', this.ModelNames{i}), '.html.'];
                        [outcome, exception, counter] = this.verifyFile(file, msg, exception, outcome, counter);
                    else
                        data(i,:) = {this.ModelNames{i}, [], [], [], [], []};
                    end
                end
                
                % Capture summary table data.
                this.TaskResults('taskMergeCodeCoverage') = {title, headers, data};
                
                % Capture execution outcome.
                this.TaskOutcomes('taskMergeCodeCoverage') = outcome;
                this.TaskExceptions('taskMergeCodeCoverage') = exception;
            catch ME
                % Throw exception if an error occurs.
                rethrow(ME);
            end
        end
    end
    
end
