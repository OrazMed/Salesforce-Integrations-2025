public class SalesforceTokenWrapper{
	public String access_token;	
	public String refresh_token;
	public String signature;
	public String scope;
	public String id_token;	
	public String instance_url;
	public String id;
	public String token_type;	//Bearer
	public String issued_at;
    
	public static SalesforceTokenWrapper parse(String json){
		return (SalesforceTokenWrapper) System.JSON.deserialize(json, SalesforceTokenWrapper.class);
	}
}