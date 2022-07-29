CloudFormation do

  tags = external_parameters.fetch(:tags, {})
  default_tags = []
  default_tags.push({ Key: 'Environment', Value: Ref(:EnvironmentName) })
  default_tags.push({ Key: 'EnvironmentType', Value: Ref(:EnvironmentType) })
  default_tags.push(*tags.map {|k,v| {Key: FnSub(k), Value: FnSub(v)}})
  default_tags = default_tags.map{ |t| [t[:Key], t[:Value]] }.to_h

  Condition(:HasDomainName, FnNot(FnEquals(Ref(:CertificateArn),'')))

  security_policy = external_parameters.fetch(:security_policy, 'TLS_1_2')
  dns_format = external_parameters.fetch(:dns_format, "${EnvironmentName}.${DnsDomain}")
  custom_dns_prefix = external_parameters.fetch(:custom_dns_prefix, 'api')
  endpoint_configuration = external_parameters.fetch(:endpoint_configuration, {})

  ApiGatewayV2_DomainName(:CustomDomain) {
    Condition(:HasDomainName)
    DomainName FnSub("#{custom_dns_prefix}.#{dns_format}")
    DomainNameConfigurations([{
      EndpointType: "REGIONAL",
      CertificateArn: Ref(:CertificateArn),
      CertificateName: "CustomDomainCertificate",
      SecurityPolicy: security_policy
    }])
    Tags default_tags
  }

  Route53_RecordSet(:DNSRecord) {
    Condition(:HasDomainName)
    HostedZoneName FnSub("#{dns_format}.")
    Name FnSub("#{custom_dns_prefix}.#{dns_format}.")
    Type 'A'
    AliasTarget({
      DNSName: FnGetAtt('CustomDomain','RegionalDomainName'),
      EvaluateTargetHealth: 'true',
      HostedZoneId: FnGetAtt('CustomDomain','RegionalHostedZoneId')
    })
  }
  
  api_name = external_parameters.fetch(:api_name, '${EnvironmentName}')
  api_description = external_parameters.fetch(:api_description, '${EnvironmentName} - Http Api')
  api_key_source_type = external_parameters.fetch(:api_key_source_type, nil)
  binary_media_types = external_parameters.fetch(:binary_media_types, nil)
  body_s3_location = external_parameters.fetch(:body_s3_location, nil)
  fail_on_warnings = external_parameters.fetch(:fail_on_warnings, true)
  minimum_compression_size = external_parameters.fetch(:minimum_compression_size, nil)
  header_parameters = external_parameters.fetch(:header_parameters, nil)
  endpoint_configuration = external_parameters.fetch(:endpoint_configuration, {})

  api_path_prefix = external_parameters.fetch(:api_path_prefix, nil)

  api_body_file = external_parameters.fetch(:api_body_file, '')
  if File.exists?(api_body_file)
    api_body = File.read(api_body_file)
  else
    api_body = nil
  end

  stage_name = external_parameters.fetch(:stage_name, 'default')
  stage_variables = external_parameters.fetch(:stage_variables, nil)

  # if !api_body.nil? && !body_s3_location.nil?
  #   raise "Set either api_body or body_s3_location"
  # end

  ApiGatewayV2_Api(:HttpApi) {
    Name FnSub("#{api_name}")
    Description FnSub("#{api_description}")
    ApiKeySourceType FnSub(api_key_source_type) unless api_key_source_type.nil?
    BinaryMediaTypes binary_media_types unless binary_media_types.nil?
    Body api_body unless api_body.nil?
    BodyS3Location({
      Bucket: FnSub(body_s3_location['bucket']),
      Key: FnSub(body_s3_location['key'])
    }) unless body_s3_location.nil?
    EndpointConfiguration {
      Types endpoint_configuration['types']
    } unless endpoint_configuration.empty?
    FailOnWarnings fail_on_warnings unless (api_body.nil? && body_s3_location.nil?)
    MinimumCompressionSize minimum_compression_size unless minimum_compression_size.nil?
    Parameters header_parameters unless header_parameters.nil?
    ProtocolType 'HTTP'
    Tags default_tags
  }

  Output(:HttpApiId) {
    Value(Ref(:HttpApi))
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-HttpApiId")
  }

  default_route = external_parameters.fetch(:default_route, '$default')

  ApiGatewayV2_Stage(:HttpApiStage) {
    ApiId Ref(:HttpApi)
    StageName FnSub("#{stage_name}")
    AutoDeploy true
    Variables stage_variables unless stage_variables.nil?
    Tags default_tags
  }

  Output(:HttpApiStage) {
    Value(Ref(:HttpApiStage))
    Export FnSub("${EnvironmentName}-#{external_parameters[:component_name]}-HttpApiStage")
  }

  api_key = external_parameters.fetch(:api_key, {})
  if !api_key.empty?
    ApiGatewayV2_ApiKey(:ApiKey) {
      Name FnSub('${EnvironmentName}')
      Description FnSub('${EnvironmentName} API Key')
      Enabled true
      Value api_key['key_value']
      StageKeys [{
        HttpApiId: Ref(:HttpApi),
        StageName: Ref(:HttpApiStage)
      }]
      Tags default_tags
    }

    throttle_settings = api_key['throttle_settings'].transform_keys {|k| k.split('_').collect(&:capitalize).join }
    quota = api_key['quota']
    quota = quota.transform_keys {|k| k.split('_').collect(&:capitalize).join } unless quota.nil?
    ApiGatewayV2_UsagePlan(:UsagePlan) {
      UsagePlanName FnSub("${EnvironmentName}")
      Throttle throttle_settings unless throttle_settings.nil?
      Quota quota unless quota.nil?
      ApiStages [{
        ApiId: Ref(:HttpApi),
        Stage: Ref(:HttpApiStage)
      }]
      Tags default_tags
    }

    ApiGatewayV2_UsagePlanKey(:UsagePlanKey) {
      KeyId Ref(:ApiKey)
      KeyType 'API_KEY'
      UsagePlanId Ref(:UsagePlan)
    }
  end

end

