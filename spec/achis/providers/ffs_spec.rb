require 'spec_helper'
require 'shared_examples_for_providers'
require 'achis/providers/ffs'

describe Achis::Providers::FFS do

  include_examples 'provider'

  let(:credentials) do
    {
      host:        'provider.net',
      username:    'user',
      password:    'pass'
    }
  end
  let(:provider_name){ 'ffs' }

  describe '#push' do

    include_examples 'provider#push'

    let(:push_file_path) do
      'Requests/ffs_payments_2014-11-28_1417181400.csv'
    end

    it 'has a footer with the batch size and total amount' do
      subject.push batch
      expect(generated_file).to match(
        /.*\n^FFSFooter,#{batch.size},3650/)
    end

    it 'has a header with the ffs payment version file' do
      subject.push batch
      expect(generated_file).to match(
        /\AFFSPaymentFile_v1.0,,\r\n.*\r\n/)
    end

    it 'has a header and it includes the attributes names' do
      header = 'PaymentRoutingNumber,PaymentType,Amount,BankNumber,' \
               'AccountNumber,CurrencyCode,AccountType,AccountName,' \
               'Description,Reference,Comment'
      subject.push batch
      expect(generated_file).to match(
        /\AFFSPaymentFile_v1.0,,\r\n#{header}(\r\n.*)*/)
    end

    it 'limit names to 22 characters' do
      transaction = transaction_debit
      transaction.first_name = 'A very long name with a ,coma'
      expect(transaction.first_name.size).to be > 22
      subject.push [transaction]
      generated_file.lines.to_a.each do |line|
        fields = line.split(',')
        expect(fields).to all be_limited_by(22)
      end
    end

  end

  describe '#pull' do

    include_examples 'provider#pull'

    let(:returns_file_path) do
      '/Returns/Spotloan 2014-11-28 Returns.txt'
    end

    it 'get the return record values from the file' do
      expect(return_record.transaction_id).to eq "123456781234"
      expect(return_record.nacha_code).to     eq "R01"
      expect(return_record.date).to           eq Date.new(2013, 8, 5)
      expect(return_record.description).to    eq ""
    end

  end
end
