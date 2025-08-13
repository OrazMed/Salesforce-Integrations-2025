public with sharing class CaseTriggerHandler {
    
    public static void handleAfterInsert(List<Case> newRecords) {

        /*
        if(System.isFuture() || System.isBatch()) {
            return;
        }

        Set<Id> caseIdsWithContacts = new Set<Id>();
        for(Case c : newRecords) {
            if(c.ContactId != null) {
                caseIdsWithContacts.add(c.Id);
            }else {
                System.Debug('Cases do not have Contacts!');
            }
        }

        //for(Case c: newRecords) { // make a SOQL query to get the Contact Detials
        for(Case c : [SELECT Id, Description, Subject, Priority, Contact.Name, Contact.Email FROM Case WHERE Id IN :caseIdsWithContacts]) {
            ZendeskTicketUtils.TicketWrapper wrapper = new ZendeskTicketUtils.TicketWrapper();
            wrapper.body     = c.Description;
            wrapper.subject  = c.Subject;
            wrapper.priority = c.Priority.toLowerCase(); // Allowed values are "urgent", "high", "normal", or "low".
            wrapper.name     = c.Contact.Name; // 'Oraz Med';
            wrapper.email    = c.Contact.Email; // 'orazmed@example.org';
            makeCallout(JSON.serialize(wrapper), c.Id);
        }
        */

        Set<Id> caseIds = new Map<Id, Case>(newRecords).keySet();

        if(!caseIds.isEmpty()) {
            ZendeskTicketUtils.createTicketInZendesk(caseIds);
        }

    }


    public static void handleAfterUpdate(List<Case> newRecords, Map<Id, Case> oldRecordMap) {
        Set<Id>  agentIds = new Set<Id>();
        Map<Decimal, String> assignmentsToUpdate = new Map<Decimal, String>();

        for(Case c : newRecords) {
            Case oldCase = oldRecordMap.get(c.Id);

            if(c.Assigned_Agent__c != null && oldCase.Assigned_Agent__c != null && c.Zendesk_Ticket_Id__c != null) {
                agentIds.add(c.Assigned_Agent__c);
            }
        }

        if(agentIds.isEmpty()) {
            return;
        }

        Map<Id, Zendesk_Agent__c> agentsMap = new Map<Id, Zendesk_Agent__c>([SELECT Id, Zendesk_User_ID__c FROM Zendesk_Agent__c WHERE Id IN :agentIds]);

        for(Case c : newRecords) {
            if(c.Assigned_Agent__c != null && oldRecordMap.get(c.Id).Assigned_Agent__c == null && c.Zendesk_Ticket_Id__c != null) {
                Zendesk_Agent__c agent = agentsMap.get(c.Assigned_Agent__c);

                if(agent != null && agent.Zendesk_User_ID__c != null) {
                    assignmentsToUpdate.put(c.Zendesk_Ticket_Id__c, agent.Zendesk_User_ID__c);
                }
            }
        }

        if(!assignmentsToUpdate.isEmpty()) {
            ZendeskTicketUtils.updateTicketAssigneesInZendesk(assignmentsToUpdate);
        }
    }


    @future(callout = true) // Future methods do not support parameter type of ZendeskTicketUtils.TicketWrapper
    private static void makeCallout(String params, Id caseId) {
        // Convert the String into an Object(class)
        ZendeskTicketUtils.TicketWrapper wrapper = (ZendeskTicketUtils.TicketWrapper)JSON.deserialize(params, ZendeskTicketUtils.TicketWrapper.class);
        ZendeskTicketUtils.createTicket(wrapper, caseId);
    }

}