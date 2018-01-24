require 'spec_helper'
require 'achis/providers/sarf'
require 'integration/shared_examples_for_providers'

describe Achis::Providers::SARF, :integration => true do

  let(:provider_args) do
    {
      host: ENV['SARF_HOST'],
      username: ENV['SARF_USERNAME'],
      password: ENV['SARF_PASSWORD'],
      processor_code: 'sl',
      file_type: 'debit'
    }
  end

  before do
    allow(Time).to receive(:now).and_return(Time.new(2014, 6, 16, 0, 0, 0, "+00:00"))

    def subject.returns_path
      '/SARF_test/Responses/'
    end

    def subject.push_remote_file_path
      "/SARF_test/Requests/#{ file_name }"
    end
  end

  it_behaves_like 'a provider'
end
