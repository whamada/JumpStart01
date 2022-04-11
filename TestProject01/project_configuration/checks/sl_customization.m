function sl_customization(cm)
% cm.addModelAdvisorProcessFcn(@ModelAdvisorProcessFunction);
end

function [checkCellArray taskCellArray] = ModelAdvisorProcessFunction(stage, system, checkCellArray, taskCellArray)
switch stage
    case 'configure'
        ModelAdvisor.setConfiguration('iso26262Checks.json');
end
end