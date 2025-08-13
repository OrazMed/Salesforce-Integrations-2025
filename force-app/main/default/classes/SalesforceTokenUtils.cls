public with sharing class SalesforceTokenUtils {
    
    public PageReference getAuthCode() {
        /*
           TODO: Get the Custom Metadata Record
        */
        // Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance('SalesforceToken	'); // This is hardcoded name for name of the config. We should use Custom Label for the name to make it dynamic
        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.SalesforceTokenLabel); // Dynamic

        // https://login.salesforce.com/services/oauth2/authorize?
        // client_id=3MVG9rZjd7MXFdLiSRIWrHHwo2oc0GdBjrLB7RpPzXJXyppJwBt_zuTnCZytL9qc57mysDKQwxcRhDybemMbb&
        // redirect_uri=https://www.google.com/&
        // response_type=code
        if(config != null) {
            String orgUrl = config.Environment__c == 'Production' ? 'https://login.salesforce.com' : 'https://test.salesforce.com';
            System.debug('orgUrlL === ' + orgUrl);
            // https://orgfarm-8b60f05db0-dev-ed--c.develop.vf.force.com/apex/SalesforceTokenPage
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;
            System.debug('redirect_uri === ' + redirect_uri);
            String authorizeUrl = orgUrl + config.auth_url__c + '?client_id=' + config.client_id__c + '&redirect_uri=' + redirect_uri + '&response_type=code'; // EncodingUtil.urlDecode(redirect_uri, 'UTF-8')
            System.debug('Authorize URL === ' + authorizeUrl);
            return new PageReference(authorizeUrl);
        } else {
            return null;
        }
    }


    public void getAccessToken() {
        // code=aPrx.ppuB8UlvcFRsMPxTZPoXgM3IjXdh4rcgp0zBfr.tSH0pHhUSRQZquL2ZyUjw8rxgT.EfQ%3D%3D
        String code = ApexPages.CurrentPage().getParameters().get('code');
        System.debug('code === ' + code);

        Salesforce_Config__mdt config = Salesforce_Config__mdt.getInstance(System.Label.SalesforceTokenLabel);
        
        if(config != null) {
            String orgUrl = config.Environment__c == 'Production' ? 'https://login.salesforce.com' : 'https://test.salesforce.com';
            String tokenUrl = orgUrl + config.token_url__c;
            String redirect_uri = System.URL.getOrgDomainUrl().toExternalForm() + '/apex/' + config.PageName__c;

            String reqBody = 'code=' + code + '&grant_type=authorization_code&client_id=' + config.client_id__c + '&client_secret=' + config.client_secret__c + '&redirect_uri=' + redirect_uri;
            System.debug('reqBody === ' + reqBody);

            HttpRequest httpReq = new HttpRequest();
            httpReq.setEndpoint(tokenUrl);
            httpReq.setMethod('POST');
            httpReq.setBody(reqBody);
            httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
            httpReq.setHeader('Accept', 'application/json');

            Http http = new Http();
            try{
                HttpResponse httpResp = http.send(httpReq);
                if(httpResp.getStatusCode() == 200) {
                    // Success
                    System.debug('SUCCESS \n ' + httpResp.getBody());
                    SalesforceTokenWrapper wrapper = SalesforceTokenWrapper.parse(httpResp.getBody());
                    /*
                        TODO: Deploy the Custom Metadata
                            ! How to deploy?
                        Metadata is a Namespace
                            CustomMetadata - Class
                            CustomMetaValue - Class
                            Operations - Class
                            DeployCallback - Interface
                    */
                }else {
                    // Error
                    System.debug('ERROR \n ' + httpResp.getBody());
                }
            } catch (System.CalloutException e) {

            } catch (System.Exception e) {

            }
        }
        
    }
}