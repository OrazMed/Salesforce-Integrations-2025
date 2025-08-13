/*
    Batch class gets all Zendesk Users and maps them to Zendesk_User__c Custom Object.
*/

public class ZendeskUserSynchBatch implements Database.Batchable<ZendeskUserListWrapper.users>, Database.Stateful, Database.AllowsCallouts{
    private String endpointURL;
    private String next_page_URL;
    private Integer batch_count;

    public ZendeskUserSynchBatch() {
        this.endpointURL = System.Label.Zendesk_Endpoint + '/api/v2/users';
    }

    public ZendeskUserSynchBatch(String url) {
        this.next_page_URL = url;
    }

    public Iterable<ZendeskUserListWrapper.users> start(Database.BatchableContext bc) { // ZendeskUserListWrapper.users
        System.debug('Endpoint URL: ' + this.endpointURL);

        HttpResponse res = ZendeskTicketUtils.getUsers(this.endpointURL);

        if(res.getStatusCode() == 200) {
            // SUCCESS
            ZendeskUserListWrapper wrapper = ZendeskUserListWrapper.parse(res.getBody());

            this.next_page_URL = wrapper.next_page;

            if(wrapper.users != null) {
                return wrapper.users;
            }
        }else {
            // ERROR
            System.debug('Zendesk API call failed: ' + res.getStatusCode() + ' === Status: ' + res.getStatus() + ' === Response Body: ' + res.getBody());
        }

        return new List<ZendeskUserListWrapper.users>(); // ZendeskUserListWrapper.users
    }

    public void execute(Database.BatchableContext bc, List<ZendeskUserListWrapper.users> scope) {
        List<Zendesk_Agent__c> agentsList = new List<Zendesk_Agent__c>();
        for(ZendeskUserListWrapper.users z : scope) {
            if(z.verified) {
                Zendesk_Agent__c agent = new Zendesk_Agent__c();
                agent.Zendesk_User_ID__c = String.valueOf(z.id);
                agent.Name = z.name;
                agent.Is_Active__c = z.active;
                agent.Email__c = z.email;
                agent.Last_Login__c = parseDateTime(z.last_login_at);
                agent.Phone__c = z.phone;
                agent.Role__c = z.role;
                agent.Time_Zone__c = parseDateTime(z.time_zone);

                agentsList.add(agent);
            }
        }

        if(!agentsList.isEmpty()) {
            try {
                upsert agentsList Zendesk_Agent__c.Zendesk_User_ID__c; // or Zendesk_Agent__c.Fields.Zendesk_User_ID__c;
                System.debug('UPSERTED ZENDESK USERS: ' + agentsList.size());
            }catch(Exception e) {
                System.debug('ERROR UPSERTING ZENDESK USERS: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        this.batch_count++;
        System.debug('ZendeskUserSynchBatch FINISHED A CYCLE.' + this.batch_count);

        if(this.next_page_URL != null) {
            System.debug('NEXT PAGE URL: ' + this.next_page_URL);
            Database.executeBatch(new ZendeskUserSynchBatch(this.next_page_URL), 2);
        }else {
            System.debug('NEXT PAGE URL IS NULL. DONE.');
            String finishMessage = 'The Zendesk user sych has finished completely.';
            sendNotificationToEmail.sendEmail('Zendesk User Syncronization', finishMessage);
        }
    }


    private Datetime parseDateTime(String dt) {
        if(String.isNotBlank(dt)) {
            try{
                return (Datetime)JSON.deserialize('"' + dt + '"', Datetime.class);
            }catch(Exception e) {
                return null;
            }
        }
        return null;
    }
}