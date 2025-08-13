public with sharing class ExchangeRateAPIService {
    public static void getExchangeRates (String myCurrency) {
        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(System.Label.EXHCANGE_RATE_URL + System.Label.EXCHANGE_RATE_KEY +  '/latest/' + myCurrency);
        httpReq.setMethod('GET');

        Http http = new Http();
        try {
            HttpResponse httpResp = new HttpResponse();
            httpResp = http.send(httpReq);
            String responseBody = httpResp.getBody();
            Integer statusCode = httpResp.getStatusCode();
            String status = httpResp.getStatus();
            // System.debug('Exchange rate API response - ' + statusCode);
            // System.debug('Exchange rate API response - ' + status);
            // System.debug('Exchange rate API response - ' + responseBody);
            if(statusCode == 200) {
                ExchangeRateWrapper wrapper = (ExchangeRateWrapper)JSON.deserialize(responseBody, ExchangeRateWrapper.class);
                if(wrapper?.conversion_rates != null) {
                    ExchangeRateWrapper.rates rates = wrapper.conversion_rates;
                    String baseCode = wrapper.base_code;
                    Double GBP = rates.GBP;
                    Double USD = rates.USD;
                    Double MNT = rates.MNT;
                    Double MXN = rates.MXN;
                    System.debug('USD: ' + USD);
                    System.debug('MNT: ' + MNT);
                    System.debug('MXN: ' + MXN);
                    System.debug('Base code: ' + baseCode);
                }
            }
        }catch (System.CalloutException calloutEx) {
            System.debug('System.CalloutException ... ' + calloutEx.getStackTraceString());
            if(String.valueOf(calloutEx).startsWith('System.CalloutException: Unauthorized endpoint')) {
                System.debug('This is remote site setting error or Callout Exception.');
            }
        }
    }
}