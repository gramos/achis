[![Build Status](https://magnum.travis-ci.com/Katlean/achis.svg?token=MqMZysWvNsjRsPcwgQA8&branch=master)](https://magnum.travis-ci.com/Katlean/achis)
[![Code Climate](https://codeclimate.com/repos/53bda2fe69568029cb00e93b/badges/e69c4589ba29fb1a2265/gpa.svg)](https://codeclimate.com/repos/53bda2fe69568029cb00e93b/feed)
[![Test Coverage](https://codeclimate.com/repos/53bda2fe69568029cb00e93b/badges/e69c4589ba29fb1a2265/coverage.svg)](https://codeclimate.com/repos/53bda2fe69568029cb00e93b/feed)

# Achis

Achis helps to integrate an application with different ACH processors.

## Installation

Add 'achis' to the Gemfile and bundle.

## Usage

### Setting up the client ###

The first thing to do is to setup a client for a given provider with the
required credentials.

~~~ ruby
credentials = {
                host:        'provider.net',
                username:    'user',
                keys:        ['~/private_key_file'],
                merchant_id: '12345'
              }

client = Achis::Providers::Transact24.new credentials
~~~

You can also set credential as environment variables like this:

~~~ shell
export ACHIS:TRANSACT24:HOST='providert24.com'
export ACHIS:TRANSACT24:USERNAME='test'
export ACHIS:TRANSACT24:KEYS='~/.ssh/transition_rsa'
export ACHIS:TRANSACT24:MERCHANT_ID='1234'
~~~

~~~ ruby
client = Achis::Providers::Transact24.new
~~~

To know what are the required credentials for each provider check the
[spec file](./spec/achis/providers).

Clients provide a clean public interface, you can `push` transactions and
`pull` returns.

### Pushing transactions ###

The main virtue of achis, is that there is no difference
bettween providers, we have a transaction object that should work for
each provider.

~~~ ruby
sample_transaction = {
  id:               "FD00AFA8A0F7",
  transaction_type: :debit,
  amount:           '16',
  effective_date:   Date.new(2013, 03, 26),
  first_name:       'marge',
  last_name:        'baker',
  address:          '101 2nd st',
  city:             'wellsville',
  state:            'KS',
  postal_code:      '66092',
  telephone:        '5858232966',
  account_type:     'checking',
  routing_number:   '103100195',
  account_number:   '3423423253234'
}
~~~

With averything set up, it is time to push the transaction:

~~~ ruby
client.push [ sample_transaction ]
~~~

### Pulling returns ###

Once you `pull` returns you will always get the same normalized object.

~~~ ruby
returns = client.pull Date.new(2014, 11, 28)

sample_return = returns.first #=>#<Achis::ReturnRecord:0x007ff203c6e2b8>

sample_return.transaction_id #=> "FD00AFA8A0F7"
sample_return.nacha_code     #=> "R02"
sample_return.date           #=> #<Date: 2014-11-28 ((2456990j,0s,0n),+0s,2299161j)>
sample_return.description    #=> "Closed account 0010000013"
~~~

All the returns are retrieved and parsed together and are assigned an
standar nacha code for returns, for settlements they are assigned an 'S'
code, results of validations receive 'V' codes and corrections use 'C'
codes. Codes are always one uppercase letter and two digits.

### Processed files ###

After any push or pull, the files that were transfered are accessible
as processed files, they are [temp files][1] so they get unlinked
(deleted) once there is no refference for them.

~~~ ruby
client.pull Date.new(2014, 11, 28)

client.processed_files
#=> [#<File:/tmp/RBL_SL1_BankReturns_20141128_ToClnt.csv20141128-9833-nc3t0u (closed)>,
#    #<File:/tmp/RBL_SL2_BankReturns_20141128_ToClnt.csv20141128-9833-sfp1u7 (closed)>]
~~~

 [1]: http://ruby-doc.org/stdlib-trunk/libdoc/tempfile/rdoc/Tempfile.html

## Adding new providers ##

Some common requirements for adding a new provider are supplied in the
file [doc/new_provider_requirements](./doc/new_provider_requirements.md).

In any case, there are shared examples that can be used to build
specifications and integration tests.

~~~ ruby
describe Achis::Providers::OtherProvider do

  include_examples 'provider'

  let(:credentials) do
    {
      host:        'provider.net',
    }
  end

  let(:provider_name) { 'the_good_one' }

  describe '#push' do

    include_examples 'provider#push'

    let(:push_file_path) { '/the_push_path/new/custom_expected_name.12345.2014-11-28.00.csv' }

  end

  describe '#pull' do

    include_examples 'provider#pull'

    let(:returns_file_path) do
      '/pull_path/new/Returns.12345.2014-11-28.00.csv'
    end

  end

end
~~~

The error messages should guide you on the setup of the provider. You
will need to add fixture files (with the expected names) in the
`spec/fixtures/new_provider` folder.

## Roadmap ##

- Credentials should use environment variables.

- Transactions should be constructed in the client from a hash or a JSON
  string.

- ReturnRecords should behave as a hash.

## Contributing

1. Fork it ( https://github.com/Katlean/achis/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## COPYING

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
