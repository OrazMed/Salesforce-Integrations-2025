public with sharing class EventCreatorController {
    
    @AuraEnabled
    public static String createCalendarEvent(String subject, DateTime startDateTime, DateTime endDateTime) {
        String eventId = '';
        if(String.isBlank(subject) || startDateTime == null || endDateTime == null) {
            throw new AuraHandledException('Subject, Start Date and End Date should not be empty!');
        }
        if(startDateTime >= endDateTime) {
            throw new AuraHandledException('End Date and Time must be after the Start Date and Time.');
        }

        Id newEventId;

        try {
            eventId = OM_GoogleCalendarEventManager.createEvent(subject, startDateTime, endDateTime);
        } catch (Exception e) {
            throw new AuraHandledException('Error creating event on Google Calendar: ' + e.getMessage());
        }

        try {
            Event newEvent = new Event(
                Subject = subject,
                ActivityDateTime = startDateTime,
                EndDateTime = endDateTime,
                OwnerId = UserInfo.getUserId()
            );
            insert newEvent;
            newEventId = newEvent.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating event: ' + e.getMessage());
        } catch (Exception e) {
            throw new AuraHandledException('Error any other: ' + e.getMessage() + '; Stack trace: ' + e.getStackTraceString());
        }

        return 'Event ID: ' + eventId;
    }
}