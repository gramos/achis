Adding a new provider.
======================

Implementing a new provider is a straighforward process and it uses TDD. So we
need a simple test first:

```ruby
# spec/achis/providers/new_provider_spec.rb

require 'spec_helper'
require 'shared_examples_for_providers'
require 'achis/providers/new_provider'

describe Achis::Providers::NewProvider do

  include_examples 'provider'

  describe '#push' do

    include_examples 'provider#push'

  end

  describe '#pull' do

    include_examples 'provider#pull'

  end
end
```

This test will fail for different reasons, a new provider should be almost ready
after fixing those.

The exceptions that are received are: LoadError (because of the missing file),
the undefined constants Achis, Providers, NoProvider.

Just create the file and define the class. We use inheritance to model our
providers in achis, the base class is `Achis::Client` and it has very small
public intereface that we try to keep small and simple:

```ruby

Achis::Client

#new( credentials )

#pull( date )

#push( batch )

#processed_files

```

Do **not** define those methods in the new provider, just make the new provider
inherit from `Achis::Client`.

With that file in place, there will be some exceptions about undefined methods
in the tests that specify how the provider works, where are the files, what are
the credentials, etc.

```ruby

# the credentials needed for the given provider.
# use an empty hash at the start and add credentials as needed
#
let(:credentials) do
  {}
end

# how the provider is known in the outside world
#
let(:provider_name) { 'ffs' }

# where the file with transactions is expected in the remote server
# the date will always be 2014-11-28
#
let(:push_file_path) do
  'Transactions/payments_2014-11-28.csv'
end

# Where the returns files are stored in the server, all the return file types
# that the provider uses should be in that list as they all should be handled
# by the #pull method
# the date will always be 2014-11-28
#
let(:returns_file_path) do
  %w[
    /Returns/Spotloan 2014-11-28 Returns.txt
    /Returns/Spotloan 2014-11-28 Response.txt
  ]
end
```

Those lets, will also define where you should store the fixture files that will
need to be stored in the `spec/fixtures/new_provider` folder (with the same
name that is expected in the server).

To implement a new provider you will need to implement the missing methods and
the result will look like more or less this.

``` ruby
require 'achis/client'

module Achis
  module Providers
    class NewProvider < Achis::Client

      self.connection_adapter_class = ConnectionAdapters::SFTP

      def connection_settings
        [ credential[:host] ]
      end

      def provider_name
        'new_provider'
      end

      def parse_returns return_file
        CSV.open(file)
      end

      def returns_path date
        "something/filedate.csv"
      end

      def generate_row transaction
        [ transaction.id ]
      end

    end
  end
end
```

## Integration tests

The last step is to setup the connection adapter and test it (as it cannot be
fully automated). The integration tests should help (but the remote files needs
to be manualy upload for testing).

```ruby
require 'spec_helper'
require 'achis/providers/new_provider'
require 'integration/shared_examples_for_providers'

describe Achis::Providers::NewProvider, :integration => true do

  let(:provider_args) do
    { host:        ENV['NEW_PROVIDER_HOST'],
      username:    ENV['NEW_PROVIDER_USERNAME'],
      password:    ENV['NEW_PROVIDER_PASSWORD'] }
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
```

To run those you will need valid credentials in the environment and run the
specs with `rspec --tag integration`.

Trying MockProvider
===================

```ruby

irb -Ilib

require 'achis'
require 'date'
require 'achis/providers/mock_provider'

ENV['ACHIS:MOCK_PROVIDER:SAMPLE_CREDENTIAL'] = 'fruta.com'
ENV['ACHIS:MOCK_PROVIDER:HOST']              = 'example.com'
ENV['ACHIS:MOCK_PROVIDER:PASSWORD']          = 'manzana'

client = MockProvider.new

client.push [ { :id => 'abc' } ]

client.processed_files.first.open.read

Achis::MockConnection.sent_files

Achis::MockConnection.setup_mock_file '/returns/sample_return-2014-11-28.1.csv', 'ok,bad'

client.pull Date.new 2014, 11, 28
client.processed_files

```
