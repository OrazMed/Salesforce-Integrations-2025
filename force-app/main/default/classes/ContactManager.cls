 /**
  * Org Base URL - Instance URL + /services/apexrest//v1/ContactManager/
  * (Classic url) - https://orgfarm-8b60f05db0-dev-ed.develop.my.salesforce.com/services/apexrest/v1/ContactManager/
  */
@RestResource(urlMapping = '/v1/ContactManager/*')
global with sharing class ContactManager {
    
    @httpGet
    global static List<Contact> getContacts() {
        return [SELECT FirstName, LastName, Email FROM Contact LIMIT 10];
    }


    /**
     * Account - Name, Industry, Rating, AnnaulRevenue, Phone
     * Contact - FirstName, LastName, Email, Phone, Title
     */
    @httpPost
    global static ResposneWrapper processData(Account accountRecord, Contact contactRecord) {
        System.debug(System.LoggingLevel.DEBUG, accountRecord);
        System.debug(System.LoggingLevel.DEBUG, contactRecord);

        List<Contact> existingContacts = [SELECT Id, Email FROM Contact WHERE Email = : contactRecord.Email];
        ResposneWrapper wrapper = new ResposneWrapper();

        if(existingContacts?.size() > 0) {
            // Do nothing
            //return existingContacts.get(0);

            wrapper.contactRecord = contactRecord;
            wrapper.accountRecord = accountRecord;
            wrapper.status = 'Existing';
            wrapper.message = 'Contact found with the same email addreass';
        } else {
            // Create Account
            insert accountRecord;
            // Create Contact
            contactRecord.AccountId = accountRecord.Id;
            insert contactRecord;

            wrapper.contactRecord = contactRecord;
            wrapper.accountRecord = accountRecord;
            wrapper.status = 'New';
            wrapper.message = 'Contact inserted Successfully!';
        }
            
        return wrapper;
    }


    global class ResposneWrapper {
        global Contact contactRecord;
        global Account accountRecord;
        global String status; // New, Existing
        global String message; // Success, Error
    }
}