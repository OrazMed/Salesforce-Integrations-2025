/**
 * Url mapping = instanceUrl + /services/apexrest/v1/CaseManager/
 */
@RestResource(urlMapping = '/v1/CaseManager/*')
global with sharing class CaseManager {
    
    @httpPost
    global static ResponseWrapper createCase(String subject, String description, String caseReason, String contactId) {
        Case c = new Case();
        c.Subject = subject;
        c.Description = description;
        c.Reason = caseReason;
        c.ContactId = contactId;
        insert c;
        System.debug('Case created successfully: ' + c.Id + ' - ' + c.Subject);

        ResponseWrapper wrapper = new ResponseWrapper();
        wrapper.status = 'Success';
        wrapper.message = 'Case created successfully: ' + c.Id + ' - ' + c.Subject;

        return wrapper;

        /*
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {'user@gmail.com'};
        mail.setToAddresses(toAddresses);
        mail.setReplyTo('noreply@example.com');
        mail.setSenderDisplayName('User Oraz Support');
        mail.setSubject('Hey you have created a new Case: ' + c.Id);
        mail.setBccSender(true);
        mail.setUseSignature(false);
        mail.setPlainTextBody('Your case" ' + c.Id + ' has been created successfully!');
        mail.setHtmlBody('Your case:<b> ' + c.Id +' </b>has been created.<p>'+
     'To view your case <a href=https://orgfarm-8b60f05db0-dev-ed.develop.my.salesforce.com/'+case.Id+'>click here.</a>');
        System.debug('Case ID: ' + c.Id);
        System.debug('MAIL: ' + mail);
        OrgWideEmailAddress[] org = [SELECT Id, DisplayName, Address, IsVerified FROM OrgWideEmailAddress WHERE Address = 'useroraz@gmail.com'];
        //mail.setOrgWideEmailAddressId(org[0].Id);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        */
    }

/*
    @httpGet
    global static Case viewCase() {
        RestRequest req = RestContext.request;
        String caseId = req.requestURI.substringAfterLast('/');
        System.debug('Case Id: ' + caseId);

        Case c = [SELECT Id, Subject, Description, Priority, Status, CaseNumber, CreatedDate, ClosedDate, Contact.Name, Contact.Email
                    FROM Case
                    WHERE Id =: caseId
                    LIMIT 1];
        System.debug('Case: ' + c);
        RestResponse res = RestContext.response;
        res.responseBody = Blob.valueOf(System.JSON.serializePretty(c));
        System.debug('Response: ' + res);
        System.debug('Response Body: ' + res.responseBody);

        return c;
    }
*/

    @httpGet
    global static void viewContactCases() { // TODO: Enhancement + Error Handling
        RestRequest req = RestContext.request;
        String contactId = req.requestURI.substringAfter('CaseManager/').substringBefore('/');
        System.debug('Contact Id: ' + contactId);

        List<Case> contactCases = [SELECT Id, Subject, Description, Status, Priority, Contact.Name
                                    FROM Case
                                    WHERE ContactId =: contactId
                                    LIMIT 10];
        RestResponse res = RestContext.response;
        res.responseBody = Blob.valueOf(System.JSON.serializePretty(contactCases));
    }

    global class ResponseWrapper {
        global String status;
        global String message;
    }

    global class CaseWrapper {
        global String subject;
        global String description;
        global String reason;
        global String priority;
        global String caseNumber;
        global String createdDate;
        global String closedDate;
        global String contactName;
    }
}