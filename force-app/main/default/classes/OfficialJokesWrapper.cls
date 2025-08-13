public class OfficialJokesWrapper{
    
	public String type;	//general
	public String setup;	//I saw a nice stereo on Craigslist for $1. Seller says the volume is stuck on ‘high’
	public String punchline;	//I couldn’t turn it down.
	public Integer id;	//370

	public static OfficialJokesWrapper parse(String json){
		return (OfficialJokesWrapper) System.JSON.deserialize(json, OfficialJokesWrapper.class);
	}
}