public with sharing class ZendeskTicketUtils {

    /* // Debug run:
    ZendeskTicketUtils.TicketWrapper wrapper = new ZendeskTicketUtils.TicketWrapper();
    wrapper.body = 'Dynamic body';
    wrapper.subject = 'Testing from Salesforce apex!';
    wrapper.priority = 'urgent';
    wrapper.name = 'Oraz Med';
    wrapper.email = 'orazmed@example.org';

    ZendeskTicketUtils.createTicket(wrapper);
    */

    public class TicketWrapper {
        public String body;
        public String subject;
        public String priority;
        public String name;
        public String email;
    }


    public static void createTicket(TicketWrapper wrapper, Id caseId) {
        /*
            Case -->
                Case is Created in Salesforce
                    Zendesk
        */

        String header = System.Label.Zendesk_Username + ':' + System.Label.Zendesk_Token;

        String requestBody = '{'+
		'    "ticket": {'+
		'        "comment": {'+
		'            "body": "'+wrapper.body+'"'+
		'        },'+
		'        "priority": "'+wrapper.priority+'",'+
		'        "subject": "'+wrapper.subject+'",'+
		'        "requester": {'+
		'            "locale_id": 8,'+
		'            "name": "'+wrapper.name+'",'+
		'            "email": "'+wrapper.email+'"'+
		'        }'+
		'    }'+
		'}';

        HttpRequest httpReq = new HttpRequest();
        httpReq.setEndpoint(System.Label.Zendesk_Endpoint + '/api/v2/tickets');
        httpReq.setMethod('POST');
        httpReq.setBody(requestBody); // String --> XML/JSON
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json');
        httpReq.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(header)));

        Http http = new Http();
        try{
            HttpResponse httpResp = http.send(httpReq);
            if(httpResp.getStatusCode() == 201) {
                // Success
                System.debug('SUCCESS \n ' + httpResp.getBody());
                String responseBody = httpResp.getBody();
                System.debug('Response Body \n ' + responseBody);
                Case caseRec = [SELECT Id, Zendesk_Response_Body__c, Zendesk_Ticket_Id__c FROM Case WHERE Id =:caseId LIMIT 1];
                caseRec.Zendesk_Response_Body__c = responseBody;
                //ZendeskResponseWrapper wrappedRes = (ZendeskResponseWrapper)JSON.deserialize(responseBody, ZendeskResponseWrapper.class);
                ZendeskResponseWrapper wrappedRes = ZendeskResponseWrapper.parse(responseBody);
                caseRec.Zendesk_Ticket_Id__c = wrappedRes.ticket.id;
                update caseRec;
            }else {
                // Error
                System.debug('ERROR \n ' + httpResp.getBody());
            }
        } catch (System.CalloutException e) {

        } catch (System.Exception e) {

        }
    }


    @future(callout=true)
    public static void createTicketInZendesk(Set<Id> caseIds) { // new updated/created case ids passed as parameter
        List<Case> casesToUpdate = new List<Case>();
        List<Case> casesToQuery = [SELECT Id, Subject, Priority, Description, ContactId, Contact.Name, Contact.Email, Assigned_Agent__r.Zendesk_User_ID__c FROM Case WHERE Id IN :caseIds];

        String header = System.Label.Zendesk_Username + ':' + System.Label.Zendesk_Token;

        for(Case c: casesToQuery) {
            ZendeskTicketWrapper.CreateTicket reqBody = new ZendeskTicketWrapper.CreateTicket(c.Subject, c.Description, c.Priority, c.Contact.Email, c.Contact.Name, c.Assigned_Agent__c);

            if(c.Assigned_Agent__r.Zendesk_User_ID__c != null) {
                reqBody.ticket.assignee_id = Long.valueOf(c.Assigned_Agent__r.Zendesk_User_ID__c);
            }

            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.Label.Zendesk_Endpoint + '/api/v2/tickets');
            req.setMethod('POST');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(header)));
            req.setBody(JSON.serialize(reqBody));
            HttpResponse res = new Http().send(req);

            if(res.getStatusCode() == 201) {
                ZendeskResponseWrapper response = ZendeskResponseWrapper.parse(res.getBody());
                Long zendeskId = response.ticket.id;
                Long assigneeId = response.ticket.assignee_id;

                // Cases to be updated with the new Zendesk Ids
                casesToUpdate.add(new Case(Id = c.Id, Zendesk_Ticket_Id__c = zendeskId));
                System.debug('SUCCESS after insert::: ' + c.Id + '. Status::: ' + res.getStatus() + '. StatusCode::: ' + res.getStatusCode() + '. Body::: ' + res.getBody());
            }else {
                System.debug('Error::: ' + c.Id + '. Status::: ' + res.getStatus() + '. StatusCode::: ' + res.getStatusCode() + '. Body::: ' + res.getBody());
            }
        }
        if(!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }


    public static void updateTicketAssigneesInZendesk(Map<Decimal, String> assignmentsToUpdate) {
        
        String header = System.Label.Zendesk_Username + ':' + System.Label.Zendesk_Token;

        for(Decimal zendeskTicketId : assignmentsToUpdate.keySet()) {
            String assigneeId = assignmentsToUpdate.get(zendeskTicketId);

            ZendeskTicketWrapper.UpdateTicket reqBody = new ZendeskTicketWrapper.UpdateTicket(assigneeId);

            HttpRequest req = new HttpRequest();
            req.setEndpoint(System.Label.Zendesk_Endpoint + '/api/v2/tickets/' + zendeskTicketId);
            req.setMethod('PUT');
            req.setHeader('Content-Type', 'application/json');
            req.setHeader('Accept', 'application/json');
            req.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(header)));
            req.setBody(JSON.serialize(reqBody));
            
            HttpResponse res = new HttpResponse();
            Http http = new Http();
            res = http.send(req);

            if(res.getStatusCode() == 200) {
                System.debug('SUCCESS updating Zendesk Ticket Ids::: ' + res.getStatus() + '. Status Code::: ' + res.getStatusCode() + '. Body::: ' + res.getBody());
            } else {
                System.debug('ERROR::: ' + res.getStatus() + '. Status Code::: ' + res.getStatusCode() + '. Body::: ' + res.getBody());
            }
        }
    }


    public static HttpResponse getUsers(String endpointURL) {
        HttpRequest httpReq = new HttpRequest();
        //httpReq.setEndpoint(System.Label.Zendesk_Endpoint + '/api/v2/users');
        httpReq.setEndpoint(endpointURL);
        httpReq.setMethod('GET'); // Todo...
        httpReq.setHeader('Content-Type', 'application/json');
        httpReq.setHeader('Accept', 'application/json');
        httpReq.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(System.Label.Zendesk_Username + ':' + System.Label.Zendesk_Token)));

        Http http = new Http();
        HttpResponse httpResp = new HttpResponse();
        try{
            httpResp = http.send(httpReq);
            Integer statusCode = httpResp.getStatusCode();
            String status = httpResp.getStatus();
            String responseBody = httpResp.getBody();
            System.debug('Response body - ' + responseBody);
            System.debug('Status code - ' + statusCode);
            if(statusCode == 200) {
                // SUCCESS
                //ZendeskUserListWrapper wrappedRes = ZendeskUserListWrapper.parse(responseBody);
                //System.debug('All Zendesk Users - ' + wrappedRes);
                return httpResp;
            }else {
                // ERROR
                System.debug('ERROR \n ' + httpResp.getBody());
                return httpResp;
            }
        }catch(System.CalloutException e) {
            // Callout exception
            System.debug('Callout Error - ' + e.getStackTraceString());
            httpResp = new HttpResponse();
            httpResp.setStatusCode(500); // 500: An error has occurred within Lightning Platform, so the request couldn’t be completed.
            httpResp.setStatus('CALLOUT ERROR!');
            httpResp.setBody(e.getStackTraceString());
            
            return httpResp;
        }catch(System.Exception e) {
            // Exception
            System.debug('Exception Error - ' + e.getStackTraceString());
            httpResp = new HttpResponse();
            httpResp.setStatusCode(503); // 503: The server is unavailable to handle the request.
            httpResp.setStatus('CALLOUT ERROR!');
            httpResp.setBody(e.getStackTraceString());
            
            return httpResp;
        }
    }
}