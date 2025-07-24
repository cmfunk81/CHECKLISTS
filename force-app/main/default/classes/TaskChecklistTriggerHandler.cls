public with sharing class TaskChecklistTriggerHandler {

    public static void handleAfterInsertOrUpdate(List<Task> newTasks, Map<Id, Task> oldTaskMap) {
        List<Id> taskIdsToProcess = new List<Id>();

        for (Task t : newTasks) {
            Task oldTask = oldTaskMap != null ? oldTaskMap.get(t.Id) : null;

            Boolean checklistChanged = false;

            if (oldTask == null && t.Checklist_Name__c != null) {
                // Insert - Checklist assigned
                checklistChanged = true;
            } else if (oldTask != null) {
                // Update - checklist lookup changed
                if (t.Checklist_Name__c != oldTask.Checklist_Name__c) {
                    checklistChanged = true;
                }
            }

            if (checklistChanged) {
                taskIdsToProcess.add(t.Id);
            }
        }

        if (!taskIdsToProcess.isEmpty()) {
            ChecklistAssignmentService.createChecklistInstancesForTasks(taskIdsToProcess);
        }
    }
}
