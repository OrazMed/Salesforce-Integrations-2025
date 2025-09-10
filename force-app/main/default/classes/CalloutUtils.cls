public with sharing class CalloutUtils {
    
    public static HttpRequest prepareRequest(String endPoint, String method, String body, String accept, String contentType, String accessToken) {
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(endPoint);
        httpReq.setMethod(method);
        httpReq.setHeader('Content-Type', contentType);
        if(!String.isBlank(accept)) {
            httpReq.setHeader('Accept', accept);
        }
        if(!String.isBlank(body)) {
            httpReq.setBody(body);
        }
        if(!String.isBlank(accessToken)) {
            httpReq.setHeader('Authorization', 'Bearer ' + accessToken);
        }

        return httpReq;
    }
}