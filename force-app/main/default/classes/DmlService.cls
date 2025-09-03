
public with sharing class DmlService {
    
    public static List<sObject> doInsert(List<sObject> records, Boolean allOrNone) {
        List<sObject> insertedRecords = new List<sObject>();
        Database.SaveResult[] resultList = Database.insert(records, allOrNone);

        for(Integer i = 0; i < resultList.size(); i++) {
            Database.SaveResult result = resultList[i];
            sObject originalRec = records[i];

            if (result.isSuccess()) {
                insertedRecords.add(originalRec);
            } else {
                String errorMessage = '';
                for(Database.Error err : result.getErrors()) {
                    errorMessage += err.getStatusCode() + ' === ' + err.getMessage() + '|';
                }
                ErrorLoggerService.logInfo('DML Insert Failed for ' + originalRec.getSObjectType() + '; ' + errorMessage, 'DmlService', 'insert', originalRec.Id, 'Apex');
            }
        }
        return insertedRecords;
    }


    public static List<sObject> doUpdate (List<sObject> records Boolean allOrNone) {
        List<sObject> insertedRecords = new List<sObject>();
        Database.SaveResult[] resultList = Database.update(records, allOrNone);

        for(Integer i = 0; i < resultList.size(); i++) {
            Database.SaveResult result = resultList[i];
            sObject originalRec = records[i];

            if (result.isSuccess()) {
                insertedRecords.add(originalRec);
            } else {
                String errorMessage = '';
                for(Database.Error err : result.getErrors()) {
                    errorMessage += err.getStatusCode() + ' === ' + err.getMessage() + '|';
                }
                ErrorLoggerService.logInfo('DML Insert Failed for ' + originalRec.getSObjectType() + '; ' + errorMessage, 'DmlService', 'insert', originalRec.Id, 'Apex');
            }
        }
        return insertedRecords;
    }
}