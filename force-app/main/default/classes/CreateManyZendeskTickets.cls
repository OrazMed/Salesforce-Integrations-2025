public class  CreateManyZendeskTickets{
	public tickets[] tickets;
	public class tickets {
		public comment comment;
		public String assignee_email;	//example@email.com
		public Integer assignee_id;	//65461313984654
		public requester requester;
		public String priority;	//urgent
		public String subject;	//My printer is on fire!
	}
	public class comment {
		public String body;	//The smoke is very colorful.
	}
	public class requester {
		public Integer locale_id;	//8
		public String name;	//Pablo
		public String email;	//pablito@example.org
	}

	public static  CreateManyZendeskTickets parse(String json){
		return ( CreateManyZendeskTickets) System.JSON.deserialize(json,  CreateManyZendeskTickets.class);
	}
    
	public static  String convertToString(CreateManyZendeskTickets obj){
		return ( String) System.JSON.serialize(obj);
	}
}