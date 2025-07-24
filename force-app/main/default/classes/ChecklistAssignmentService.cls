public with sharing class ChecklistAssignmentService {

    @AuraEnabled
    public static void createChecklistInstancesForTasks(List<Id> taskIds) {
        if (taskIds.isEmpty()) return;

        List<Task> tasks = [
            SELECT Id, Subject, Checklist_Name__c, Checklist_Instance__c,
                   Checklist_Name__r.Name
            FROM Task 
            WHERE Id IN :taskIds AND Checklist_Name__c != null
        ];

        List<cf_Checklist_Instance__c> instancesToInsert = new List<cf_Checklist_Instance__c>();
        Map<Id, Task> taskToUpdate = new Map<Id, Task>();
        Map<Id, List<cf_Checklist_Item_Template__c>> templateToItems = new Map<Id, List<cf_Checklist_Item_Template__c>>();

        // Gather template IDs
        Set<Id> templateIds = new Set<Id>();
        for (Task t : tasks) {
            if (t.Checklist_Instance__c == null && t.Checklist_Name__c != null) {
                templateIds.add(t.Checklist_Name__c);
            }
        }

        // Load template items
        if (!templateIds.isEmpty()) {
            for (cf_Checklist_Item_Template__c item : [
                SELECT Id, Name, Checklist_Template__c, Sort_Order__c, Weight__c
                FROM cf_Checklist_Item_Template__c 
                WHERE Checklist_Template__c IN :templateIds
            ]) {
                if (!templateToItems.containsKey(item.Checklist_Template__c)) {
                    templateToItems.put(item.Checklist_Template__c, new List<cf_Checklist_Item_Template__c>());
                }
                templateToItems.get(item.Checklist_Template__c).add(item);
            }
        }

        // Create instances
        for (Task t : tasks) {
            if (t.Checklist_Instance__c == null) {
                cf_Checklist_Instance__c inst = new cf_Checklist_Instance__c(
                    Name = 'Checklist: ' + t.Checklist_Name__r.Name,
                    Checklist_Template__c = t.Checklist_Name__c
                );
                instancesToInsert.add(inst);
                taskToUpdate.put(t.Id, t);
            }
        }

        if (!instancesToInsert.isEmpty()) {
            insert instancesToInsert;

            // Update tasks with new instance
            Integer index = 0;
            for (Task t : taskToUpdate.values()) {
                t.Checklist_Instance__c = instancesToInsert[index].Id;
                index++;
            }
            update taskToUpdate.values();
        }

        // Create assigned items for each instance
        List<cf_Checklist_Assigned_Item__c> assignedItemsToInsert = new List<cf_Checklist_Assigned_Item__c>();
        for (cf_Checklist_Instance__c inst : instancesToInsert) {
            List<cf_Checklist_Item_Template__c> items = templateToItems.get(inst.Checklist_Template__c);
            if (items != null) {
                for (cf_Checklist_Item_Template__c templateItem : items) {
                    assignedItemsToInsert.add(new cf_Checklist_Assigned_Item__c(
                        Checklist_Instance__c = inst.Id,
                        Checklist_Item__c = templateItem.Id,
                        Checklist_Item_Label__c = templateItem.Name,
                        Sort_Order__c = templateItem.Sort_Order__c,
                        Weight__c = templateItem.Weight__c
                    ));
                }
            }
        }
        if (!assignedItemsToInsert.isEmpty()) {
            insert assignedItemsToInsert;
        }
    }
}
