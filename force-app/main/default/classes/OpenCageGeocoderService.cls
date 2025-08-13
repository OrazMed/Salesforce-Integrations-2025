public with sharing class OpenCageGeocoderService {
    public static void reverseGeoCoding(String accountId) { //argument
        /* Step 0: Get lat and long from account */
        Account acc = [SELECT Id, Location__latitude__s, Location__longitude__s 
                        FROM Account 
                        WHERE Id =: accountId AND Location__latitude__s != null AND Location__longitude__s != null
                        LIMIT 1
                    ];
        /* Step 0.1: Prepare query parameters */
        String queryParams = acc.Location__latitude__s + ',' + acc.Location__longitude__s; // formatted per API doc

        /* Callouts only */
        /* Step 1: prepare the request */
        HttpRequest httpReq = new HttpRequest();
        /* Step 1.1: set endpoint */
        httpReq.setEndpoint(System.Label.OPENCAGE_API_URL + '?key=' + System.Label.OPENCAGE_API_KEY + '&q=' + queryParams + '&pretty=1');
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

            if(statusCode == 200) {
                //main logic
                // JSON class inside system namespace
                // deserialize, deserializeUntypes, deserializeStrict
                OpenCageReverseResponseWrapper wrapper = (OpenCageReverseResponseWrapper)System.JSON.deserialize(responseBody, OpenCageReverseResponseWrapper.class);
                if(wrapper?.results?.size() > 0) { // condition is same as (wrapper != null && wrapper.results != null && wrapper.results.size() > 0)
                    OpenCageReverseResponseWrapper.results rslt = wrapper.results[0];
                    System.debug('The response from OpenCage Data API - ' + rslt.formatted);
                    // Update Account Record
                    acc.BillingStreet = rslt?.components?.road;
                    acc.BillingPostalCode = rslt?.components?.postcode;
                    acc.BillingCity = rslt?.components?.city;
                    acc.BillingState = rslt?.components?.state;
                    acc.BillingCountry = rslt?.components?.country;
                    
                    acc.ShippingStreet = rslt?.components?.road;
                    acc.ShippingPostalCode = rslt?.components?.postcode;
                    acc.ShippingCity = rslt?.components?.city;
                    acc.ShippingState = rslt?.components?.state;
                    acc.ShippingCountry = rslt?.components?.country;
                    System.debug('this is where update happened. acc.ShippingCountry = ' + acc.ShippingCountry);
                    update acc;
                    System.debug('this is where update happened. acc.ShippingCountry = ' + acc.ShippingCountry);
                }
            } else {
                // error handling...
            }
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


    public static void forwardGeocoding(String accountId) {
        // Get accound Billing Address
        Account acc = [SELECT Id, Location__latitude__s, Location__longitude__s, BillingStreet, BillingCity, BillingPostalCode, BillingState, BillingCountry FROM Account WHERE Id =: accountId];
        // Prepare query parameter
        String queryParams = acc.BillingStreet + ',' + acc.BillingCity + ',' + acc.BillingState + ',' + acc.BillingPostalCode + ',' + acc.BillingCountry;
        String encodedQueryParams = EncodingUtil.urlEncode(queryParams, 'UTF-8');
        // Step 1: prapare the request
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(System.Label.OPENCAGE_API_URL + '?key=' + System.Label.OPENCAGE_API_KEY + '&q=' + encodedQueryParams + '&pretty=1');
        httpReq.setMethod('GET');

        //Step 2: send the request
        Http http = new Http();
        try {
            HttpResponse httpResp = new HttpResponse();
            httpResp = http.send(httpReq);
            // Step 3: Process the response
            String responseBody = httpResp.getBody();
            Integer statusCode = httpResp.getStatusCode();
            // String status = httpResp.getStatus();
            // System.debug('Http request response from OpenCage - ' + statusCode);
            // System.debug('Http request response from OpenCage - ' + status);
            System.debug('Http request response from OpenCage - ' + responseBody);

            if(statusCode == 200) {
                // Deserialize the response body
                OpenCageForwardResponseWrapper wrapper = (OpenCageForwardResponseWrapper)System.JSON.deserialize(responseBody, OpenCageForwardResponseWrapper.class);
                if(wrapper?.results?.size() > 0) {
                    OpenCageForwardResponseWrapper.results rst = wrapper.results[0];
                    acc.Location__latitude__s = rst.geometry.lat;
                    acc.Location__longitude__s = rst.geometry.lng;
                    System.debug('updated lat and long = ' + acc.Location__latitude__s + ' and ' + acc.Location__longitude__s);
                    update acc;
                }
            }
        }catch (System.CalloutException calloutEx) {
            System.debug('System.CalloutException ... ' + calloutEx.getStackTraceString());
            if(String.valueOf(calloutEx).startsWith('System.CalloutException: Unauthorized endpoint')) {
                // Remote site settings error - custom error message
                System.debug('CalloutException ... ');
            } 
        }catch (System.Exception ex) {
            System.debug('Exception ... ' + ex.getStackTraceString());
            if(String.valueOf(ex).startsWith('System.CalloutException: Unauthorized endpoint')) {
                // Remote site settings error - 
                System.debug('Exception ... ');
            }
        }
    }
}