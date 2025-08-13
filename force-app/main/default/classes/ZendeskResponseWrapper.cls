public with sharing class ZendeskResponseWrapper {

    public ticket ticket;
    public class ticket {
        public String url;	//https://abc-5967.zendesk.com/api/v2/tickets/12.json
        public Long id;	//12
        public String created_at;	//2025-08-05T14:13:06Z
        public String updated_at;	//2025-08-05T14:13:06Z
        public Long generated_timestamp;	//0
        public String subject;	//Completely New Case
        public Long assignee_id;	//12
    }
        
	public static ZendeskResponseWrapper parse(String json){
		return (ZendeskResponseWrapper) System.JSON.deserialize(json, ZendeskResponseWrapper.class);
	}
}