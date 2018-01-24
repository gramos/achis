require 'spec_helper'
require 'shared_examples_for_providers'
require 'achis/providers/transact_24'
require 'achis/mock_connection'

describe Achis::Providers::Transact24 do

  include_examples 'provider'

  let(:credentials) do
    {
      host:        'provider.net',
      username:    'user',
      keys:        ['~/private_key_file'],
      merchant_id: '12345'
    }
  end
  let(:provider_name){'transact24'}

  describe '#push' do

    include_examples 'provider#push'

    let(:push_file_path) { '/inbox/new/Transactions.12345.Transact24.2014-11-28.00.csv' }

    it 'with invalid transactions it raises a specific error' do
      expect {subject.push [transaction_debit, 1]}.to \
        raise_error(Achis::InvalidTransactionError)
    end

    it 'limit names to 22 characters' do
      transaction = transaction_debit
      transaction.first_name = 'A very long name with a ,coma'
      expect(transaction.first_name.size).to be > 22
      subject.push [transaction]
      fields = File.read(sent_file[:local_file]).lines.to_a.first.split(',')
      expect(fields).to all be_limited_by(22)
    end

    context 'when there are files already in the inbox' do
      before do
        Achis::MockConnection.remote_files = %w[
          /inbox/new/Transactions.12345.Transact24.2014-11-28.01.csv
          /inbox/new/Transactions.12345.Transact24.2014-11-28.02.csv
        ]
      end

      it 'uses the next sequence number available for that day' do
        subject.push batch
        expect(sent_file[:remote_path]).to eq(
          '/inbox/new/Transactions.12345.Transact24.2014-11-28.03.csv')
      end
    end
  end

  describe '#pull' do

    include_examples 'provider#pull'

    let(:returns_file_path) do
      '/outbox/new/Returns.Transact24.12345.2014-11-28.00.csv'
    end

    it 'have all the required field values' do
      expect(return_record.transaction_id).to eq "ADFEC412CB90"
      expect(return_record.nacha_code).to     eq "C03"
      expect(return_record.date).to           eq Date.new(2014, 05, 20)
      expect(return_record.description).to    eq "555555555/0000"
    end

    it 'respect the legacy interface' do
      expect(return_record.unique_transaction_id).to eq return_record.transaction_id
      expect(return_record.return_reason_code).to    eq return_record.nacha_code
      expect(return_record.return_date).to           eq return_record.date
      expect(return_record.correction_detail).to     eq return_record.description
    end

  end
end
