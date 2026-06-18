param containerGroupName string = 'smsflow-sql-api-worker'
param location string = resourceGroup().location
param image string = 'YOUR_REGISTRY/smsflow-sql-api-worker:0.1.0'
@secure()
param sqlConnectionString string
param portalMode string = 'Simulated'
@secure()
param portalBaseUrl string = ''
@secure()
param apiKey string = ''

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: containerGroupName
  location: location
  properties: {
    osType: 'Linux'
    restartPolicy: 'Always'
    containers: [
      {
        name: 'worker'
        properties: {
          image: image
          resources: {
            requests: {
              cpu: 1
              memoryInGB: 2
            }
          }
          environmentVariables: [
            {
              name: 'SMSFLOW_SQL_INTEGRATION_ROOT'
              value: '/smsflow'
            }
            {
              name: 'SqlIntegrationV2__ConnectionString'
              secureValue: sqlConnectionString
            }
            {
              name: 'SqlIntegrationV2__PortalMode'
              value: portalMode
            }
            {
              name: 'SqlIntegrationV2__PortalBaseUrl'
              secureValue: portalBaseUrl
            }
            {
              name: 'SqlIntegrationV2__ApiKey'
              secureValue: apiKey
            }
          ]
        }
      }
    ]
  }
}
