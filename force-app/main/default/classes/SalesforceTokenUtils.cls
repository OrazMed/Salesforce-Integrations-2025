public with sharing class SalesforceTokenUtils {
    
    public PageReference getAuthCode() {
        /*
           TODO: Get the Custom Metadata Record
        */
        // Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance('SalesforceToken	'); // This is hardcoded name for name of the config. We should use Custom Label for the name to make it dynamic
        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.SalesforceTokenLabel); // Dynamic

        if(config != null) {

            List<String> codeChallengeVerifier = PKCEAuthHelper.getDetails();
            // codeChallengeVerifier.get(0); code_verifier
            // codeChallengeVerifier.get(1); code_challenge

            String orgUrl = config.Environment__c == 'Production' ? 'https://login.salesforce.com' : 'https://test.salesforce.com';
            System.debug('orgUrlL === ' + orgUrl);
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;
            System.debug('redirect_uri === ' + redirect_uri);
            String authorizeUrl = orgUrl + config.auth_url__c + '?client_id=' + config.client_id__c + '&redirect_uri=' + redirect_uri + '&response_type=code&code_challenge=' + codeChallengeVerifier.get(1); // EncodingUtil.urlDecode(redirect_uri, 'UTF-8')
            System.debug('Authorize URL === ' + authorizeUrl);

            // Before redirecting:
            //      Insert the Custom Setting / Custom Object
            PKCE_Helper__c helper = new PKCE_Helper__c();
            helper.Active__c = true;
            helper.User__c = UserInfo.getUserId();
            helper.code_challenge__c = codeChallengeVerifier.get(1);
            helper.code_verifier__c = codeChallengeVerifier.get(0);
            insert helper;
            System.debug('HELPER record created === ' + helper);

            return new PageReference(authorizeUrl);
        } else {
            return null;
        }
    }


    public void getAccessToken() {
        String code = ApexPages.CurrentPage().getParameters().get('code');
        System.debug('code === ' + code);

        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.SalesforceTokenLabel);
        
        if(config != null) {

            // Get the Custom Setting / Custom Object
            PKCE_Helper__c helper = [SELECT Id, Name, code_verifier__c FROM PKCE_Helper__c WHERE User__c =: UserInfo.getUserId() AND Active__c = True LIMIT 1];
            System.debug('HELPER record fetched === ' + helper);

            String orgUrl = config.Environment__c == 'Production' ? 'https://login.salesforce.com' : 'https://test.salesforce.com';
            String tokenUrl = orgUrl + config.token_url__c;
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;

            String reqBody = 'code=' + code + '&grant_type=authorization_code&client_id=' + config.client_id__c + '&client_secret=' + config.client_secret__c + '&redirect_uri=' + redirect_uri + '&code_verifier=' + helper.code_verifier__c;
            System.debug('reqBody === ' + reqBody);

            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(tokenUrl);
            httpReq.setMethod('POST');
            httpReq.setBody(reqBody);
            httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            httpReq.setHeader('Accept', 'application/json');

            Http http = new Http();
            try{
                HttpResponse httpResp = http.send(httpReq);
                if(httpResp.getStatusCode() == 200) {
                    // Success
                    System.debug('SUCCESS \n ' + httpResp.getBody());
                    SalesforceTokenWrapper wrapper = SalesforceTokenWrapper.parse(httpResp.getBody());
                    /*
                        TODO: Deploy the Custom Metadata
                            ! How to deploy?
                        Metadata is a Namespace
                            CustomMetadata - Class
                            CustomMetaValue - Class
                            Operations - Class
                            DeployCallback - Interface
                    */

                        // For existing Custom metadata record:
                    String fullName = 'Salesforce_Config.' + System.Label.SalesforceTokenLabel;
                    String label = System.Label.SalesforceTokenLabel;
                
                        // For new Custom metadata record:
                    /*
                    String fullName = 'Salesforce_Config.' + 'Salesforce_Token';
                    String label = 'Salesforce Token Detail';
                    */
                    Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
                    fieldWithValuesMap.put('access_token__c', wrapper.access_token);
                    //fieldWithValuesMap.put('expires_in__c');
                    fieldWithValuesMap.put('expires_in_time__c', System.now().addHours(2));
                    fieldWithValuesMap.put('instance_url__c', wrapper.instance_url);
                    fieldWithValuesMap.put('refresh_token__c', wrapper.refresh_token);
                    fieldWithValuesMap.put('scope__c', wrapper.scope);

                    CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);

                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'Successfully Authorized and Saved the Token'));
                    helper.Active__c = false;
                    update helper;
                }else {
                    // Error
                    System.debug('ERROR \n ' + httpResp.getBody());
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, httpResp.getBody() ));
                }
            } catch (System.CalloutException e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));

            } catch (System.Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));

            }
        }
        
    }


    public static Boolean isTokenValid(Salesforce_Config__mdt config) {
        Boolean isValid = true;
        if(config.expires_in_time__c < System.now()){
            isValid = false;
        }
        return isValid;
    }


    public static Map<String, Object> refreshToken(Salesforce_Config__mdt config) {
        String orgUrl = config.Environment__c == 'Production' ? 'https://login.salesforce.com' : 'https://test.salesforce.com';
        String tokenUrl = orgUrl + config.token_url__c;

        String reqBody = 'grant_type=refresh_token&client_id=' + config.client_id__c + '&client_secret=' + config.client_secret__c + '&refresh_token=' + config.refresh_token__c;
        System.debug('reqBody for refresh token === ' + reqBody);
        HttpRequest httpReq = CalloutUtils.prepareRequest(tokenUrl, 'POST', reqBody, 'application/json', 'application/json', '');

        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
        try {
            HttpResponse httpResp = ( new HTTP() ).send(httpReq);
                if(httpResp.getStatusCode() == 200) {
                    
                    SalesforceTokenWrapper wrapper = SalesforceTokenWrapper.parse(httpResp.getBody());
                    fieldWithValuesMap.put('access_token__c', wrapper.access_token);
                    fieldWithValuesMap.put('expires_in_time__c', System.now().addHours(2));

                    //CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
                } else {
                    System.debug('ERROR \n ' + httpResp.getBody());
                }
        } catch (System.CalloutException e) {
            System.debug('CALLOUT ERROR::: \n' + e.getStackTraceString() );
        } catch (System.Exception e) {
            System.debug('SYSTEM ERROR::: \n' + e.getStackTraceString() );
        }
        return fieldWithValuesMap;
    }
}