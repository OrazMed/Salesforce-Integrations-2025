public with sharing class sendNotificationToEmail {

    public static void sendEmail(String subject, String message) {
        // List<OrgWideEmailAddress> owea = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@yourcompany.com' LIMIT 1]
        User currentUser = [SELECT Email FROM User WHERE Id = :UserInfo.getUserId()];

        if(currentUser == null || String.isBlank(currentUser.Email)) {
            System.debug('Email address is not provided!');
            return;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>{currentUser.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(message + '\n\n This is an automated message from Salesforce!');

        try{
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            System.debug('Email is sent to: ' + currentUser.Email);
        } catch(exception e){
            System.debug('Exception occured: ' + e.getMessage());
        }
    }
}