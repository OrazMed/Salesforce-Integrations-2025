public class InvoiceResponseWrapper{
	public Invoice Invoice;
	public class Invoice {
		public boolean AllowIPNPayment;
		public boolean AllowOnlinePayment;
		public boolean AllowOnlineCreditCardPayment;
		public boolean AllowOnlineACHPayment;
		public String Id;	//145
		public String SyncToken;
		public String DocNumber;
		public String TxnDate;	//2025-09-03
		public CurrencyRef CurrencyRef;
		public LinkedTxn[] LinkedTxn;
		public Line[] Line;
		public TxnTaxDetail TxnTaxDetail;
		public CustomerRef CustomerRef;
		public BillAddr BillAddr;
		public ShipFromAddr ShipFromAddr;
		public String DueDate;	//2025-10-03
		public Decimal TotalAmt;	//100
		public boolean ApplyTaxAfterDiscount;
		public String PrintStatus;
		public String EmailStatus;
		public Decimal Balance;
        public BillEmail BillEmail;
	}
    public class BillEmail {
        public String Address;
    }
	public class LastModifiedByRef {
		public String value;	//9341455276189331
	}
	public class CurrencyRef {
		public String value;	//USD
		public String name;	//United States Dollar
	}
	public class LinkedTxn {
	}
	public class Line {
		public String Id;	//1
		public Integer LineNum;	//1
		public Decimal Amount;	//100
		public String DetailType;	//SalesItemLineDetail
		public SalesItemLineDetail SalesItemLineDetail;
		public CustomExtensions[] CustomExtensions;
	}
	public class SalesItemLineDetail {
		public ItemRef ItemRef;
		public ItemAccountRef ItemAccountRef;
		public TaxCodeRef TaxCodeRef;
	}
	public class ItemRef {
		public String value;	//1
		public String name;	//Services
	}
	public class ItemAccountRef {
		public String value;	//1
		public String name;	//Services
	}
	public class TaxCodeRef {
		public String value;	//NON
	}
	public class CustomExtensions {
	}
	public class TxnTaxDetail {
		public Decimal TotalTax;	//0
	}
	public class CustomerRef {
		public String value;	//61
		public String name;	//Hoeger and Sons
	}
	public class BillAddr {
		public String Id;	//99
		public String Line1;	//123 Main Street
		public String City;	//Mountain View
		public String Country;	//USA
		public String CountrySubDivisionCode;	//CA
		public String PostalCode;	//94042
	}
	public class ShipFromAddr {
		public String Id;	//100
		public String Line1;	//123 Sierra Way
		public String Line2;	//San Pablo, CA  87999
	}
}