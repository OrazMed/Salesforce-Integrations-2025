/*
    Use Metadata NameSpace to deploy/update the Custom Metadata Record
    TODO: Using Metadata.DeployCallback interface
*/
public class CreateUpdateMetadataUtils implements Metadata.DeployCallback {
    
    public static final String JOB_ID = '';

    public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
        if (result.status == Metadata.DeployStatus.Succeeded) {
            // Deployment was successful
            System.debug('SUCCESS : ' + result);
        } else {
            // Deployment was not successful
            System.debug('ERROR : ' + result);
        }
    }

    public static String createUpdateMetadata(String fullName, String label, Map<String, Object> fieldWithValuesMap) {
        // Setup custom metadata to be created in the subscriber org.
        Metadata.CustomMetadata customMetadata =  new Metadata.CustomMetadata();
        customMetadata.fullName = fullName; // CustomMetadataObjectName.ConfigAPiName = Salesforce_Config.SalesforceToken
        customMetadata.label = label; // Label

        for(String key : fieldWithValuesMap.keySet()) {

            Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue();
            customField.field = key;
            customField.value = fieldWithValuesMap.get(key);

            customMetadata.values.add(customField);
        }

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(customMetadata);

        // Setup deploy callback, MyDeployCallback implements the Metadata.DeployCallback interface
        CreateUpdateMetadataUtils callback = new CreateUpdateMetadataUtils();

        // Enqueue custom metadata deployment
        Id jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        return jobId;
    }


    @AuraEnabled(cacheable=true)
    public static String deployMetadataRecords(String metadataType, String recordsJson) {
        System.debug('metadataType === ' + metadataType);
        System.debug('recordsJson === ' + recordsJson);

        // List<MetadataRecordWrapper> records = (List<MetadataRecordWrapper>)JSON.deserialize(recordsJson, List<MetadataRecordWrapper>.class);
        List<Object> records = (List<Object>)JSON.deserializeUntyped(recordsJson);
        Metadata.DeployContainer container = new Metadata.DeployContainer();
        List<String> jobIds = new List<String>();
        System.debug('records === ' + records);

        for (Object untypedRec : records) {
            
            // Step 3: Cast each individual object into a Map. This is safe and reliable.
            Map<String, Object> recMap = (Map<String, Object>) untypedRec;
            System.debug('Processing Record Map === ' + recMap);

            // Step 4: Get the required fields from the map.
            String recordLabel = (String) recMap.get('Label');
            String recordDevName = (String) recMap.get('DeveloperName');

            // Server-side validation
            if (String.isBlank(recordLabel)) {
                throw new AuraHandledException('A record was found with a blank Label. Every record must have a Label.');
            }

            Metadata.CustomMetadata customMetadata = new Metadata.CustomMetadata();
            customMetadata.fullName = metadataType + '.' + recordDevName;
            customMetadata.label = recordLabel;

            // Step 5: DYNAMICALLY loop over all keys in the map to find and add the custom fields.
            // This is the key to making the component truly generic.
            for (String fieldName : recMap.keySet()) {
                
                // We only process custom fields here. Label and DeveloperName are handled above.
                if (fieldName.endsWith('__c')) {
                    Object fieldValue = recMap.get(fieldName);
                    // The helper method adds the value to the deployment package.
                    addMetadataValue(customMetadata, fieldName, fieldValue);
                }
            }
            
            container.addMetadata(customMetadata);
        }

        /*
        for(MetadataRecordWrapper rec : records) {
            System.debug('Record details ===> \n ' + rec);
            Metadata.CustomMetadata cusMetadata = new Metadata.CustomMetadata();
            String devName = rec.developerName;
            devName = devName.replaceAll('[^a-zA-Z0-9]', '_');
            cusMetadata.fullName = metadataType + '.' + devName;
            String fullName = metadataType + '.' + devName;
            cusMetadata.label = rec.label;
            String label = rec.label;
            /*Map<String, Object> fieldWithValuesMap = new Map<String, Object>();
            fieldWithValuesMap.put('Flag_Emoji__c', rec.flag);
            fieldWithValuesMap.put('ISO_Alpha_2__c', rec.isoAlpha2);
            fieldWithValuesMap.put('ISO_alpha_3__c', rec.isoAlpha3);
            fieldWithValuesMap.put('Currency_Code__c', rec.currencyCode);
            fieldWithValuesMap.put('Currency_Symbol__c', rec.currencySymbol);
            fieldWithValuesMap.put('Latitude__c', rec.latitude);
            fieldWithValuesMap.put('Longitude__c', rec.longitude);

            addMetadataValue(cusMetadata, 'Flag_Emoji__c', rec.flag);
            addMetadataValue(cusMetadata, 'ISO_Alpha_2__c', rec.isoAlpha2);
            addMetadataValue(cusMetadata, 'ISO_alpha_3__c', rec.isoAlpha3);
            addMetadataValue(cusMetadata, 'Currency_Code__c', rec.currencyCode);
            addMetadataValue(cusMetadata, 'Currency_Symbol__c', rec.currencySymbol);
            addMetadataValue(cusMetadata, 'Latitude__c', rec.latitude);
            addMetadataValue(cusMetadata, 'Longitude__c', rec.longitude);
            
            container.addMetadata(cusMetadata);
            // jobIds.add(createUpdateMetadata(fullName, label,  fieldWithValuesMap));
        }*/
        
        CreateUpdateMetadataUtils callback = new CreateUpdateMetadataUtils();
        Id jobId = Metadata.Operations.enqueueDeployment(container, callback);
        return jobId;
        //return jobIds;
    }


    public static void addMetadataValue(Metadata.CustomMetadata cm, String label, Object value) {
        Metadata.CustomMetadataValue customField = new Metadata.CustomMetadataValue ();
        customField.field = label;
        customField.value = value;
        cm.values.add(customField);
    }


    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getMetadataTypes() {
        List<Map<String, String>> options = new List<Map<String, String>>();

        options.add(new Map<String, String>{
                'label' => '--Select a Metadata Type--',
                'value' => ''
        });
        options.add(new Map<String, String>{
                'label' => 'Country Data',
                'value' => 'Country_Data__mdt'
        });

        return options;
    }

    
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getMetadataRecordsAndFields(String metadataType) {
        if(String.isBlank(metadataType)) {
            return null;
        }

        Map<String, Object> response = new Map<String, Object>();
        List<String> fieldNames = new List<String>();
        List<Map<String, Object>> columns = new List<Map<String, Object>>();

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(metadataType).getDescribe().fields.getMap();

        for(Schema.SObjectField field : fieldMap.values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            String currentFieldName = fieldDescribe.getName();
            Boolean isEssentialStandardField = currentFieldName.equalsIgnoreCase('Label') || currentFieldName.equalsIgnoreCase('DeveloperName');

            if(fieldDescribe.isAccessible() && (fieldDescribe.isCustom() || isEssentialStandardField)) {
                fieldNames.add(fieldDescribe.getName());

                Map<String, Object> col = new Map<String, Object>();
                col.put('label', fieldDescribe.getLabel());
                col.put('fieldName', fieldDescribe.getName());
                col.put('type', getDatatableType(fieldDescribe.getType()));

                if(fieldDescribe.getName().equalsIgnoreCase('DeveloperName')) {
                    col.put('editable', false);
                    col.put('cellAttributes', new Map<String, Object>{ 'class' => 'slds-theme_shade' });
                } else {
                    col.put('editable', true);
                }

                if(getDatatableType(fieldDescribe.getType()) == 'number') {
                    col.put('typeAttributes', new Map<String, Object>{ 'step' => '0.00001'});
                }

                columns.add(col);
            }
        }

        if(!fieldNames.isEmpty()) {
            String query = 'SELECT  ' + String.join(fieldNames, ',') + ' FROM ' + String.escapeSingleQuotes(metadataType);
            response.put('records', Database.query(query));
        } else {
            response.put('records', new List<Object>());
        }
        response.put('columns', columns);
        return response;

        /*Map<String, Object> response = new Map<String, Object>();
        String query = 'SELECT Label, DeveloperName, ISO_alpha_3__c, ISO_alpha_2__c, Currency_Code__c, Currency_Symbol__c, Flag_Emoji__c, Latitude__c, Longitude__c FROM ' + String.escapeSingleQuotes(metadataType);

        List<Map<String, Object>> columns = new List<Map<String, Object>>{
            new Map<String, Object>{'label' => 'Label', 'fieldName' => 'Label', 'type' => 'text', 'editable' => true},
            new Map<String, Object>{'label' => 'DeveloperName', 'fieldName' => 'DeveloperName', 'type' => 'text', 'editable' => false, 'cellAttributes' => new Map<String, Object>{'class' => 'slds-theme_shade'}},
            new Map<String, Object>{'label' => 'Flag', 'fieldName' => 'Flag_Emoji__c', 'type' => 'text', 'editable' => true},
            new Map<String, Object>{'label' => 'ISO Apha-2', 'fieldName' => 'ISO_alpha_2__c', 'type' => 'text', 'editable' => true},
            new Map<String, Object>{'label' => 'ISO Apha-3', 'fieldName' => 'ISO_alpha_3__c', 'type' => 'text', 'editable' => true},
            new Map<String, Object>{'label' => 'Currency Code', 'fieldName' => 'Currency_Code__c', 'type' => 'text', 'editable' => true},
            new Map<String, Object>{'label' => 'Currency Symbol', 'fieldName' => 'Currency_Symbol__c', 'type' => 'text', 'editable' => true},
            new Map<String, Object>{'label' => 'Latitude', 'fieldName' => 'Latitude__c', 'type' => 'number', 'editable' => true, 'typeAttributes' => new Map<String, Object>{ 'step' => '0.0000001'}},
            new Map<String, Object>{'label' => 'Longitude', 'fieldName' => 'Longitude__c', 'type' => 'number', 'editable' => true, 'typeAttributes' => new Map<String, Object>{ 'step' => '0.0000001'}}
        };

        response.put('records', Database.query(query));
        response.put('columns', columns);

        return response;*/
    }


    private static String getDatatableType(DisplayType fieldType) {
        switch on fieldType {
            when STRING, PICKLIST, TEXTAREA, EMAIL, URL, PHONE {
                return 'text';
            }
            when DOUBLE, INTEGER, CURRENCY, PERCENT {
                return 'number';
            }
            when BOOLEAN {
                return 'boolean';
            }
            when DATE {
                return 'date-local';
            }
            when DATETIME {
                return 'date';
            }
            when else {
                return 'text';
            }
        }
    }


    public class MetadataRecordWrapper {
        @AuraEnabled public String label;
        @AuraEnabled public String developerName;
        @AuraEnabled public String flag;
        @AuraEnabled public String isoAlpha2;
        @AuraEnabled public String isoAlpha3;
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String currencySymbol;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public Decimal longitude;
    }
}