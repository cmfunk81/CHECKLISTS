trigger TaskChecklistTrigger on Task (after insert, after update) {
    List<Id> taskIds = new List<Id>();
    for (Task t : Trigger.new) {
        Task oldTask = Trigger.isUpdate ? Trigger.oldMap.get(t.Id) : null;
        if (t.Checklist_Name__c != null && (oldTask == null || oldTask.Checklist_Name__c != t.Checklist_Name__c)) {
            taskIds.add(t.Id);
        }
    }
    if (!taskIds.isEmpty()) {
        ChecklistAssignmentService.createChecklistInstancesForTasks(taskIds);
    }
}
