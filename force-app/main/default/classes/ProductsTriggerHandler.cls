public with sharing class ProductsTriggerHandler {

    public static void testSync() {
        List<Product2> products = [SELECT Id, Name, QB_External_Id__c, Sync_With_QuickBooks__c, Synced_With_QuickBooks__c
                                   FROM Product2
                                   WHERE QB_External_Id__c = null
                                   LIMIT 2];
        for(Product2 p : products) {
            p.Sync_With_QuickBooks__c = true;
        }

        List<sObject> updatedProds = DmlService.doUpdate(products, false);

        System.debug('Inserted Products: ' + updatedProds);
        System.debug('Inserted Products number: ' + updatedProds.size());
    }

    public static void handleBeforeUpdates(List<Product2> newRecords, Map<Id, Product2> oldRecordMap) {
        for(Product2 p : newRecords) {
            if(oldRecordMap.get(p.Id).Sync_With_QuickBooks__c == false && p.Sync_With_QuickBooks__c == true) {
                syncProductsWithItems(p.Id);
            }
        }
    }
    
    // accepts primitive data types as arguments (like String, Integer, Boolean, or collections of these)
    @future(callout=true)
    public static void syncProductsWithItems(String prodId) {
        Product2 prod = [SELECT Id, Name, QB_External_Id__c, Sync_With_QuickBooks__c, Synced_With_QuickBooks__c
                        FROM Product2
                        WHERE Id = :prodId
                        LIMIT 1];
                        System.debug('Product to be updated : \n ' + prod);
        List<Product2> syncedProds = new List<Product2>();
        Product2 updatedProd = QB_ItemsUtil.createItem(prod);
        
        System.debug('Product rec returned from createItem method: ' + updatedProd);
        try {
            update updatedProd;
        } catch (DmlException e) {
            System.debug('DML Exception: ' + e.getMessage());
        }
        /*syncedProds.add(updatedProd);
        System.debug('syncedProds: ' + syncedProds);

        List<sObject> updatedRecs = new List<sObject>();
        if(syncedProds.size() > 0) {
            updatedRecs = DmlService.doUpdate(syncedProds, false);
        }
        System.debug('Updated Recs === ' + updatedRecs);*/
    }
}