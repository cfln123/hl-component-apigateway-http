CfhighlanderTemplate do

  Name 'apigateway-http'
  Description "#{component_name} - #{component_version} - (#{template_name}@#{template_version})"

  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', allowedValues: ['development','production'], isGlobal: true
    ComponentParam 'DnsDomain', description: 'the root DNS Name'
    ComponentParam 'CertificateArn', description: 'the EDGE Cert Arn'
  end

end