import { LightningElement, wire } from 'lwc';
import createInvoiceLwc from '@salesforce/apex/QB_InvoicesManagerLwcHandler.createInvoiceLwc';
import getQBCustomerDetails from '@salesforce/apex/QB_InvoicesManagerLwcHandler.getQBCustomerDetails';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class QB_InvoicesManagerLwc extends LightningElement {

    isLoading = false;
    amount;
    billingEmail;
    selectedCustomerQBId;
    selectedCustomerSFId;

    
    /*matchingInfo = {
        primaryField: { fieldPath: 'Name' },
        additionalFields: [
            { fieldPath: 'QB_Customer_Id__c' }
        ],
    }
    displayInfo = {
        primaryField: 'Name',
        additionalFields: ['QB_Customer_Id__c'],
    };*/

    /*@wire(getQBCustomerDetails, { customerId: '$selectedCustomerSFId' })
    wiredCustomer({ error, data }) {
        if (data) {
            this.selectedCustomerQBId = data.QB_Customer_Id__c;
        } else if (error) {
            this.selectedCustomerQBId = null;
            this.showToast('Error', error.body.message, 'error');
            console.log('Error while retreiving Customer details: ', error);
        }
    }*/

    

    handleInputChange(event) {
        const fieldName = event.target.name;
        const fieldValue = event.target.value;

        if(fieldName === 'Billing Email') {
            this.billingEmail = fieldValue;
        } else if (fieldName === 'Amount') {
            this.amount = fieldValue;
        }
    }

    async handleCustomerSelection(event) {
        this.selectedCustomerSFId = event.detail.recordId;

        if(!this.selectedCustomerSFId) {
            this.selectedCustomerQBId = null;
            return;
        }

        this.isLoading = true;

        try {
            const customer = await getQBCustomerDetails({ customerId: this.selectedCustomerSFId });

            this.selectedCustomerQBId = customer.QB_Customer_Id__c;
        } catch (error) {
            this.showToast('Error Fetching Customer Details', error.body.message, 'error');
            this.selectedCustomerQBId = null;
            console.log('error.body.message: ', error.body.message);
        } finally {
            this.isLoading = false;
        }
    }

    async handleCreateInvoice() {
        this.isLoading = true;
        if(!this.selectedCustomerQBId || !this.amount || !this.billingEmail) {
            console.log('ERROR: ', this.selectedCustomerQBId, this.amount, this.billingEmail);
            this.showToast('ERROR', 'Please fill all the required fields OR Customer Ref No is empty.', 'error');
            this.isLoading = false;
            return;
        }
        try {
            const newInvoiceId = await createInvoiceLwc( {
                customerId: this.selectedCustomerQBId,
                amount: this.amount,
                billEmail: this.billingEmail
            });
            const invoiceQBId = newInvoiceId.QB_Invoice_Id__c;

            this.showToast('SUCCESS', `Invoice created successfully with QB Customer ID: ${invoiceQBId}`, 'success');

            this.resetForm();

        } catch (error) {
            this.showToast('ERROR', error.body.message, 'error');
            console.log('Error while creating Invoice: ', error);
        } finally {
            this.isLoading = false;
        }
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }

    resetForm() {
        this.selectedCustomerSFId = null;
        this.billingEmail = null;
        this.amount = null;
        this.selectedCustomerQBId = null;

        const recordPicker = this.template.querySelector('lightning-record-picker');
        if(recordPicker) {
            recordPicker.clearSelection();
        }
    }

    get isButtonDisabled() {
        return !(this.selectedCustomerSFId && this.billingEmail && this.amount > 0);
    }
}