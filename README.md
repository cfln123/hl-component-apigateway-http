# apigateway-http CfHighlander component

## Build status
![cftest workflow](https://github.com/theonestack/hl-component-apigateway-http/actions/workflows/rspec.yaml/badge.svg)
## Parameters

| Name | Use | Default | Global | Type | Allowed Values |
| ---- | --- | ------- | ------ | ---- | -------------- |
| EnvironmentName | Tagging | dev | true | String
| EnvironmentType | Tagging | development | true | String | ['development','production']
| DomainName | The fully qualified domain name (FQDN), such as www.example.com, with which you want to secure an ACM certificate | | false | string
| EdgeCertificateArn | The ACM cert ARN created in us-east-1 | | false | String
| RegionalCertificateArn | The regional ACM cert ARN | | false | String
| NetworkLoadBalander | The ARN of a NLB for creating a VPC Link for this API Gateway | | false | String

## Outputs/Exports

| Name | Value | Exported |
| ---- | ----- | -------- |
| HttpApiId | HttpApiId | true
| HttpApiStage | HttpApiStage | true

## Included Components
<none>

## Example Configuration
### Highlander
```
  Component name: 'apigateway', template: 'apigateway-http' do
    parameter name: 'VPCId', value: root_domain
    parameter name: 'EdgeCertificateArn', value: cfout('acmv2', 'CertificateArn')
    parameter name: 'RegionalCertificateArn', value: cfout('acmv2', 'CertificateArn')
  end
```
### API Gateway (Http) Configuration
```
api_name: 'app1_api'

```
## Cfhighlander Setup

install cfhighlander [gem](https://github.com/theonestack/cfhighlander)

```bash
gem install cfhighlander
```

or via docker

```bash
docker pull theonestack/cfhighlander
```
## Testing Components

Running the tests

```bash
cfhighlander cftest efs-v2
```