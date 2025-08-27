/**
 * This is Apex REST service for Custom Rest
 */

 /**
  * Org Base URL - Instance URL + /services/apexrest/v1/AccountManager/
  * (Classic url) - https://orgfarm-8b60f05db0-dev-ed.develop.my.salesforce.com/services/apexrest/v1/AccountManager
  */
@RestResource(urlMapping = '/v1/AccountManager/*')
global with sharing class AccountManager {

    /** List all the Slesforce Accounts - GET (method) */
    /**
     *  @httpGet - GET
     *  @httpPost - POST
     *  @httpPut - PUT
     *  @httpPatch - PATCH
     *  @httpDelete - DELETE
     */

    /** There can be only one type of HTTP method per class
     * No using multiple GET methods, etc
     */

    @httpGet // Only one method per type can be defined with: HttpGet
    global static List<Account> getAccounts() {
        RestRequest req = RestContext.request;
        System.debug(System.JSON.serializePretty(req));

        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));

        return [SELECT Id, Name, Phone FROM Account LIMIT 10];
    }
    
    /*@httpGet
    global static Account getAccount() {
        return [SELECT Id, Name, Phone FROM Account LIMIT 1];
    }*/


            /*
    @httpPost
    global static String createAccount(String name, String rating, String phone) {
        // RestRequest is used when the method (createAccount) doesn't accept any parameter
        RestRequest req = RestContext.request;
        System.debug(System.JSON.serializePretty(req));

        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));

        Account account = new Account(Name = name,
                                        Phone = phone,
                                        Rating = rating);
        insert account;
        return account.Id;
    }
            */

    @httpPost
    global static Account createAccount() {
        // RestRequest is used when the method (createAccount) doesn't accept any parameter
        /** Get the information about Request */
        RestRequest req = RestContext.request;
        System.debug(System.JSON.serializePretty(req));
        /** Get request Body */
        String body = req.requestBody.toString(); // Converts Blob into String format
        System.debug('REQUEST BODY ==> ' + body);

        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));

        if(String.isBlank(body)) {
            res.statusCode = 400;
            res.responseBody = Blob.valueOf('{"error": "Request body is empty."}');
            return null;
        }

        Account account = new Account(Name = 'Test',
                                        Phone = '',
                                        Rating = '');
        insert account;
        return account;
    }
}