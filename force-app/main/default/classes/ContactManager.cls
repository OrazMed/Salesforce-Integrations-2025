 /**
  * Org Base URL - Instance URL + /services/apexrest//v1/ContactManager/
  * (Classic url) - https://orgfarm-8b60f05db0-dev-ed.develop.my.salesforce.com/services/apexrest/v1/ContactManager/
  */
@RestResource(urlMapping = '/v1/ContactManager/*')
global with sharing class ContactManager {
    
    /*
    @httpGet
    global static List<Contact> getContacts() {
        return [SELECT FirstName, LastName, Email FROM Contact LIMIT 10];
    }
    */
    
    @httpGet
    global static List<ResposneWrapper> getContacts() {
        RestRequest req = RestContext.request;
        System.debug('REQUEST \n ' + System.JSON.serializePretty(req));

        RestResponse res = RestContext.response;
        System.debug('RESPONSE \n ' + System.JSON.serializePretty(res));

        String requestUri = req.requestURI;
        String accountId = req.requestURI.substringAfter('ContactManager/').substringBefore('/');
        System.debug('ACCOUNT ID ==> ' + accountId);
        //ResposneWrapper wrapper = new ResposneWrapper();
        List<ResposneWrapper> responseToReturn = new List<ResposneWrapper>();

        try {
            List<Contact> cons = [SELECT Id, FirstName, LastName, Phone, Email, AccountId, Account.Name FROM Contact WHERE AccountId =: accountId];
            System.debug('Number of Contacts found: ' + cons.size());
            for(Contact con : cons) {
                ResposneWrapper wrapper = new ResposneWrapper();
                wrapper.contactRecord = con;
                wrapper.accountRecord = con.Account;
                wrapper.status = 'Existing';
                wrapper.message = 'This is contact number ' + cons.indexOf(con) + ' of ' + cons.size();
                wrapper.numberOfContacts = cons.size();
                responseToReturn.add(wrapper);
            }
            if(responseToReturn.size() == 0) {
                ResposneWrapper wrapper = new ResposneWrapper();
                wrapper.status = 'INFO';
                wrapper.message = 'There are no contacts found for this account';
                responseToReturn.add(wrapper);
            }

            return responseToReturn;
        } catch (QueryException e) {
            ResposneWrapper wrapper = new ResposneWrapper();
            wrapper.status = 'ERROR';
            wrapper.message = 'Something went wrong! Give the following error message to System Developer: ' + e.getMessage();
            responseToReturn.add(wrapper);
            return responseToReturn;
        }
    }


    /**
     * Account - Name, Industry, Rating, AnnaulRevenue, Phone
     * Contact - FirstName, LastName, Email, Phone, Title
     */
    /*
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
    */

    @httpPost
    global static ResposneWrapper processData(InputWrapper input) {
        List<Contact> existingContacts = [SELECT Id, Email FROM Contact WHERE Email = : input.Email];
        ResposneWrapper wrapper = new ResposneWrapper();

        if(existingContacts?.size() > 0) {
            // Do nothing
            //return existingContacts.get(0);

            wrapper.contactRecord = existingContacts.get(0);
            
            wrapper.status = 'Existing';
            wrapper.message = 'Contact found with the same email addreass';
        } else {
            // Create Account
            Account accountRecord = new Account(Name = input.accountName);
            insert accountRecord;
            // Create Contact
            Contact contactRecord = new Contact(FirstName = input.firstName,
                                                LastName = input.lastName,
                                                Email = input.email,
                                                AccountId = accountRecord.Id
                                                );
            insert contactRecord;

            wrapper.contactRecord = contactRecord;
            wrapper.accountRecord = accountRecord;
            wrapper.status = 'New';
            wrapper.message = 'Contact inserted Successfully!';
        }
            
        return wrapper;
    }


    @httpDelete
    global static void deleteContact() {
        
    }

                                         
    global class InputWrapper {
        global String accountName;
        global String firstName;
        global String lastName;
        global String email;
    }

    global class ResposneWrapper {
        global Contact contactRecord;
        global Account accountRecord;
        global String status; // New, Existing
        global String message; // Success, Error
        global Integer numberOfContacts;
    }
}