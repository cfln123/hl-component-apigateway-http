require 'yaml'

describe 'compiled component' do
  
  context 'cftest' do
    it 'compiles test' do
      expect(system("cfhighlander cftest #{@validate} --tests tests/api-key.test.yaml")).to be_truthy
    end      
  end
  
  let(:template) { YAML.load_file("#{File.dirname(__FILE__)}/../out/tests/api-key/apigateway-http.compiled.yaml") }

  context 'Resource ApiKey' do
    let(:properties) { template["Resources"]["ApiKey"]["Properties"] }

    it 'has property Name and Description' do
      expect(properties["Name"]).to eq({"Fn::Sub"=>"${EnvironmentName}"})
      expect(properties["Description"]).to eq({"Fn::Sub"=>"${EnvironmentName} API Key"})
    end

    it 'has property Value' do
      expect(properties["Value"]).to eq("{{resolve:ssm-secure:MY_API_KEY_VALUE:1}}")
    end

    it 'has property StageKeys' do
      expect(properties["StageKeys"]).to eq([{
        "HttpApiId"=>{"Ref"=>"HttpApi"}, 
        "StageName"=>{"Ref"=>"HttpApiStage"}
      }])
    end

    it 'has property Tags' do
      expect(properties["Tags"]).to eq([
        {"Key"=>"Environment", "Value"=>{"Ref"=>"EnvironmentName"}}, 
        {"Key"=>"EnvironmentType", "Value"=>{"Ref"=>"EnvironmentType"}}])
    end

  end
end