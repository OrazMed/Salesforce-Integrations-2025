public class ZendeskUserListWrapper{
    
	public users[] users;
	// public next_page next_page;
	// public previous_page previous_page;
	public String next_page;
	public String previous_page;
	public Integer count;	//10
	public class users {
		public Long id;	//4922775290399
		public String name;	//O M
		public String email;	//useroraz@gmail.com
		public String created_at;	//2025-08-04T13:38:02Z
		public String updated_at;	//2025-08-06T16:00:00Z
		public String time_zone;	//Europe/London
		public String phone;
		public photo photo;
		public String locale;	//en-gb
		public Long organization_id;	//4922775354143
		public String role;	// Allowed values are "end-user", "agent", or "admin".
		public boolean verified;
		public boolean active;
		public String last_login_at;	//2025-08-06T16:00:00Z
		public boolean restricted_agent;
		public boolean suspended;
		public Long default_group_id;	//4922775353503
	}
	// public class phone {
	// }
	public class photo {
	}
	// public class next_page {
	// }
	// public class previous_page {
	// }

	public static ZendeskUserListWrapper parse(String json){
		return (ZendeskUserListWrapper) System.JSON.deserialize(json, ZendeskUserListWrapper.class);
	}
}