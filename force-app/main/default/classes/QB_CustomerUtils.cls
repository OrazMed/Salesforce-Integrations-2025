public with sharing class QB_CustomerUtils {

    public static void testCreateCustomer() {

        // QB_CustomerUtils.testCreateCustomer();
        
        QB_CustomerInput customerInput = new QB_CustomerInput();
        customerInput.CompanyName = 'Good';
        customerInput.DisplayName = 'Dog';
        customerInput.FullyQualifiedName = 'Good - Dog';
        customerInput.Suffix = 'Mr';
        customerInput.Title = 'Mr';
        customerInput.MiddleName = '';
        customerInput.Notes = 'Test notes given here.';
        customerInput.FamilyName = 'Dog';
        customerInput.GivenName = 'Dog';

        /** Prepare Primary Email address */
        QB_CustomerInput.PrimaryEmailAddr email = new QB_CustomerInput.PrimaryEmailAddr();
        email.Address = 'letsy@test.this';
        customerInput.PrimaryEmailAddr = email;

        /** Primary Phone */
        QB_CustomerInput.PrimaryPhone phone = new QB_CustomerInput.PrimaryPhone();
        phone.FreeFormNumber = '1234567890';
        customerInput.PrimaryPhone = phone;

        /** Billing Address */
        QB_CustomerInput.BillAddr billAddr = new QB_CustomerInput.BillAddr();
        billAddr.CountrySubDivisionCode = '';
        billAddr.City = 'Liverpool';
        billAddr.PostalCode = 'MJ1 1SPI';
        billAddr.Line1 = '';
        billAddr.Country = 'UK';
        customerInput.BillAddr = billAddr;


        Map<String, String> result = createCustomer(customerInput);
        List<QB_Customer__c> customers = new List<QB_Customer__c>();
        if(result?.size() > 0) {
            QB_Customer__c newCustomer = new QB_Customer__c();
            newCustomer.Name = customerInput.DisplayName;
            newCustomer.Last_Name__c = customerInput.FamilyName;
            newCustomer.Primary_Email__c = customerInput.PrimaryEmailAddr.Address;
            newCustomer.Primary_Phone__c = customerInput.PrimaryPhone.FreeFormNumber;
            newCustomer.Suffix__c = customerInput.Suffix;
            newCustomer.Billing_City__c = customerInput.BillAddr.City;
            newCustomer.Billing_Country__c = customerInput.BillAddr.Country;
            newCustomer.Billing_Post_Code__c = customerInput.BillAddr.PostalCode;
            if(result.get('isSynced') == 'true') {
                newCustomer.Synced_With_Quickbooks__c =  true;
            }
            newCustomer.QB_Customer_Id__c = result.get('customerId');
            //insert newCustomer;
            customers.add(newCustomer);
            List<sObject> insertedCustomers = DmlService.doInsert(customers, false);
            System.debug('insertedCustomers = \n ' + insertedCustomers);
        }
    }
    

    public static Map<String, String> createCustomer(QB_CustomerInput customerInput) {
        Map<String, String> result = new Map<String, String>();
        
        // Quickbook__mdt config = Quickbook__mdt.getInstance(System.Label.QB_Token_Label);
        List<Quickbook__mdt> configList = [SELECT Id, Client_Id__c, auth_url__c, Client_Secret__c, Page_Name__c, Minor_version__c, MasterLabel, DeveloperName, access_token__c, Create_Customer__c, Environment__c, Expires_In__c, Expires_in_time__c, Prod_Base_Url__c, realmId__c, Refresh_Token__c, Sandbox_Base_Url__c, Token_type__c, Token_Url__c 
                                      FROM Quickbook__mdt 
                                      WHERE DeveloperName = 'QBToken'
                                      LIMIT 1];

        if(configList?.size() > 0) {
            Quickbook__mdt config =  configList.get(0);
            Map<String, Object> fieldWithValuesMap = new Map<String, Object>();

            String access_token = config.access_token__c;
            Boolean isValid = OM_QuickBooksTokenUtil.isValid(config);

            if(isValid == false) {// is expired
                // Refresh the Token
                fieldWithValuesMap = OM_QuickBooksTokenUtil.refreshToken(config);
                access_token = (String) fieldWithValuesMap.get('access_token__c');
            }

            String endpoint = config.Prod_Base_Url__c + '/v3/company/' + config.realmId__c + '/customer?minorversion=' + config.Minor_version__c;
            if(config.Environment__c.equals('Sandbox') ) {
                // 	/v3/company/{realmId}/customer?minorversion=
                endpoint = config.Sandbox_Base_Url__c + '/v3/company/' + config.realmId__c + '/customer?minorversion=' + config.Minor_version__c;
            }

            String body = System.JSON.serialize(customerInput);

            HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'POST', body, 'application/json', 'application/json', access_token);

            try {
                HttpResponse res = (new Http() ).send(req);
                
                if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    System.debug('Status code === ' + res.getStatusCode() );
                    System.debug('Status Body === ' + res.getBody() );
                    Map<String, Object> responseMap = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
                    Map<String, Object> customerObj = (Map<String, Object>) responseMap.get('Customer');
                    String customerId = (String) customerObj.get('Id');
                    System.debug('Customer Id === ' + customerId);
                    /**
                     * Update the info in Salesforce
                     * OR return the data from here
                     */
                    result.put('customerId', customerId);
                    result.put('isSynced', 'true');
                } else {
                    System.debug('Status code === ' + res.getStatusCode() );
                    System.debug('ERROR OCCURRED \n ' + res.getBody());
                    ErrorLoggerService.logInfo(res.getBody(), 'QB_CustomerUtils', 'createCustomer', null, 'Apex');
                }
            } catch (System.CalloutException e) {
                System.debug('Callout exception ===> ' + e.getMessage());
                ErrorLoggerService.logError(e, 'QB_CustomerUtils', 'createCustomer', null, 'Apex');

            } catch (System.Exception e) {
                System.debug('Any other (than Callout) Exception ===> ' + e.getMessage());
                ErrorLoggerService.logError(e, 'QB_CustomerUtils', 'createCustomer', null, 'Apex');
            }
            System.debug('fieldWithValuesMap is Zero size???? === ' + fieldWithValuesMap.size() );
            if(fieldWithValuesMap.size() > 0) {
                System.debug('Updating the Custom Metadata with the new Token');
                String fullName = 'Quickbook.' + System.Label.QB_Token_Label; // Object Name + Record Name
                String label = System.Label.QB_Token_Label;

                // Update the Custom Metadata
                CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
            }
        } else {
            // TODO: Enhance this
        }
        return result;
    }
}