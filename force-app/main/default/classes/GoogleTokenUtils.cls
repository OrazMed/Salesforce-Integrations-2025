public with sharing class GoogleTokenUtils {
    
    public PageReference getAuthCode() {
        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.GoogleAPI);

        if(config != null) {
            String orgUrl = config.Environment__c == 'Production' ? 'https://accounts.google.com' : '';

            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;
            //String redirect_uri = 'https://www.google.com/';
            System.debug('redirect_uri === ' + redirect_uri);

            String authorizeUrl = orgUrl + config.auth_url__c + '?client_id=' + config.client_id__c + '&redirect_uri=' + redirect_uri + '&response_type=code' + '&scope=' + config.scope__c + '&access_type=offline&include_granted_scopes=true';

            System.debug('authorizeUrl === ' + authorizeUrl);
            return new PageReference(authorizeUrl);
        } else {
            return null;
        }
    }

    public void getAccessToken() {
        String code = ApexPages.CurrentPage().getParameters().get('code');
        System.debug('code === ' + code);

        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.GoogleAPI);

        if(config != null) {
            String orgUrl = config.Environment__c == 'Production' ? 'https://oauth2.googleapis.com' : '';
            String tokenUrl = orgUrl + config.token_url__c;
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;
            //String redirect_uri = 'https://www.google.com/';

            String reqBody = 'code=' + code + '&grant_type=authorization_code&client_id=' + config.client_id__c + '&client_secret=' + config.client_secret__c + '&redirect_uri=' + redirect_uri;
            System.debug('reqBody === ' + reqBody);

            HttpRequest req = CalloutUtils.prepareRequest(tokenUrl, 'POST', reqBody, '', 'application/x-www-form-urlencoded', '');

            Http http = new Http();
            try {
                HttpResponse res = http.send(req);

                if(res.getStatusCode() == 200) {
                    System.debug('SUCCESSFUL GOOGLE TOKEN \n' + res.getBody());
                    GoogleTokenWrapper wrapper = (GoogleTokenWrapper) JSON.deserialize(res.getBody(), GoogleTokenWrapper.class);

                    String fullName = 'Salesforce_Config.' + System.Label.GoogleAPI;
                    String label = System.Label.GoogleAPI;

                    Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
                    fieldWithValuesMap.put('access_token__c', wrapper.access_token);
                    fieldWithValuesMap.put('expires_in_time__c', System.now().addSeconds(wrapper.expires_in));
                    fieldWithValuesMap.put('refresh_token__c', wrapper.refresh_token);
                    fieldWithValuesMap.put('scope__c', wrapper.scope);

                    System.debug('REFRESH TOKEN ===> ' + wrapper.refresh_token);

                    CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'SUCCESSFULLY AUTHORIZED AND SAVED THE TOKEN!'));
                } else {
                    System.debug('ERROR OCCURRED \n' + res.getBody());
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, res.getBody()));
                }
            } catch (System.CalloutException e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));
            } catch (System.Exception e) {
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));
            }
        }
    }


    public static void getSpreadsheet() {

        //GoogleTokenUtils.getSpreadsheet();

        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.GoogleAPI);

        if(config != null) {
            Boolean isValid = SalesforceTokenUtils.isTokenValid(config);
            Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
            String access_token = config.access_token__c;

            System.debug('isValid === ' + isValid);
            if(!isValid) {
                System.debug('if access token is not valid, then we need to refresh the token using refresh token' + config);
                fieldWithValuesMap = refreshToken(config);
                access_token = (String) fieldWithValuesMap.get('access_token__c');
            }

            String endpoint = 'https://sheets.googleapis.com/v4/spreadsheets';
            HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'GET', '', 'application/json', 'application/x-www-form-urlencoded', '');

            req.setHeader('Authorization', 'Bearer ' + access_token);
            try {
                HttpResponse res = (new Http() ).send(req);
                if(res.getStatusCode() == 200) {
                    System.debug('SUCCESS \n ' + res.getBody());
                } else {
                    System.debug('ERROR \n ' + res.getBody());
                }
            } catch (System.CalloutException e) {
                    // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));

            } catch (System.Exception e) {
                    // ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));

            }

            if(fieldWithValuesMap.size() > 0) {
                String fullName = 'Salesforce_Config.' + System.Label.GoogleAPI;
                String label = System.Label.GoogleAPI;

                CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
            }
        }
    }


    public static Map<String, Object> refreshToken(Salesforce_Config__mdt config) {
        String orgUrl = config.Environment__c == 'Production' ? 'https://accounts.google.com' : '';
        String tokenUrl = orgUrl + config.token_url__c;

        String reqBody = 'grant_type=refresh_token&client_id=' + config.client_id__c + '&client_secret=' + config.client_secret__c + '&refresh_token=' + config.refresh_token__c;
        System.debug('reqBody for refresh token === ' + reqBody);
        HttpRequest httpReq = CalloutUtils.prepareRequest(tokenUrl, 'POST', reqBody, '', 'application/x-www-form-urlencoded', '');

        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
        try {
            HttpResponse res = new HttpResponse();
            if(res.getStatusCode() == 200) {
                GoogleTokenWrapper wrapper = (GoogleTokenWrapper) JSON.deserialize(res.getBody(), GoogleTokenWrapper.class);
                fieldWithValuesMap.put('access_token__c', wrapper.access_token);
                fieldWithValuesMap.put('expires_in_time__c', System.now().addSeconds(wrapper.expires_in));

            } else {
                System.debug('ERROR \n' + res.getBody());
            }
        } catch (System.CalloutException e) {
            System.debug('CALLOUT ERROR::: \n' + e.getStackTraceString() );
        } catch (System.Exception e) {
            System.debug('SYSTEM ERROR::: \n' + e.getStackTraceString() );
        }
        return fieldWithValuesMap;
    }
}