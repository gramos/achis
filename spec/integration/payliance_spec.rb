require 'spec_helper'
require 'achis/providers/payliance'
require 'integration/shared_examples_for_providers'

describe Achis::Providers::Payliance, :integration => true do

  let(:provider_args) do
    { host: ENV['PAYLIANCE_HOST'],
      username: ENV['PAYLIANCE_USERNAME'],
      password: ENV['PAYLIANCE_PASSWORD'],
      store_id: ENV['PAYLIANCE_STORE_ID'],
      client_id: ENV['PAYLIANCE_CLIENT_ID'],
      location_id: ENV['PAYLIANCE_LOCATION_ID'],
      cyber_location_id: ENV['PAYLIANCE_CYBER_LOCATION_ID'] }
  end

  before do
    def subject.returns_path
      '/test'
    end

    def subject.push_remote_file_path
      "/test/#{file_name}"
    end
  end

  it_behaves_like 'a provider'
end
