require 'spec_helper'
require 'achis/providers/transact_24'
require 'integration/shared_examples_for_providers'

describe Achis::Providers::Transact24, :integration => true do

  let(:provider_args) do
    { host:        ENV['TRANSACT_24_HOST'],
      username:    ENV['TRANSACT_24_USERNAME'],
      keys:        ENV['TRANSACT_24_KEYS'],
      merchant_id: ENV['TRANSACT_24_MERCHANT_ID'] }
  end

  it_behaves_like 'a provider'
end
