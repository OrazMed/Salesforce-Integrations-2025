public with sharing class QB_InvoicesUtil {

    public static void testCreateInvoice() {

        // QB_InvoicesUtil.testCreateInvoice();
        
        String customerId = '68';
        Decimal amount = 321.4;
        String billEmail = 'this@test.email';

        InvoiceResponseWrapper response = (InvoiceResponseWrapper) createInvoice(customerId, amount, billEmail);
        System.debug('response = ' + response);
        if(response != null) {
            InvoiceResponseWrapper.Invoice invoice = response.Invoice;
            String invoiceId = invoice.Id;
            System.debug('invoiceId === ' + invoiceId);
            Decimal lineAmount = invoice.Line[0].Amount;

            List<QB_Customer__c> customers = [SELECT Id, QB_Customer_Id__c FROM QB_Customer__c WHERE QB_Customer_Id__c =: customerId LIMIT 1];
            String custId;
            if(customers?.size() > 0) {
                QB_Customer__c customer = customers.get(0);
                System.debug('customer = ' + customer);
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
            System.debug('invoices = ' + invoices.size() );

            List<sObject> updatedRecs = DmlService.doInsert(invoices, false);
            System.debug('updatedRecs = ' + updatedRecs);
        }
    }
    

    @AuraEnabled(cacheable=true)
    public static InvoiceResponseWrapper createInvoice(String customerId, Decimal amount, String billEmail) {
        String metadataRec = System.Label.QB_Token_Label;
        List<Quickbook__mdt> configList = [SELECT Id, Client_Id__c, auth_url__c, Client_Secret__c, Page_Name__c, Minor_version__c, MasterLabel, DeveloperName, access_token__c, Create_Customer__c, Environment__c, Expires_In__c, Expires_in_time__c, Prod_Base_Url__c, realmId__c, Refresh_Token__c, Sandbox_Base_Url__c, Token_type__c, Token_Url__c 
                                       FROM Quickbook__mdt
                                       WHERE DeveloperName =: metadataRec
                                       LIMIT 1];
        
        InvoiceResponseWrapper response = new InvoiceResponseWrapper();
        if(configList?.size() > 0) {
            // Get config
            Quickbook__mdt config = configList.get(0);

            // get access token
            String access_token = config.access_token__c;
            Boolean isValid = OM_QuickBooksTokenUtil.isValid(config);
            Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
            if(isValid == false) {
                fieldWithValuesMap = (Map<String, Object>) OM_QuickBooksTokenUtil.refreshToken(config);
                access_token = (String) fieldWithValuesMap.get('access_token__c');
            }

            // prepare the request
            String reqBaseUrl = config.Prod_Base_Url__c;
            if(config.Environment__c.equals('Sandbox')) {
                reqBaseUrl = config.Sandbox_Base_Url__c;
            }
            String endpoint = reqBaseUrl + '/v3/company/' + config.realmId__c + '/invoice?minorversion=' + config.Minor_version__c;

            String body = '{'+
            '  "Line": ['+
            '    {'+
            '      "DetailType": "SalesItemLineDetail", '+
            '      "Amount": '+amount+', '+
            '      "SalesItemLineDetail": {'+
            '        "ItemRef": {'+
            '          "name": "Services", '+
            '          "value": "1"'+
            '        }'+
            '      }'+
            '    }'+
            '  ], '+
            '  "BillEmail": {'+
            '    "Address": "'+billEmail+'"'+
            '  }, '+
            '  "CustomerRef": {'+
            '    "value": "'+customerId+'"'+
            '  }'+
            '}';

            HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'POST', body, 'application/json', 'application/json', access_token);

            try {
                HttpResponse res = ( new Http() ).send(req);
                if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    
                    /*Map<String, Object> responseMap = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> invoiceObj = (Map<String, Object>) responseMap.get('Invoice');
                    String invoiceId = (String) invoiceObj.get('Id');
                    System.debug('Invoice Id === ' + invoiceId);*/
                    if(response != null) {
                        response = (InvoiceResponseWrapper) System.JSON.deserialize(res.getBody(), InvoiceResponseWrapper.class);
                        InvoiceResponseWrapper.Invoice invoice = response.Invoice;
                        String invoiceId = invoice.Id;
                        Decimal lineAmount = invoice.Line[0].Amount;
                    } else {
                        System.debug('Response is null');
                    }
                } else {
                    // ERROR
                    System.debug('ERROR OCCURRED \n ' + res.getBody());
                }
            } catch (System.CalloutException e) {
                System.debug('Callout exception ===> ' + e.getMessage());
                ErrorLoggerService.logError(e, 'QB_CustomerUtils', 'createCustomer', null, 'Apex');

            } catch (System.Exception e) {
                System.debug('Any other (than Callout) Exception ===> ' + e.getMessage());
                ErrorLoggerService.logError(e, 'QB_CustomerUtils', 'createCustomer', null, 'Apex');
            }
            if(fieldWithValuesMap.size() > 0) {
                System.debug('Updating the Custom Metadata with the new Token');
                String fullName = 'Quickbook.' + System.Label.QB_Token_Label; // Object Name + Record Name
                String label = System.Label.QB_Token_Label;

                // Update the Custom Metadata
                CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
            }
        } else {
            // Requires enhancement
        }
        return response;
    }
}