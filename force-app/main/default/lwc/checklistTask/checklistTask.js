import { LightningElement, api, track, wire } from 'lwc';
import getChecklistItems from '@salesforce/apex/ChecklistController.getChecklistItems';
import updateChecklistItem from '@salesforce/apex/ChecklistController.updateChecklistItem';
import { refreshApex } from '@salesforce/apex';

export default class ChecklistTask extends LightningElement {
    @api recordId;
    @track checklistItems = [];
    @track checklistInstanceName = '';
    wiredResult;

    get progress() {
        if (!this.checklistItems.length) return 0;
        const completed = this.checklistItems.filter(i => i.Is_Completed__c).length;
        return Math.round((completed / this.checklistItems.length) * 100);
    }

    get progressStyle() {
        return `width: ${this.progress}%;`;
    }

    @wire(getChecklistItems, { taskId: '$recordId' })
    wiredItems(result) {
        this.wiredResult = result;
        if (result.data) {
            this.checklistItems = result.data.map(item => ({
                ...item,
                CompletedByName: item.Completed_By__r ? item.Completed_By__r.Name : '',
                CompletedDateFormatted: item.Completed_Date_Time__c
                    ? new Date(item.Completed_Date_Time__c).toLocaleString()
                    : ''
            }));
            if (result.data.length > 0) {
                this.checklistInstanceName = result.data[0].Checklist_Instance__r.Name;
            }
        }
    }

    async handleCheckboxChange(event) {
        const itemId = event.target.dataset.id;
        const isChecked = event.target.checked;
        await updateChecklistItem({ itemId: itemId, isCompleted: isChecked, taskId: this.recordId });        
        await refreshApex(this.wiredResult);

        // Refresh page if progress hits 100
        if (this.progress === 100) {
            setTimeout(() => {
                window.location.reload();
            }, 500);
        }
    }
}