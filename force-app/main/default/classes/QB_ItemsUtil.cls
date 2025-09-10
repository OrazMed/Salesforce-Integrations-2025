public with sharing class QB_ItemsUtil {

    public static void testCreateItem() {
        
        List<Product2> products = [SELECT Id, Name, QB_External_Id__c, Sync_With_QuickBooks__c, Synced_With_QuickBooks__c
                                   FROM Product2
                                   WHERE QB_External_Id__c = null];
        List<Product2> prodsToUpdate = new List<Product2>();
        if(products.size() > 0) {
            for(Product2 prod : products) {
                prod = createItem(prod);
                prodsToUpdate.add(prod);
            }
        }
        if(prodsToUpdate.size() > 0) {
            System.debug('prodsToUpdate size = ' + prodsToUpdate.size());
            List<sObject> insertedProds = DmlService.doUpdate(prodsToUpdate, false);
        }

        /*QB_ItemInput itemInput = new QB_ItemInput();
        itemInput.Name = 'BookNow Software';
        itemInput.TrackQtyOnHand = true;
        itemInput.QtyOnHand = 101;
        itemInput.InvStartDate = '2025-01-01';
        itemInput.Type = 'Service';

        QB_ItemInput.IncomeAccountRef incomeAccountRef = new QB_ItemInput.IncomeAccountRef();
        incomeAccountRef.name = 'Sales of Product Income';
        incomeAccountRef.value = '79';
        itemInput.IncomeAccountRef = incomeAccountRef;

        QB_ItemInput.AssetAccountRef assetAccountRef = new QB_ItemInput.AssetAccountRef();
        assetAccountRef.name = 'Inventory Asset';
        assetAccountRef.value = '81';
        itemInput.AssetAccountRef = assetAccountRef;
        
        QB_ItemInput.ExpenseAccountRef expenseAccountRef = new QB_ItemInput.ExpenseAccountRef();
        expenseAccountRef.name = 'Cost of Goods Sold';
        expenseAccountRef.value = '80';
        itemInput.ExpenseAccountRef = expenseAccountRef;*/

        //createItem(itemInput);

        // QB_ItemsUtil.testCreateItem();
        /**
         * Callout
         * Callout
         * Dml - works
         * 
         * Callout
         * DML
         * Callout - ** System.CalloutException: You have uncommitted work pending. Please commit or rollback before calling out
         */
        /*for(Product2 p : products) { // Not a best practice but will do test
            createItem(p);
        }
        List<sObject> insertedProds = DmlService.doUpdate(products, false);*/
    }

    public static Product2 createItem(Product2 productRecord) {
        
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
            System.debug('is valid? = ' + isValid);

            if(isValid == false) {// is expired
                // Refresh the Token
                fieldWithValuesMap = OM_QuickBooksTokenUtil.refreshToken(config);
                access_token = (String) fieldWithValuesMap.get('access_token__c');
                System.debug('access token = ' + access_token);// L60cUzc5vjQ
            }

            String endpoint = config.Prod_Base_Url__c + '/v3/company/' + config.realmId__c + '/item?minorversion=' + 74;// config.Minor_version__c;
            if(config.Environment__c.equals('Sandbox') ) {
                // 	/v3/company/{realmId}/customer?minorversion=
                endpoint = config.Sandbox_Base_Url__c + '/v3/company/' + config.realmId__c + '/item?minorversion=' + config.Minor_version__c;
            }

            String prodName = productRecord.Name.replaceAll(':', ' ');

            String body = '{'+
            '  "TrackQtyOnHand": true, '+
            '  "Name": "'+prodName+'", '+
            '  "QtyOnHand": 10, '+
            '  "IncomeAccountRef": {'+
            '    "name": "'+System.Label.IncomeAccountRefName+'", '+
            '    "value": "'+System.Label.IncomeAccountRefValue+'"'+
            '  }, '+
            '  "AssetAccountRef": {'+
            '    "name": "'+System.Label.AssetAccountRefName+'", '+
            '    "value": "'+System.Label.AssetAccountRefValue+'"'+
            '  }, '+
            '  "ExpenseAccountRef": {'+
            '    "name": "'+System.Label.ExpenseAccountRefName+'", '+
            '    "value": "'+System.Label.ExpenseAccountRefValue+'"'+
            '  }, '+
            '  "InvStartDate": "2025-01-01", '+
            '  "Type": "Inventory", '+
            '  "SubItem": true, '+
            '  "ParentRef": {'+
            '    "name": "Pants", '+
            '    "value": "46"'+
            '  } '+
            '}';

            System.debug('body === ' + System.JSON.serializePretty(body));

            HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'POST', body, 'application/json', 'application/json', access_token);

            try {
                HttpResponse res = (new Http() ).send(req);
                
                if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    Map<String, Object> responseMap = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
                    Object item = (Object) responseMap.get('Item');
                    Map<String, Object> itemMap = (Map<String, Object>) item;
                    System.debug('Item Map ===> \n   ' + System.JSON.serializePretty(itemMap));
                    String prodId = (String) itemMap.get('Id');
                    System.debug('Customer Id === ' + prodId);
                    /**
                     * Update the info in Salesforce
                     * OR return the data from here
                     */
                    productRecord.QB_External_Id__c = prodId;
                    productRecord.Synced_With_QuickBooks__c = true;

                    //upsert productRecord QB_External_Id__c;
                } else {
                    System.debug('Status code === ' + res.getStatusCode() );
                    System.debug('ERROR OCCURRED \n ' + res.getBody());
                    //ErrorLoggerService.logInfo(res.getBody(), 'QB_ItemsUtil', 'createItem', null, 'Apex');
                }
            } catch (System.CalloutException e) {
                System.debug('Callout exception ===> ' + e.getMessage());
                //ErrorLoggerService.logError(e, 'QB_ItemsUtil', 'createItem', null, 'Apex');

            } catch (System.Exception e) {
                System.debug('Any other (than Callout) Exception ===> ' + e.getMessage());
                //ErrorLoggerService.logError(e, 'QB_ItemsUtil', 'createItem', null, 'Apex');
            }
            /**
             * Update Custom metadata type now,
             * because Dml operations are allowed after the Callout
             */
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
        return productRecord;
    }
}