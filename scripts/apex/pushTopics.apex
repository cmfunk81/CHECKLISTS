// PushTopic for Checklist Items
PushTopic checklistItemPush = new PushTopic();
checklistItemPush.Name = 'ChecklistItemUpdates';
checklistItemPush.Query = 'SELECT Id, Name, Is_Completed__c, Checklist__c FROM cf_Checklist_Item__c';
checklistItemPush.ApiVersion = 60.0;
checklistItemPush.NotifyForOperationCreate = true;
checklistItemPush.NotifyForOperationUpdate = true;
checklistItemPush.NotifyForOperationDelete = false;
checklistItemPush.NotifyForOperationUndelete = false;
checklistItemPush.NotifyForFields = 'Referenced';
insert checklistItemPush;

// PushTopic for Task Checklist lookup changes
PushTopic taskChecklistPush = new PushTopic();
taskChecklistPush.Name = 'TaskChecklistUpdates';
taskChecklistPush.Query = 'SELECT Id, Checklist_Name__c FROM Task';
taskChecklistPush.ApiVersion = 60.0;
taskChecklistPush.NotifyForOperationCreate = false;
taskChecklistPush.NotifyForOperationUpdate = true;
taskChecklistPush.NotifyForOperationDelete = false;
taskChecklistPush.NotifyForOperationUndelete = false;
taskChecklistPush.NotifyForFields = 'Referenced';
insert taskChecklistPush;
