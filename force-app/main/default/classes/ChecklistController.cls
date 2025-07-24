public with sharing class ChecklistController {

    @AuraEnabled(cacheable=true)
    public static List<cf_Checklist_Assigned_Item__c> getChecklistItems(Id taskId) {
        // Get the Checklist_Instance__c from the Task first
        Task t = [SELECT Id, Checklist_Instance__c FROM Task WHERE Id = :taskId LIMIT 1];

        if (t.Checklist_Instance__c == null) {
            return new List<cf_Checklist_Assigned_Item__c>();
        }

        // Query checklist items directly
        List<cf_Checklist_Assigned_Item__c> items = [
            SELECT Id, Checklist_Instance__c, Checklist_Item__c, Checklist_Item_Label__c,
                   Is_Completed__c, Completed_By__r.Name, Completed_Date_Time__c,
                   Checklist_Instance__r.Name
            FROM cf_Checklist_Assigned_Item__c
            WHERE Checklist_Instance__c = :t.Checklist_Instance__c
            ORDER BY Sort_Order__c ASC
        ];
        return items;
    }

@AuraEnabled
public static void updateChecklistItem(Id itemId, Boolean isCompleted, Id taskId) {
    // Get checklist item & related checklist instance
    cf_Checklist_Assigned_Item__c item = [
        SELECT Id, Checklist_Instance__c 
        FROM cf_Checklist_Assigned_Item__c 
        WHERE Id = :itemId 
        LIMIT 1
    ];
    item.Is_Completed__c = isCompleted;
    if (isCompleted) {
        item.Completed_By__c = UserInfo.getUserId();
        item.Completed_Date_Time__c = System.now();
    }
    update item;

    // Get instance & update URL only if blank
    cf_Checklist_Instance__c instance = [
        SELECT Id, Task_URL_Link__c 
        FROM cf_Checklist_Instance__c 
        WHERE Id = :item.Checklist_Instance__c 
        LIMIT 1
    ];
    if (String.isBlank(instance.Task_URL_Link__c) && taskId != null) {
        instance.Task_URL_Link__c = System.URL.getOrgDomainUrl().toExternalForm() + '/' + taskId;
        update instance;
    }

            
        // Check if all items are completed
        List<cf_Checklist_Assigned_Item__c> allItems = [
            SELECT Id, Is_Completed__c 
            FROM cf_Checklist_Assigned_Item__c 
            WHERE Checklist_Instance__c = :item.Checklist_Instance__c
        ];

        Boolean allComplete = true;
        for (cf_Checklist_Assigned_Item__c ci : allItems) {
            if (!ci.Is_Completed__c) {
                allComplete = false;
                break;
            }
        }

        if (allComplete) {
            // Update Task to Completed
            Task t = [SELECT Id FROM Task WHERE Checklist_Instance__c = :item.Checklist_Instance__c LIMIT 1];
            t.Status = 'Completed';
            update t;

        }
}

}
