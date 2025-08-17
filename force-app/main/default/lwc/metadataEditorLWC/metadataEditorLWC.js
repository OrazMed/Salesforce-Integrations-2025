import { LightningElement, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getMetadataTypes from '@salesforce/apex/CreateUpdateMetadataUtils.getMetadataTypes';
import getMetadataRecordsAndFields from '@salesforce/apex/CreateUpdateMetadataUtils.getMetadataRecordsAndFields';
import deployMetadataRecords from '@salesforce/apex/CreateUpdateMetadataUtils.deployMetadataRecords';

export default class MetadataEditorLWC extends LightningElement {
    selectedMetadataType = '';
    metadataTypeOptions = [];
    data = [];
    columns = [];
    draftValues = [];
    isLoading = false;

    @wire(getMetadataTypes)
    wiredMetadataTypes({ error, data}) {
        if(data) {
            this.metadataTypeOptions = data;
        } else if(error) {
            this.showToast('Error', 'Failed to load metadata types.', 'error');
            console.error('Error fetching metadata types: ', error);
        }
    }


    async handleMetadataTypeChange(event) {
        this.selectedMetadataType = event.target.value;
        this.data = undefined;
        if(this.selectedMetadataType) {
            this.isLoading = true;
            try {
                const result = await getMetadataRecordsAndFields({ metadataType: this.selectedMetadataType });

                if(result) {
                    this.data = result.records;
                    this.columns = result.columns;
                }
            } catch (error) {
                this.showToast('Error', 'Failed to fetch records.', 'error');
                console.error('Error fetching records: ', this.extractError(error));
            } finally {
                this.isLoading = false;
            }
        }
    }


    handleSave(event) {
        const updatedDrafts = event.detail.draftValues;
        const updatedData = this.data.map(row => {
            const draft = updatedDrafts.find(d => d.DeveloperName === row.DeveloperName);
            return draft ? {...row, ...draft} : row;
        });

        this.data = updatedData;
        this.draftValues = [];
        this.showToast('Staged', 'Changes are staged. Click "Create/Update Metadata records" to deploy.', 'info');
    }

    handleAddNewRow() {
        const newRow = {
            Label: 'New Record',
            DeveloperName: `temp_record_${Date.now()}`,
            Flag_Emoji__c: '🏳️',
            ISO_alpha_2__c: '',
            ISO_alpha_3__c: '',
            Currency_Code__c: '',
            Currency_Symbol__c: '',
            Latitude__c: 0,
            Longitude__c: 0
        };

        this.data = [newRow, ...this.data];
    }

    async handleDeploy() {
        this.isLoading = true;

        console.log('The data: ', JSON.stringify(this.data, null, 2));
        /*const recordsToDeploy = this.data.map(row => {
            const newRow = { ...row };
            if(newRow.DeveloperName.startsWith('temp_record_')) {
                newRow.DeveloperName = newRow.Label.replace(/[^a-zA-Z0-9]/g, '_');
            }
            return newRow;
        });*/

        try {
            const jobId = await deployMetadataRecords({
                metadataType: this.selectedMetadataType,
                recordsJson: JSON.stringify(this.data)
            });
            this.showToast('Deployment Started', `Deployment enqueuedwith job ID: ${jobId}. Refresh the page after a moment to see changes.`, 'success');
        } catch (error) {
            const errorMessage = this.extractError(error);
            this.showToast('Deployment Error', errorMessage, 'error');
            console.error('Deployment Error', error);
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

    extractError(error) {
        if(error && error.body) {
            if(Array.isArray(error.body)) {
                return error.body.map(e => e.message).join(', ');
            } else if(typeof error.body.message === 'string') {
                return error.body.message;
            }
        }
        return error.message || 'An unknown error occurred.';
    }
}