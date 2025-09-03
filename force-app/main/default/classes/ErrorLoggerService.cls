public class ErrorLoggerService {
    
    public static void logError(Exception e,
                                String apexClass,
                                String apexMethod,
                                Id relatedRecId,
                                String type) {
        if(e == null) {
            return;
        }

        String stackTrace = e.getStackTraceString().abbreviate(131072);
        String message = e.getMessage().abbreviate(32768);
        String severity = 'Error';

        createLogRecordAsync(message, severity, stackTrace, apexClass, apexMethod, relatedRecId, UserInfo.getUserId(), type);
    }

    public static void logInfo(String message,
                               String apexClass,
                               String apexMethod,
                               Id relatedRecId,
                               String type) {
        String severity = 'Info';
        String stackTrace = 'N/A';
        String messageAbbr = message.abbreviate(32768);

        createLogRecordAsync(messageAbbr, severity, stackTrace, apexClass, apexMethod, relatedRecId, UserInfo.getUserId(), type);
    }

    @future
    private static void createLogRecordAsync(String message,
                                             String severity,
                                             String stackTrace,
                                             String apexClass,
                                             String apexMethod,
                                             Id relatedRecId,
                                             Id userId,
                                             String type) {
        try {
            Error_Log__c log = new Error_Log__c();
            log.Log_Message__c = message;
            log.Severity__c = severity;
            log.Stack_Trace__c = stackTrace;
            log.Apex_Class__c = apexClass;
            log.Apex_Method__c = apexMethod;
            log.Related_Record_Id__c = relatedRecId;
            log.User__c = userId;
            log.Log_Type__c = type;

            insert log;
        } catch (Exception e) {
            System.debug('ERROR OCCURRED IN ErrorLoggerService: \n ' + e.getMessage());
            System.debug('ERROR OCCURRED IN ErrorLoggerService (STACK TRACE): \n' + e.getStackTraceString());
        }
    }
}