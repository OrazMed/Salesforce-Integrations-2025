public with sharing class AccountUtils {
    
    public static void createAccount(String name, String rating) {
        // AccountUtils.createAccount('OAuth 2.0', 'Hot');
        
        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.SalesforceTokenLabel); // to get Client Id and Secret
        
        if(config != null) {

            Boolean isValid = SalesforceTokenUtils.isTokenValid(config); // Returns false for Token expired
            Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
            String accessToken = config.access_token__c;
            if(!isValid) {
                // Token Expired : config.access_token__c
                // Get the Access Token using Refresh Token
                fieldWithValuesMap = SalesforceTokenUtils.refreshToken(config);
                accessToken = (String)fieldWithValuesMap.get('access_token__c');
            }

            String endpoint = config.instance_url__c + '/services/data/v60.0/sobjects/Account';
            String reqBody = '{'+
                                '    "Name": "'+name+'",'+
                                '    "Rating": "'+rating+'",'+
                                '    "Phone": "0777878787",'+
                                '    "Industry": "Experience",'+
                                '    "Active__c": "Yes"'+
                                '}';

            HttpRequest httpReq = CalloutUtils.prepareRequest(endpoint, 'POST', reqBody, 'application/json', 'application/json', '');
            httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
            try {
                HttpResponse resp = ( new Http() ).send(httpReq);
                if(resp.getStatusCode() == 200 || resp.getStatusCode() == 201) {
                    System.debug('SUCCESS --> \n ' + resp.getBody());
                } else {
                    System.debug('ERROR --> \n ' + resp.getBody());
                }
            } catch (System.CalloutException e) {
                    // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));

            } catch (System.Exception e) {
                    // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));

            }

            /*
                TODO: Update teh Custom Metadata with the new values
            */
            if(fieldWithValuesMap.size() > 0) {
                String fullName = 'Salesforce_Config.' + System.Label.SalesforceTokenLabel;
                String label = System.Label.SalesforceTokenLabel;
                CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
            }
        }
        

    }
}