public with sharing class CurrencyAPIService {
    public static void getExchangeRates () {
        /* Callouts only */
        /* Step 1: prepare the request */
        HttpRequest httpReq = new HttpRequest();
        /* Step 1.1: set endpoint */
        httpReq.setEndpoint('https://open.er-api.com/v6/latest/USD');
        /* Step 1.2: Set headers */
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json'); // api returns: JSON, XML, Text, HTML; but you want to specify which one you want, so you use 'Accept' header
        /* Step 1.3: Set Method */
        httpReq.setMethod('GET');
        /* Step 2: Send the request */
        Http http = new Http();
        try {
            HttpResponse httpResp = http.send(httpReq);
            /* Step 3: Print the Information */
            String responseBody = httpResp.getBody();
            Integer statusCode = httpResp.getStatusCode();
            String status = httpResp.getStatus();
            System.System.debug('The response from Currency API -' + status);
            System.System.debug('The response from Currency API -' + responseBody);
            System.System.debug('The response from Currency API -' + statusCode);
        } catch (System.CalloutException calloutEx) {
            System.debug('System.CalloutException ... ' + calloutEx.getStackTraceString());
            if(String.valueOf(calloutEx).startsWith('System.CalloutException: Unauthorized endpoint')) {
                // Remote site settings error - custom error message
                System.debug('CalloutException ... ');
            }   
        } catch (System.Exception ex) {
            if(String.valueOf(ex).startsWith('System.CalloutException: Unauthorized endpoint')) {
                // Remote site settings error - 
                System.debug('Exception ... ');
            }
        }
       

    }
}