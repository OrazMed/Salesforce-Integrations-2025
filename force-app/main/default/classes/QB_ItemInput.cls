public class QB_ItemInput{
	public Boolean TrackQtyOnHand;	//false
	public String Name;	//{{$randomProduct}}
	public Integer QtyOnHand;	//200
	public IncomeAccountRef IncomeAccountRef;
	public AssetAccountRef AssetAccountRef;
	public String InvStartDate;	//2025-01-01
	public String Type;	//Service
	public ExpenseAccountRef ExpenseAccountRef;

	public class IncomeAccountRef {
		public String name;	//Sales of Product Income
		public String value;	//79
	}

	public class AssetAccountRef {
		public String name;	//Inventory Asset
		public String value;	//81
	}

	public class ExpenseAccountRef {
		public String name;	//Cost of Goods Sold
		public String value;	//80
	}
}