public with sharing class QB_InvoicesManagerLwcHandler {

    @AuraEnabled(cacheable=false)
    public static sObject createInvoiceLwc(String customerId, Decimal amount, String billEmail) {

        // QB_InvoicesManagerLwcHandler.createInvoiceLwc('a08gK000008o7JUQAY', 120, 'howdy@howdy.us');

        InvoiceResponseWrapper response = (InvoiceResponseWrapper) QB_InvoicesUtil.createInvoice(customerId, amount, billEmail);
        List<sObject> updatedRecs = new List<sObject>();
        if(response != null) {
            InvoiceResponseWrapper.Invoice invoice = (InvoiceResponseWrapper.Invoice) response.Invoice;
            String invoiceId = invoice.Id;
            System.debug('invoiceId === ' + invoiceId);
            Decimal lineAmount = invoice.Line[0].Amount;

            List<QB_Customer__c> customers = [SELECT Id, QB_Customer_Id__c FROM QB_Customer__c WHERE QB_Customer_Id__c =: customerId LIMIT 1];
            String custId;
            if(customers?.size() > 0) {
                QB_Customer__c customer = customers.get(0);
                custId = customer.Id;
            }

            List<QB_Invoice__c> invoices = new List<QB_Invoice__c>();

            QB_Invoice__c inv = new QB_Invoice__c();
            inv.QB_Invoice_Id__c = invoiceId;
            inv.QB_Customer__c = custId;
            inv.Amount__c = invoice.Line.get(0).Amount;
            inv.Billing_Email__c = billEmail;
            inv.Due_Date__c = Date.valueOf(invoice.DueDate);
            invoices.add(inv);

            updatedRecs = DmlService.doInsert(invoices, false);
            return updatedRecs.get(0);
            //insert invoices;
        } else {
            System.debug('Invoice response is null');
        }
        //return 'This is RESPONSE from the server';
        return null;
    }


    @AuraEnabled(cacheable=true)
    public static QB_Customer__c getQBCustomerDetails(String customerId) {
        try {
            List<QB_Customer__c> customers = [SELECT Id, Name, QB_Customer_Id__c
                    FROM QB_Customer__c
                    WHERE Id =: customerId
                    LIMIT 1];
            if(customers?.size() > 0) {
                return customers.get(0);
            }
            return null;
        } catch (Exception e) {
            System.debug('Error: ' + e.getMessage());
            System.debug('Stack trace: ' + e.getStackTraceString());
            throw new AuraHandledException('Could not find customer details. Error: ' + e.getMessage() );
        }
    }
}