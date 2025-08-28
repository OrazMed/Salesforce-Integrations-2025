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

     /*
    @httpGet // Only one method per type can be defined with: HttpGet
    global static List<Account> getAccounts() {
        RestRequest req = RestContext.request;
        System.debug(System.JSON.serializePretty(req));

        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));

        return [SELECT Id, Name, Phone FROM Account LIMIT 10];
    }
    */
    
    @httpGet
    global static ResponseWrapper getAccount() {
        RestRequest req = RestContext.request;
        System.debug('REQUEST \n ' + System.JSON.serializePretty(req));

        RestResponse res = RestContext.response;
        System.debug('RESPONSE \n ' + System.JSON.serializePretty(res));

        String accountId = req.requestURI.substringAfterLast('/');
        System.debug('ACCOUNT ID ==> ' + accountId);
        ResponseWrapper wrapper = new ResponseWrapper();

        if(String.isBlank(accountId)) {
            wrapper.status = 'FAILED';
            wrapper.message = 'Account ID is missing!';

            return wrapper;
        }

        try {
            Account account = [SELECT Id, Name, Phone, Industry, BillingAddress, ShippingAddress, BillingStreet, BillingCity, BillingState, BillingCountry, ShippingStreet, ShippingCity, ShippingState, ShippingCountry
                            FROM Account 
                            WHERE Id =: accountId
                            LIMIT 1];
            System.debug('ACCOUNT ==> ' + account);
            
            if(account != null) {
                wrapper.Status = 'SUCCESS';
                wrapper.message = 'Account record found!';
                wrapper.id = account.Id;
                wrapper.name = account.Name;
                wrapper.industry = account.Industry;
                wrapper.phone = account.Phone;

                wrapper.billingAddress = new Address();
                wrapper.billingAddress.street = account.BillingStreet;
                wrapper.billingAddress.city = account.BillingCity;
                wrapper.billingAddress.state = account.BillingState;
                wrapper.billingAddress.country = account.BillingCountry;
                
                wrapper.shippingAddress = new Address();
                wrapper.shippingAddress.street = account.ShippingStreet;
                wrapper.shippingAddress.city = account.ShippingCity;
                wrapper.shippingAddress.state = account.ShippingState;
                wrapper.shippingAddress.country = account.ShippingCountry;
            }
            return wrapper;
        } catch (QueryException e) {
            wrapper.status = 'ERROR';
            wrapper.message = 'Something went wrong! Give the following error message to System Developer: ' + e.getMessage();
            return wrapper;
        }
    }


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


    @httpDelete
    global static ResponseWrapper deleteAccount() {
        RestRequest req = RestContext.request;

        RestResponse res = RestContext.response;
        System.debug(System.JSON.serializePretty(res));
        String accId = req.requestURI.substringAfterLast('/');
        //Database.delete(accId, false);
        ResponseWrapper response = new ResponseWrapper();

        try {
            Database.DeleteResult result = Database.delete(accId, false);
            
            if(result.isSuccess()) {
                response.status = 'Success';
                response.message = 'Account deleted successfully!';
                response.id = accId;
            } else {
                List<Database.Error> errors = result.getErrors();

                for(Database.Error error : errors) {
                    System.debug(error.getStatusCode() + ' ' + error.getMessage());
                }

                if(!errors.isEmpty()) {
                    Database.Error err = errors[0];
                    response.status = String.valueOf(err.getStatusCode());
                    response.message = err.getMessage();
                } else {
                    response.status = 'ERROR';
                    response.message = 'Something went wrong!';
                }
                response.id = accId;
            }
        } catch (DmlException e) {
                response.status = 'ERROR';
                response.message = 'Account deletion was unsuccessful!';
                response.id = accId;
        }
        return response;
    }


    global class ResponseWrapper {
        global String status;
        global String message;
        global String id;
        global String name;
        global String industry;
        global String phone;
        global Address billingAddress;
        global Address shippingAddress;
    }

    global class Address {
        global String street;
        global String city;
        global String state;
        global String country;
    }
}