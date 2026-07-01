# Salesforce source connector fails after upgrading to 3.1.1

If you upgrade IBM Connectivity Pack from 3.1.0 to 3.1.1, the Salesforce source connector might fail to start because the `updatedField` subscription parameter is no longer supported.


## Symptoms

After upgrading Connectivity Pack from 3.1.0 to 3.1.1, the Salesforce source connector fails to start and the Kafka Connect pod logs display an error similar to the following:

```json
{
  "message": "The provided data for the \"Employee__c\" object isn't in the correct format for the application. Ensure that the provided data for the operation is valid. Ensure that the properties of the object comply with the definition in the OpenAPI document.",
  "error_details": "instance.options.subscription options.subscription is not allowed to have the additional property \"updatedField\""
}
```

## Causes

Connectivity Pack 3.1.1 removes the `updatedField` parameter from the Salesforce source connector subscription configuration. Connector configurations that include this parameter are incompatible with the updated configuration schema.

## Resolving the problem
Complete the following steps to update the connector configuration:

1. Remove the `updatedField` parameter from every `KafkaConnector` custom resource where it is configured. The parameter uses the following format:

   ```yaml
   connectivitypack.source.<object>.<event>.subscription.updatedField
   ```
   For example, `connectivitypack.source.Employee__c.CREATED_POLLER.subscription.updatedField: LastModifiedDate`.

  Apply the updated connector configuration.

1. Verify the connector status in the `KafkaConnector` custom resource and ensure that the connector state is `RUNNING`.

