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

    public static void createUpdateMetadata(String fullName, String label, Map<String, Object> fieldWithValuesMap) {
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
        
        CreateUpdateMetadataUtils callback = new CreateUpdateMetadataUtils();
        Id jobId = Metadata.Operations.enqueueDeployment(container, callback);
        return jobId;
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
}