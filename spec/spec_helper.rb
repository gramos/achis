if ENV['CODECLIMATE_REPO_TOKEN']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
else
  require 'simplecov'
  SimpleCov.start do
    add_group "Core" do |file|
      file.filename !~ /providers/ &&
        file.filename !~ /connection_adapters/
    end
    add_group "Providers", "lib/achis/providers"
    add_group "Connection Adapters", "lib/achis/connection_adapters"
    add_filter "/spec/"
  end
end

require 'achis/transaction'

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

def fixture_file(name)
  File.new File.expand_path("#{__FILE__}/../fixtures/#{name}")
end

def transaction_debit_hash
  {  id:               "FD00AFA8A0F7",
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
end

def transaction_credit_hash
  {  id:               "665E0601D848",
     transaction_type: :credit,
     amount:           '20.50',
     effective_date:   Date.new(2013, 03, 26),
     first_name:       'James,,,',
     last_name:        'Good, man',
     address:          '10 Maple Dr, APT 123',
     city:             'Boiling Springs,',
     state:            'PA,',
     postal_code:      '17007',
     telephone:        '6155320889',
     email:            'abc@xyz.com',
     account_type:     'saving',
     routing_number:   '124003116',
     account_number:   '192312313'
  }
end

def transaction_debit
  Achis::Transaction.new transaction_debit_hash
end

def transaction_credit
  Achis::Transaction.new transaction_credit_hash
end

RSpec::Matchers.define :be_limited_by do |expected|
  match do |actual|
    actual.size <= expected
  end
end

def csv_fields csv
  csv.lines.to_a.map { |line| line.split(',') }.flatten
end
