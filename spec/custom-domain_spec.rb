require 'yaml'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/custom-domain.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/custom-domain/apigateway-http.compiled.yaml") }

  context 'Resource HttpApi' do
    let(:properties) { template["Resources"]["HttpApi"]["Properties"] }

    it 'has property Name and Description' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}"})
      expect(properties["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} - Http Api"})
    end

    it 'has property FailOnWarnings' do
      expect(properties["FailOnWarnings"]).to eq(true)
    end

    it 'has property Tags' do
      expect(properties["Tags"]).to eq([
        {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, 
        {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
    end

  end

  context 'Resource Custom Domain' do
    let(:properties) { template["Resources"]["CustomDomain"]["Properties"] }

    it 'has properties' do
        expect(properties).to eq({
            "CertificateArn" => {"Fn::If"=>["HasEdgeCertificateArn", {"Ref"=>"EdgeCertificateArn"}, {"Ref"=>"AWS::NoValue"}]},
            "DomainName" => {"Fn::Sub"=>"api.${EnvironmentName}.${DnsDomain}"},
            "RegionalCertificateArn" => {"Fn::If"=>["HasRegionalCertificateArn", {"Ref"=>"RegionalCertificateArn"}, {"Ref"=>"AWS::NoValue"}]},
            "SecurityPolicy" => "TLS_1_2",
            "Tags" => [{"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}],
        })
    end
  end

  context 'Resource Base Path Mapping' do
    let(:properties) { template["Resources"]["BasePathMapping"]["Properties"] }

    it 'has properties' do
        expect(properties).to eq({
            "BasePath" => "api",
            "DomainName" => {"Ref"=>"CustomDomain"},
            "HttpApiId" => {"Ref"=>"HttpApi"},
            "Stage" => {"Ref"=>"HttpApiStage"},
        })
    end
  end
end