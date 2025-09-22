public with sharing class OM_GoogleApiTokenUtil {

    public static PageReference authorize() {
        String metadataRec = System.Label.Google_calendar;
        Google_API__mdt config = Google_API__mdt.getInstance(metadataRec);
        
        if(config != null) {
            //String baseUrl = config.base_url__c;
            String baseUrl = 'https://accounts.google.com';
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;
            String authUrl = baseUrl +config.auth_url__c + '?scope=' + config.scope__c + '&access_type=offline&' + 'include_granted_scopes=true&'+ 'response_type=code&' + 'redirect_uri=' + redirect_uri + '&client_id=' + config.client_id__c + '&prompt=consent';

            return new PageReference(authUrl);
        } else {
            // Show the Error
            System.debug('ERROR OCCURRED \n' + 'Config not found!');
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Config not found!' ));

            return null;
        }
    }


    public void getAccessToken() {
        String code = ApexPages.CurrentPage().getParameters().get('code');
        
        String metadataRec = System.Label.Google_calendar;
        Google_API__mdt config = Google_API__mdt.getInstance(metadataRec);
        if( config !=null ) {
            
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;
            String endpoint = config.base_url__c + config.token_url__c;
            String body = 'client_id=' + config.client_id__c + '&client_secret=' + config.client_secret__c + '&code=' + code + '&redirect_uri=' + redirect_uri + '&grant_type=authorization_code';
            
            HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'POST', body, 'application/json', 'application/x-www-form-urlencoded', '');

            try {
                HttpResponse res = ( new Http() ).send(req);
                if( res.getStatusCode() == 200 || res.getStatusCode() == 201 ) {
                    String resBody = res.getBody();
                    Map<String, Object> fieldWithValuesMap = prepareMetadata( resBody );

                    String fullName = 'Google_API.' + System.Label.Google_calendar;
                    String label = System.Label.Google_calendar;

                    CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.CONFIRM, 'SUCCESSFULLY AUTHORIZED AND SAVED THE TOKEN!'));
                } else {
                    System.debug('Response Code = ' + res.getStatusCode());
                    System.debug('ERROR OCCURRED \n ' + res.getBody());
                    ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, res.getBody() ));
                }
            } catch (System.CalloutException e) {
                System.debug('Callout exception ===> ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));
                ErrorLoggerService.logError(e, 'OM_GoogleApiTokenUtil', 'authorize', null, 'Apex');

            } catch (System.Exception e) {
                System.debug('Exception ===> ' + e.getMessage());
                ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage() ));
                ErrorLoggerService.logError(e, 'OM_GoogleApiTokenUtil', 'authorize', null, 'Apex');
            }
        } else {
            // Show the Error
            System.debug('ERROR OCCURRED \n' + 'Config not found!');
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.WARNING, 'Config not found!' ));
        }
    }


    public static Map<String, Object> prepareMetadata(String responseBody) {
        Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);

        String access_token = (String) responseMap.get('access_token');
        String refresh_token = (String) responseMap.get('refresh_token');
        Integer expires_in = (Integer) responseMap.get('expires_in');

        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
        fieldWithValuesMap.put('access_token__c', access_token);
        fieldWithValuesMap.put('expires_in__c', expires_in);
        fieldWithValuesMap.put('expires_in_time__c', System.now().addSeconds(expires_in));
        fieldWithValuesMap.put('refresh_token__c', refresh_token);
        
        return fieldWithValuesMap;
    }


    public static Boolean isValid(Google_API__mdt config) {
        Boolean isValid = true;
        if(config.expires_in_time__c <= System.Now()) {
            isValid = false;
        }
        return isValid;
    }


    public static Map<String, Object> refreshToken(Google_API__mdt config) {
        
        Map<String, Object> fieldWithValuesMap = new Map<String, Object>();

        String endpoint = config.base_url__c + config.token_url__c;
        String body = 'client_id=' + config.client_id__c + '&client_secret=' + config.client_secret__c + '&refresh_token=' + config.refresh_token__c + '&grant_type=refresh_token';

        HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'POST', body, 'application/json', 'application/x-www-form-urlencoded', '');

        try {
            HttpResponse res = (new Http() ).send(req);
            if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {

                String resBody = res.getBody();
                fieldWithValuesMap = prepareMetadata(resBody);
            } else {
                // ERROR
                System.debug('ERROR OCCURRED \n ' + res.getBody());
            }
        } catch (System.CalloutException e) {
            System.debug('Callout exception ===> ' + e.getMessage());
            ErrorLoggerService.logError(e, 'OM_GoogleApiTokenUtil', 'refreshToken', null, 'Apex');
        } catch (System.Exception e) {
            System.debug('Exception ===> ' + e.getMessage());
            ErrorLoggerService.logError(e, 'OM_GoogleApiTokenUtil', 'refreshToken', null, 'Apex');
        }

        return fieldWithValuesMap;
    }
}