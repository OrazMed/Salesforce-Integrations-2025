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


    @AuraEnabled
    public static String deployMetadataRecords(String metadataType, String recordsJson) {
        // List<Map<String, Object>> records = (List<Map<String, Object>>)JSON.deserialize(recordsJson, List<Map<String, Object>>.class);
        // System.debug('records === ' + records);
        List<MetadataRecordWrapper> records = (List<MetadataRecordWrapper>)JSON.deserialize(recordsJson, List<MetadataRecordWrapper>.class);
        Metadata.DeployContainer container = new Metadata.DeployContainer();

        for(MetadataRecordWrapper rec : records) {
            Metadata.CustomMetadata cusMetadata = new Metadata.CustomMetadata();
            String devName = rec.developerName;
            devName = devName.replaceAll('[^a-zA-Z0-9]', '_');
            cusMetadata.fullName = metadataType + '.' + devName;
            addMetadataValue(cusMetadata, 'Flag_Emoji__c', rec.flag);
            addMetadataValue(cusMetadata, 'ISO_Alpha_2__c', rec.isoAlpha2);
            addMetadataValue(cusMetadata, 'ISO_alpha_3__c', rec.isoAlpha3);
            addMetadataValue(cusMetadata, 'Currency_Code__c', rec.currencyCode);
            addMetadataValue(cusMetadata, 'Currency_Symbol__c', rec.currencySymbol);
            addMetadataValue(cusMetadata, 'Latitude__c', rec.latitude);
            addMetadataValue(cusMetadata, 'Longitude__c', rec.longitude);
            
            container.addMetadata(cusMetadata);
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

        return response;
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