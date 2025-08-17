public class MetadataWrapper{

    public records[] records;

    public class records{
        public String label;
        public String developerName;
        public String flag;
        public String isoAlpha2;
        public String isoAlpha3;
        public String currencyCode;
        public String currencySymbol;
        public Decimal latitude;
        public Decimal longitude;
    }

	public static MetadataWrapper parse(String json){
		return (MetadataWrapper) System.JSON.deserialize(json, MetadataWrapper.class);
	}
}