import { LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCalendarEvent from '@salesforce/apex/EventCreatorController.createCalendarEvent';

export default class OM_CalendarEventManager extends LightningElement {
    isLoading = false;
    subject;
    startDateTime;
    endDateTime;

    handleSubjectChange( event) {
        this.subject = event.target.value;
    }

    handleDateChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        if(fieldName === 'startDate') {
            this.startDateTime = fieldValue;
        } else if(fieldName === 'endDate') {
            this.endDateTime = fieldValue;
        }
    }

    handleCreateEventButton() {
        if( this.validateInput() ) {
            this.isLoading = true;

            createCalendarEvent({
                subject: this.subject,
                startDateTime: this.startDateTime,
                endDateTime: this.endDateTime
            })
            .then(result => {
                this.showToast('Success', result, 'success');
                this.resetForm();
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
        }
    }

    validateInput() {
        if(!this.subject || !this.startDateTime || !this.endDateTime) {
            this.showToast('Validation Error', 'Please make sure to fill all the fields!', 'error');
            return false;
        }

        const start = new Date(this.startDateTime);
        const end = new Date(this.endDateTime);

        if(start >= end) {
            this.showToast('Validation Error', 'End Date and Time must be after the Start Date and Time.', 'error');
            return false;
        }

        return true;
    }

    resetForm() {
        this.subject = '';
        this.startDateTime = null;
        this.endDateTime = null;
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        this.dispatchEvent(event);
    }
}