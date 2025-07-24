public with sharing class ChecklistController {

    @AuraEnabled(cacheable=true)
    public static List<cf_Checklist_Assigned_Item__c> getChecklistItems(Id taskId) {
        Task t = [
            SELECT Checklist_Instance__c 
            FROM Task 
            WHERE Id = :taskId 
            LIMIT 1
        ];
        if (t.Checklist_Instance__c == null) {
            return new List<cf_Checklist_Assigned_Item__c>();
        }

        return [
            SELECT Id,
                   Checklist_Instance__c,
                   Checklist_Item__c,
                   Checklist_Item__r.Name,
                   Checklist_Item_Label__c,
                   Is_Completed__c,
                   Completed_By__r.Name,
                   Completed_Date_Time__c,
                   Sort_Order__c
            FROM cf_Checklist_Assigned_Item__c
            WHERE Checklist_Instance__c = :t.Checklist_Instance__c
            ORDER BY Sort_Order__c
        ];
    }

    @AuraEnabled
    public static void updateChecklistAssignedItem(Id assignedItemId, Boolean isCompleted, Id taskId) {
        cf_Checklist_Assigned_Item__c item = [
            SELECT Id, Checklist_Instance__c 
            FROM cf_Checklist_Assigned_Item__c 
            WHERE Id = :assignedItemId
        ];
        if (!item.Is_Completed__c) { // Prevent unchecking
            item.Is_Completed__c = isCompleted;
            if (isCompleted) {
                item.Completed_By__c = UserInfo.getUserId();
                item.Completed_Date_Time__c = System.now();
            }
            update item;
        }

        // Check if all items are completed for this task
        updateTaskStatusIfComplete(taskId);
    }

    private static void updateTaskStatusIfComplete(Id taskId) {
        Task t = [
            SELECT Id, Checklist_Instance__c, Status 
            FROM Task 
            WHERE Id = :taskId 
            LIMIT 1
        ];
        if (t.Checklist_Instance__c == null) return;

        Integer totalItems = [SELECT COUNT() FROM cf_Checklist_Assigned_Item__c WHERE Checklist_Instance__c = :t.Checklist_Instance__c];
        Integer completedItems = [SELECT COUNT() FROM cf_Checklist_Assigned_Item__c WHERE Checklist_Instance__c = :t.Checklist_Instance__c AND Is_Completed__c = TRUE];

        if (totalItems > 0 && completedItems == totalItems) {
            t.Status = 'Completed';
            update t;
        }
    }
}
