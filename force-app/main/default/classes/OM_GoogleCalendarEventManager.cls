/**
 * 
 * 
 */
public with sharing class OM_GoogleCalendarEventManager {
    public static void testCreateEvent() {
        // OM_GoogleCalendarEventManager.testCreateEvent();
        //createEvent('Salesforce', '2025-09-23', '2025-09-24');
    }
    
    public static String createEvent(String subject, DateTime startDateTime, DateTime endDateTime) {
        String eventId = '';
        System.debug('subject = ' + subject);
        System.debug('startDateTime = ' + startDateTime);
        System.debug('endDateTime = ' + endDateTime);

        String metadataRec = System.Label.Google_calendar;
        List<Google_API__mdt> configList = [SELECT Id, access_token__c, auth_url__c, base_url__c, client_id__c, client_secret__c, MasterLabel, DeveloperName, expires_in__c, expires_in_time__c, PageName__c, refresh_token__c, scope__c, token_url__c
                                      FROM Google_API__mdt 
                                      WHERE DeveloperName = :metadataRec
                                      LIMIT 1];
        
        if( configList.size() > 0 ) {
            Google_API__mdt config = configList.get(0);
            Map<String, Object> fieldWithValuesMap = new Map<String, Object>();

            String access_token = config.access_token__c;
            Boolean isValid = OM_GoogleApiTokenUtil.isValid(config);
            System.debug('isValid? = '+ isValid);

            if(isValid == false) {// is expired
                // Refresh the Token
                fieldWithValuesMap = OM_GoogleApiTokenUtil.refreshToken(config);
                access_token = (String) fieldWithValuesMap.get('access_token__c');
                String access_token2 = (String) fieldWithValuesMap.get('access_token__c');
                if(access_token2 != access_token) {
                    System.debug('access_token2 and access_token are NOT SAMe ');
                }else {
                    System.debug('access_token2 and access_token are SAME ');
                }
            }
            System.debug('access_token? = '+ access_token);

            String endpoint = 'https://www.googleapis.com' + '/calendar/v3/calendars/' + 'useroraz@gmail.com' + '/events' + '?maxAttendees=5&sendNotifications=true&sendUpdates=all&supportsAttachments=true';

            String strStartDate = startDateTime.formatGmt('yyyy-MM-dd');
            String strEndDate = endDateTime.formatGmt('yyyy-MM-dd');
            System.debug('strStartDate = ' + strStartDate);
            System.debug('strEndDate = ' + strEndDate);

            String body = '{'+
            '  "end": {'+
            '    "date": "'+strEndDate+'" '+
            '    '+
            '  },'+
            '  "start": {'+
            '    "date": "'+strStartDate+'" '+
            '    '+
            '  },'+
            '  "attendees": ['+
            '    {'+
            '      "email": "useroraz@gmail.com"'+
            '      '+
            '    }'+
            '    '+
            '  ],'+
            '  "summary": "'+subject+'" '+
            '  '+
            '}';

            HttpRequest req = CalloutUtils.prepareRequest(endpoint, 'POST', body, 'application/json', 'application/json', access_token);

            try {
                HttpResponse res = (new Http() ).send(req);
                
                if(res.getStatusCode() == 200 || res.getStatusCode() == 201) {
                    System.debug('Status code === ' + res.getStatusCode() );
                    System.debug('Status Body === ' + res.getBody() );
                    Map<String, Object> responseMap = (Map<String, Object>) System.JSON.deserializeUntyped(res.getBody());
                    String calendarId = (String) responseMap.get('id');
                    System.debug('Calendar Id === ' + calendarId);
                    eventId = calendarId;
                    /**
                     * Update the info in Salesforce
                     * OR return the data from here
                     */
                } else {
                    System.debug('Status code === ' + res.getStatusCode() );
                    System.debug('ERROR OCCURRED \n ' + res.getBody());
                    //ErrorLoggerService.logInfo(res.getBody(), 'OM_GoogleCalendarEventManager', 'createEvent', null, 'Apex');
                }
            } catch (System.CalloutException e) {
                System.debug('Callout exception ===> ' + e.getMessage());
                //ErrorLoggerService.logError(e, 'OM_GoogleCalendarEventManager', 'createEvent', null, 'Apex');

            } catch (System.Exception e) {
                System.debug('Any other (than Callout) Exception ===> ' + e.getMessage());
                //ErrorLoggerService.logError(e, 'OM_GoogleCalendarEventManager', 'createEvent', null, 'Apex');
            }
            System.debug('fieldWithValuesMap is Zero size???? === ' + fieldWithValuesMap.size() );
            if(fieldWithValuesMap.size() > 0) {
                System.debug('Updating the Custom Metadata with the new Token');
                String fullName = 'Google_API.' + System.Label.Google_calendar; // Object Name + Record Name
                String label = System.Label.Google_calendar;

                // Update the Custom Metadata
                CreateUpdateMetadataUtils.createUpdateMetadata(fullName, label, fieldWithValuesMap);
            }
        } else {
            // TODO: Enhance this
            System.debug('This message means there is no Config List out there! You should probably contact your Hero (System Admin ;) )');
        }
        return eventId;
    }
}