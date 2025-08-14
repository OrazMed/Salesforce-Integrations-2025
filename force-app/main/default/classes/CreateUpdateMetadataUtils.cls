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
}