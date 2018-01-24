require 'spec_helper'
require 'achis/providers/ffs'
require 'integration/shared_examples_for_providers'

describe Achis::Providers::FFS, :integration => true do

  let(:provider_args) do
    { host:        ENV['FFS_HOST'],
      username:    ENV['FFS_USERNAME'],
      password:    ENV['FFS_PASSWORD'] }
  end

  before do
    def subject.returns_path
      '/Test/Returns'
    end

    def subject.push_remote_file_path
      "/Test/Requests/#{file_name}"
    end
  end

  it_behaves_like 'a provider'

end
