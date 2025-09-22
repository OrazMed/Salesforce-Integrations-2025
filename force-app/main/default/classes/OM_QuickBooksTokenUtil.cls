public with sharing class OM_QuickBooksTokenUtil {
    
    /** Prepare the Auth URL */
    public static PageReference authorize() {
        /** Get the config from the Custom Metadata */
        Quickbook__mdt config = Quickbook__mdt.getInstance(System.Label.QB_Token_Label);
        System.debug('config === ' + config);

        if(config != null) {
            // Prepare the Auth Url

            /**
             * https://appcenter.intuit.com/connect/oauth2?
                client_id=Q3ylJatCvnkYqVKLmkxxxxxxxxxxxxxxxkYB36b5mws7HkKUEv9aI
                &response_type=code
                &scope=com.intuit.quickbooks.accounting&
                redirect_uri=https://www.mydemoapp.com/oauth-redirect&
                state=security_token%3D138r5719ru3e1%26url%3Dhttps://www.mydemoapp.com/oauth-redirect
             */
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.Page_Name__c;
            System.debug('redirect_uri === ' + redirect_uri);

            String authorize_url = config.auth_url__c + '?client_id=' + config.Client_Id__c + '&redirect_uri=' + redirect_uri + '&response_type=code' + '&scope=openid email profile address phone com.intuit.quickbooks.accounting com.intuit.quickbooks.payment' + '&grant_type=authorization_code' + '&state=' + UserInfo.getOrganizationId();
            System.debug('authorize_url === ' + authorize_url);

            return new PageReference(authorize_url);
        } else {
            // Show the Error
            System.debug('ERROR OCCURRED \n' + 'Config not found!');
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Config not found!' ));

            return null;
        }
    }

    
    /** Get the Access Token and Store into Metadata */
    public void getAccessToken() {
        /**
         * https://orgfarm-8b60f05db0-dev-ed--c.develop.vf.force.com/apex/OM_QuickbooksTokenPage?
         * code=XAB117569090515Wpx8FMF0vaOZU4DQ2QDhYVJYYaExiKmTNju
         * &state=00DgK0000086dZxUAI
         * &realmId=9341455276189302
         */
        Quickbook__mdt config = Quickbook__mdt.getInstance(System.Label.QB_Token_Label);
        System.debug('config === ' + config);

        if(config != null) {
            String code = ApexPages.CurrentPage().getParameters().get('code');
            String realmId = ApexPages.CurrentPage().getParameters().get('realmId');
            System.debug('code === ' + code + '; realmId === ' + realmId);

            String endpoint = config.Token_Url__c;
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.Page_Name__c;

            /**
             * grant_type=authorization_code&
             * code=L3114709614564VSU8JSEiPkXx1xhV8D9mv4xbv6sZJycibMUI&
             * redirect_uri=https://www.mydemoapp.com/oauth-redirect
             */
            String body = 'grant_type=authorization_code' + '&code=' + code + '&redirect_uri=' + redirect_uri + '&client_id=' + config.Client_Id__c + '&client_secret=' + config.Client_Secret__c;
            System.debug('REQUEST BODY === ' + body);

            HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'POST', body, 'application/json', 'application/x-www-form-urlencoded', '');
        

            try {
                HttpResponse res = ( new Http() ).send(req);
                if(res.getStatusCode() == 200 || res.getStatusCode() == 201 ) {
                    // Prepare the Response
                    /**
                     * {
                            "token_type": "bearer",
                            "expires_in": 3600,
                            "refresh_token":"Q311488394272qbajGfLBwGmVsbF6VoNpUKaIO5oL49aXLVJUB",
                            "x_refresh_token_expires_in":15551893,
                            "access_token":"eJlbmMiOiJBMTI4Q0JDLUhTMjU2IiwiYWxnIjoiZGGlyIn0..KM1_Fezsm6BUSaqqfTedaA.
                            dBUCZWiVmjH8CdpXeh_pmaM3kJlJkLEqJlfmavwGQDThcf94fbj9nBZkjEPLvBcQznJnEmltCIvsTGX0ue_w45h7_
                            yn1zBoOb-1QIYVE0E5TI9z4tMUgQNeUkD1w-X8ECVraeOEecKaqSW32Oae0yfKhDFbwQZnptbPzIDaqiduiM_q
                            EFcbAzT-7-znVd09lE3BTpdMF9MYqWdI5wPqbP8okMI0l8aa-UVFDH9wtli80zhHb7GgI1eudqRQc0sS9zWWb
                            I-eRcIhjcIndNUowSFCrVcYG6_kIj3uRUmIV-KjJUeXdSV9kcTAWL9UGYoMnTPQemStBd2thevPUuvKrPdz3ED
                            ft-RVRLQYUJSJ1oA2Q213Uv4kFQJgNinYuG9co_qAE6A2YzVn6A8jCap6qGR6vWHFoLjM2TutVd6eOeYoL2bb7jl
                            QALEpYGj4E1h3y2xZITWvnmI0CEL_dYQX6B3QTO36TDaVl9WnTaCCgAcP6bt70rFlPYbCjOxLoI6qFm5pUwGLLp
                            67JZ36grc58k7NIyKJ8dLJUL_Q9r1WoUvw.ZS298t_u7dSlkfajxLfO9Q"
                            }
                        */
                    String resBody = res.getBody();
                    Map<String, Object> fieldWithValuesMap = prepareMetadata(resBody, realmId);

                    // Prepare the Map for Custom Metadata
                    String fullName = 'Quickbook.' + System.Label.QB_Token_Label; // Object Name + Record Name
                    String label = System.Label.QB_Token_Label;

                    // Deploy / Update the Custom Metadata
                    CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'SUCCESSFULLY AUTHORIZED AND SAVED THE TOKEN!'));
                } else {
                    System.debug('ERROR OCCURRED \n ' + res.getBody());
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, res.getBody() ));
                }
            } catch (System.CalloutException e) {
                System.debug('Callout exception ===> ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));
                ErrorLoggerService.logError(e, 'OM_QuickBooksTokenUtil', 'getAccessToken', null, 'Apex');

            } catch (System.Exception e) {
                System.debug('Exception ===> ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));
                ErrorLoggerService.logError(e, 'OM_QuickBooksTokenUtil', 'getAccessToken', null, 'Apex');
            }
        } else {
            // Show the Error
            System.debug('ERROR OCCURRED \n' + 'Config not found!');
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Config not found!' ));
        }
    }


    public static Boolean isValid(Quickbook__mdt config) {
        Boolean isValid = true;
        if(config.Expires_in_time__c <= System.Now()) {
            isValid = false;
        }
        return isValid;
    }


    public static Map<String, Object> refreshToken(Quickbook__mdt config) {
        // Prepare the Request
        /**
         * grant_type=refresh_token&
         * refresh_token=Q311488394272qbajGfLBwGmVsbF6VoNpUKaIO5oL49aXLVJUB
         */
        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();

        String body = 'grant_type=refresh_token' + '&refresh_token=' + config.Refresh_Token__c + '&client_id=' + config.Client_Id__c + '&client_secret=' + config.Client_Secret__c;
        
        HttpRequest req = CalloutUtils.prepareRequest(config.Token_Url__c, 'POST', body, 'application/json', 'application/x-www-form-urlencoded', '');

        try {
            HttpResponse res = (new Http() ).send(req);
            if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {

                String resBody = res.getBody();
                fieldWithValuesMap = prepareMetadata(resBody, '');
            } else {
                // ERROR
                System.debug('ERROR OCCURRED \n ' + res.getBody());
            }
        } catch (System.CalloutException e) {
            System.debug('Callout exception ===> ' + e.getMessage());
            ErrorLoggerService.logError(e, 'OM_QuickBooksTokenUtil', 'refreshToken', null, 'Apex');
        } catch (System.Exception e) {
            System.debug('Exception ===> ' + e.getMessage());
            ErrorLoggerService.logError(e, 'OM_QuickBooksTokenUtil', 'refreshToken', null, 'Apex');
        }

        return fieldWithValuesMap;
    }


    public static Map<String, Object> prepareMetadata(String resBody, String realmId) {

        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(resBody);
        String access_token = (String) responseMap.get('access_token');
        String refresh_token = (String) responseMap.get('refresh_token');
        Integer expires_in = (Integer) responseMap.get('expires_in');
        String token_type = (String) responseMap.get('token_type');

        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
        fieldWithValuesMap.put('access_token__c', access_token);
        fieldWithValuesMap.put('Expires_In__c', expires_in);
        fieldWithValuesMap.put('Expires_in_time__c', System.now().addSeconds(expires_in));
        fieldWithValuesMap.put('Refresh_Token__c', refresh_token);
        if(!String.isBlank(realmId)) {
            fieldWithValuesMap.put('realmId__c', realmId);
        }
        fieldWithValuesMap.put('Token_type__c', token_type);
        
        return fieldWithValuesMap;
    }
}