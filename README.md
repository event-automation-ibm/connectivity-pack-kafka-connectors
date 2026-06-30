# Connectivity Pack Kafka connectors

By using the IBM Connectivity Pack, Connectivity Pack Kafka connectors enable data streaming between external systems and Kafka.

**Note:**  
- Connectivity Pack v2.0.0 and earlier are compatible with Event Streams 11.8 and earlier, but not compatible with Kafka Connect 4.0.0.
- Connectivity Pack v3.0.0 and later are compatible with Event Streams 12.0.0 and later, and compatible with Kafka Connect 4.0.0.

## Contents

- [Prerequisites](#prerequisites)
- [Installing the IBM Connectivity Pack](#installing-the-ibm-connectivity-pack)
- [Upgrading the Connectivity Pack](#upgrading-the-connectivity-pack)
- [Starting Kafka Connect](#starting-kafka-connect)
- [Running the connectors](#running-the-connectors)
- [License](#license)

## Prerequisites

To run Connectivity Pack Kafka connectors, ensure you have:

- IBM Event Streams installed, and you have the bootstrap address, an image pull secret called [`ibm-entitlement-key`](https://ibm.github.io/event-automation/es/installing/installing/#creating-an-image-pull-secret), certificates, and credentials required to access Kafka.
- The external system (for example, Salesforce) configured according to the [system-specific guidance](./systems/), with the required URLs and credentials to access the system.

  For information about the supported systems, see the [systems](./systems/) folder.

- Either enabled [auto-creation of Kafka topics](https://ibm.github.io/event-automation/es/connecting/setting-up-connectors/#enabling-topic-creation-for-connectors) or pre-created all the required Kafka topics in the format that must be specified in the `connectivitypack.topic.name.format` section of the [`KafkaConnector` custom resource](#running-the-connectors).


## Installing the IBM Connectivity Pack

The Connectivity Pack acts as an interface between Kafka Connect connectors and external systems you want to connect to. It can be deployed on OpenShift and other Kubernetes platforms by using the Connectivity Pack Helm chart.

To install the Connectivity Pack, run the following command:

```bash
helm install <RELEASE-NAME> <CONNECTIVITY-PACK-HELM-CHART-URL> --set license.licenseId=<LICENSE-ID>,license.accept=true -n <NAMESPACE>
```

Where:

- `<RELEASE-NAME>` is the release name of your choice. For example, `ibm-connectivity-pack`
- `<CONNECTIVITY-PACK-HELM-CHART-URL>` is the URL of the latest version of the Connectivity Pack Helm chart. For example: `https://github.com/ibm-messaging/connectivity-pack-kafka-connectors/releases/download/3.1.1/ibm-connectivity-pack-3.1.1.tgz`
- `license.licenseId=<LICENSE-ID>` is the license identifier (ID) for the program that you purchased. For more information, see [licensing reference](https://ibm.github.io/event-automation/support/licensing/).
- `license.accept` determines whether the license is accepted (default is `false` if not specified).
- `<NAMESPACE>` is the namespace where you want to install the Connectivity Pack. This must be in the same namespace where an Event Streams instance is deployed.

You can override the default configuration parameters by using the `--set` flag or by using a custom YAML file. For example, to set the `replicaCount` as `3`, you can use `--set replicaCount=3`.

For more information about installing the Connectivity Pack, including a complete list of configuration parameters supported by the Helm chart, see [installing the Connectivity Pack](./ibm-connectivity-pack/README.md#configuring).

## Upgrading the Connectivity Pack

If you are using an earlier version of Connectivity Pack, you can upgrade to the latest version. 

## Upgrade paths

The upgrade path for Connectivity Pack depends on the version of IBM Event Streams you are using:

- **Connectivity Pack v2.0.0 and earlier**: Compatible with Event Streams 11.8 and earlier. Not compatible with Kafka Connect 4.0.0.
- **Connectivity Pack v3.0.0 and later**: Compatible with Event Streams 12.0.0 and later, and compatible with Kafka Connect 4.0.0.

When upgrading from Connectivity Pack v2.x to v3.x, ensure that your Event Streams instance is also upgraded to version 12.0.0 or later before upgrading the Connectivity Pack.


**Important:** If you are upgrading from Connectivity Pack 3.1.0 to 3.1.1, the Salesforce Connector no longer supports the `updatedField` parameter in the subscription configuration. Remove this parameter from your connector configuration before upgrading to avoid errors. For more information, see the [troubleshooting documentation](./troubleshooting/upgrading-3.1.0-to-3.1.1.md).

### Upgrade by using Helm

Run the following command to upgrade your Connectivity Pack installation:

```bash
helm upgrade <RELEASE-NAME> <CONNECTIVITY-PACK-HELM-CHART-URL> -n <NAMESPACE>
```
For example:
```bash
helm upgrade ibm-connectivity-pack ibm-connectivity-pack-3.1.1.tgz -n deploy-es-scram-nocs
```

Where:

- `<RELEASE-NAME>` is the existing release name of your Connectivity Pack installation. For example, `ibm-connectivity-pack`
- `<CONNECTIVITY-PACK-HELM-CHART-URL>` is the URL or path to the Helm chart package for the version that you want to upgrade to. For example, `https://github.com/ibm-messaging/connectivity-pack-kafka-connectors/releases/download/3.1.1/ibm-connectivity-pack-3.1.1.tgz` or a local file path such as `ibm-connectivity-pack-3.1.1.tgz`.
- `<NAMESPACE>` is the namespace where the Connectivity Pack is currently installed. This must be the same namespace where your Event Streams instance is deployed.

## Starting Kafka Connect

Configure the Kafka Connect runtime and include the configuration, certificates, and connectors for the Connectivity Pack by following these instructions.

**Note:** For more information, see [setting up connectors](https://ibm.github.io/event-automation/es/connecting/setting-up-connectors/).

1. Create a `KafkaConnect` custom resource to define the Kafka Connect runtime. Example custom resource files are available in the [`examples`](/examples) folder. You can edit these files based on your requirements and configure the following settings.


    - To use the pre-built connector JAR file, set the URL of the [latest release asset](https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/eventstreams/connectors/connectivitypack/) as the value for `spec.build.plugins[].artifacts[].url` as shown in the following example:

      ```yaml
      plugins:
        - name: connectivitypack-connector
          artifacts:
          - type: jar
            url: https://public.dhe.ibm.com/ibmdl/export/pub/software/websphere/messaging/eventstreams/connectors/connectivitypack/<VERSION>/connectivity-pack-connector-<VERSION>-jar-with-dependencies.jar
      ```

        Where `<VERSION>` is the version of the Connectivity Pack connector JAR file.

    - To use the installed Connectivity Pack with `<RELEASE-NAME>`, update the `spec.template` section with the following configuration and certificates:

      - If you are using Event Streams version 11.5.2 and later, use the following configuration:

        ```yaml
        template:
          connectContainer:
            env:
              - name: CONNECTIVITYPACK_SERVICE_URL
                valueFrom:
                  configMapKeyRef:
                    key: CONNECTIVITYPACK_SERVICE_URL
                    name: <RELEASE-NAME>-config
            volumeMounts:
              - mountPath: /mnt/connectivitypack/certificates
                name: connectivitypack-certs
          pod:
            volumes:
              - name: connectivitypack-certs
                secret:
                  secretName: <RELEASE-NAME>-client-certificate
        ```

      - If you are using earlier versions of Event Streams than 11.5.2, use the following `externalConfiguration`:

        ```yaml
        externalConfiguration:
          env:
            - name: CONNECTIVITYPACK_SERVICE_URL
              valueFrom:
                configMapKeyRef:
                  key: CONNECTIVITYPACK_SERVICE_URL
                  name: <RELEASE-NAME>-config
          volumes:
            - name: connectivitypack-certs
              secret:
                secretName: <RELEASE-NAME>-client-certificate
        ```

        Where `<RELEASE-NAME>` is the Helm release name for your Connectivity Pack installation.

    - The following section explains the environment variables that are used in the Kafka Connect configuration:

        - **`CONNECTIVITYPACK_SERVICE_URL`**: The URL of the Connectivity Pack that the Kafka connector uses to connect. For example:

          ```yaml
          CONNECTIVITYPACK_SERVICE_URL: <connectivity-service-url>
          ```

          You can set this URL by using a `configMapKeyRef` that points to the ConfigMap of the Connectivity Pack or directly set it to the correct endpoint. Ensure that the URL is accessible from the Kafka Connect container.

        - **`CONNECTIVITYPACK_CERTS_PATH`**: The file path to the directory containing the certificates required for secure communication. This includes the client certificate, private key, and any intermediate certificates that are required for secure communication between the connector and the Connectivity Pack. For example:

          ```yaml
          CONNECTIVITYPACK_CERTS_PATH: /mnt/connectivitypack/certificates
          ```

          By default, this is set to `/mnt/connectivitypack/certificates`. You can optionally specify this environment variable if your certificates are mounted at a different path.

        - **`CONNECTIVITYPACK_PKCS12_PASSWORD`**: The password that is used to access the PKCS12 certificate store. This environment variable is required for secure communication between the connector and the Connectivity Pack only if the PKCS12 file is password-protected. If the PKCS12 file does not have a password, you can set this as an empty string or skip configuring this environment variable. For example:

          ```yaml
          template:
            connectContainer:
              env:
                - name: CONNECTIVITYPACK_PKCS12_PASSWORD
                  value: <your-pkcs12-password>
          ```

1. Apply the configured `KafkaConnect` custom resource by using the `kubectl apply` command to start the Kafka Connect runtime.

1. When Kafka Connect is successfully created, verify that the connector is available for use by checking the `status.connectorPlugins` section in the `KafkaConnect` custom resource. 
   - For the Connectivity Pack source connector to work, the following plug-in must be present:

      ```yaml
      status:
        connectorPlugins:
          - class: com.ibm.eventstreams.connect.connectivitypack.source.ConnectivityPackSourceConnector
          type: source
          version: <version>
      ```
   - For the Connectivity Pack sink connector to work, the following plug-in must be present:

      ```yaml
      status:
        connectorPlugins:
          - class: com.ibm.eventstreams.connect.connectivitypack.sink.ConnectivityPackSinkConnector
          type: sink
          version: <version>
      ```

## Running the Connectors

Configure your connector with information about your external system by following these instructions.

**Note:** For more information, see [setting up connectors](https://ibm.github.io/event-automation/es/connecting/setting-up-connectors/#set-up-a-kafka-connector).

1. Create a `KafkaConnector` custom resource to define your connector configuration. Example custom resources are available in the [`examples`](/examples) folder: [kafka-connector-source.yaml](/examples#kafka-connector-source.yaml) for a source connector and [kafka-connector-sink.yaml](/examples#kafka-connector-sink.yaml) for a sink connector. You can edit these files based on your requirements.

1. Specify the appropriate connector class name:
   - For a source connector: `com.ibm.eventstreams.connect.connectivitypack.source.ConnectivityPackSourceConnector`
   - For a sink connector: `com.ibm.eventstreams.connect.connectivitypack.sink.ConnectivityPackSinkConnector`

1. Configure the connector properties in the `config` section as described in the respective documentation. See the [source connector documentation](./connectors/source-connector.md#configuration) for source connectors and the [sink connector documentation](./connectors/sink-connector.md#configuration) for sink connectors.

   You can find the supported values for your source system in the [source system-specific guidance](./systems/source%20systems) and for your sink system in the [sink system-specific guidance](./systems/sink%20systems).

   Example source connector configuration:

      ```yaml
      config:
      # Which source system to connect to, for example, salesforce
      connectivitypack.source: salesforce

      # URL to access the source system,  for example, `https://<your-instance-name>.salesforce.com`
      connectivitypack.source.url: <URL-of-the-data-source-instance>>

      # Credentials to access the source system using BASIC_OAUTH authentication.
      connectivitypack.source.credentials.authType: BASIC_OAUTH
      connectivitypack.source.credentials.accessTokenBasicOauth: <access-token>
      connectivitypack.source.credentials.refreshTokenBasicOauth: <refresh-token>
      connectivitypack.source.credentials.clientSecret: <client-secret>
      connectivitypack.source.credentials.clientIdentity: <client-identity>

      # Objects and event-types to read from the datasource.
      connectivitypack.source.objects: '<customObject>,<platformEventObject>,<CDCObject>'

      # Specifies the events to capture for the custom object <customObject>. For example, CREATED_POLLER.
      connectivitypack.source.<customObject>.events: 'CREATED_POLLER'
      # Specifies the events to capture for the platform event object <platformEventObject>. For example, CREATED.
      connectivitypack.source.<platformEventObject>.events: 'CREATED'
      # Specifies the events to capture for the CDC object <CDCObject>. 
      connectivitypack.source.<CDCObject>.events: 'UPDATED'

      # Subscription params applicable only for poller events
      connectivitypack.source.<customObject>.CREATED_POLLER.subscription.pollingInterval: <pollingInterval>
      connectivitypack.source.<customObject>.CREATED_POLLER.subscription.updatedField: <the field name that contains the timestamp of when the object was updated> # `updatedField` parameter is not supported in Connectivity Pack 3.1.1 and later.
      connectivitypack.source.<customObject>.CREATED_POLLER.subscription.createdField: <the field name that contains the timestamp of when the object was created>

      # Optional, sets the format for Kafka topic names created by the connector.
      # You can use placeholders like '${object}' and '${eventType}', which the connector will replace automatically.
      # Including '${object}' or '${eventType}' in the format is optional. For example, '${object}-topic-name' is a valid format.
      # By default, the format is '${object}-${eventType}', but it's shown here for clarity.
      connectivitypack.topic.name.format: '${object}-${eventType}'

      # Specifies the converter class used to deserialize the message value.
      # Change this to a different converter (for example, AvroConverter) if needed.
      value.converter: org.apache.kafka.connect.json.JsonConverter

      # Controls whether the schema is included in the message.
      # Set this to false to disable schema support, or to true to enable schema inclusion (for example, for Avro).
      value.converter.schemas.enable: false
      # Optional, set the topic for producing the heartbeat events.
      connectivitypack.source.heartbeat.topic: heartbeat-${topic}
      
      ```

   Example sink connector configuration:

      ```yaml
      config:
      # Which sink system to connect to, for example, Google Big Querry
      connectivitypack.sink: googlebigquery

      # Credentials to access the sink system
      connectivitypack.sink.authType: BASIC
      connectivitypack.sink.credentials.clientEmail: <clientEmail>
      connectivitypack.sink.credentials.projectId: <projectId>
      connectivitypack.sink.credentials.datasetId: <datasetId>
      connectivitypack.sink.credentials.privateKey: <privateKey>

      # In this case, the table to which data is inserted into
      connectivitypack.sink.object: <table-name>
      # The action which is performed on the object. For example, INSERT
      connectivitypack.sink.action: INSERT
      # The topic from which events are read from
      topics: <topic-name>

      # Optional, Single Message transformations (SMTs)
      transforms: 'RenameFields,FilterFields,CastFields'
      transforms.FilterFields.type: org.apache.kafka.connect.transforms.ReplaceField$Value
      transforms.RenameFields.type: org.apache.kafka.connect.transforms.ReplaceField$Value
      # Mapping of <filed name in Kafka topic record : column name in Google BigQuery Table>
      transforms.RenameFields.renames: <field name 1 in Kafka topic record:column name 1 in table, field name 2 in Kafka topic record:column name 2 in table>
      # List of fields to be excluded from inserting to the table
      transforms.FilterFields.exclude: <list of comma separated fields need to be excluded>
      transforms.CastFields.type: org.apache.kafka.connect.transforms.Cast$Value
      # Casting required for numeric data types.
      transforms.CastFields.spec: 'salary:string'
   
      # For handling bad records
      errors.tolerance: all
      errors.log.enable: true
      ```

1. Apply the configured `KafkaConnector` custom resource by using the `kubectl apply` command to start the connector.
1. Verify that the connector is running by checking the `status` section in the `KafkaConnector` custom resource:

   ```yaml
   Status:
    Conditions:
       Last Transition Time: 2024-07-13T07:56:40.943007974Z
       Status:               True
       Type:                 Ready
    Connector Status:
       Connector:
         State:      RUNNING
   ```

## License

Copyright IBM Corp. 2025

IBM Connectivity Pack is licensed under the [IBM Event Automation license, IBM Cloud Pak for Integration license, and IBM webMethods Hybrid Integration license](https://ibm.biz/ea-license), while the Helm chart and documentation are licensed under the [Apache License, Version 2.0](./ibm-connectivity-pack/license.md).