public with sharing class OfficialJokesServices {
    public static void getOfficialJoke() {
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint('https://official-joke-api.appspot.com/random_joke');
        httpReq.setMethod('GET');
        Http http = new Http();
        try {
            HttpResponse httpResp = new HttpResponse();
            httpResp = http.send(httpReq);
            String responseBody = httpResp.getBody();
            System.debug('Response from Official Jokes = ' + responseBody);
            String status = httpResp.getStatus();
            Integer statusCode = httpResp.getStatusCode();
            if(statusCode == 200) {
                OfficialJokesWrapper wrapper = OfficialJokesWrapper.parse(responseBody);
                System.debug('wrapper: ' + wrapper);
                if(wrapper != null){
                    String joke = wrapper.setup;
                    System.debug('Response joke = ' + joke);
                }
            }
        }catch(System.CalloutException calloutEx) {
            System.debug('System.CalloutException ... ' + calloutEx.getStackTraceString());
        }
    }
}