require 'spec_helper'
require 'achis/providers/viking'
require 'integration/shared_examples_for_providers'

describe Achis::Providers::Viking, :integration => true do

  let(:provider_args) do
    {
      host:               ENV['VIKING_HOST'],
      username:           ENV['VIKING_USERNAME'],
      password:           ENV['VIKING_PASSWORD'],
      destination:        '91017329',
      destination_name:   "Signature Bank",
      origin:             '1234567',
      origin_name:        "VBS Blue Chip Financial",
      discretionary_data: "test discretionary data",
      company_id:         '1234567',
      company_name:       'VBS Spotloan',
      processor_code:     'RBL',
      lender_code:        'RB',
      file_type:          'Post',
      entry_description:  "8187777777"
    }
  end

  before do
    def subject.returns_path
      '/Test_To_ZST'
    end

    def subject.push_remote_file_path
      "/Test_To_Viking/#{ file_name }"
    end
  end

  it_behaves_like 'a provider'

end
