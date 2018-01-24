require 'spec_helper'
require 'shared_examples_for_providers'
require 'achis/mock_connection'
require 'achis/providers/payliance'

describe Achis::Providers::Payliance do

  include_examples 'provider'

  let(:credentials) do
    {
      host:              'host.com',
      username:          'username',
      password:          'asecret',
      cyber_location_id: '000000',
      client_id:         'client_id',
      store_id:          '000001',
      location_id:       '0000'
    }
  end
  let(:provider_name){'payliance'}

  it 'uses the provided host and credentials to log in' do
    credentials = subject.connection.class.started_with
    expect(credentials).to eq(['host.com', 'username', password: 'asecret'])
  end

  describe '#push' do

    include_examples 'provider#push'

    let(:push_file_path) { '/141128_000000_1.csv' }

    it 'set the sequence number based on the files in the remote folder' do
      Achis::MockConnection.remote_files = %w[
        /141127_000000_3.csv
        /141128_000000_1.csv
        /141128_000000_2.csv
      ]
      subject.push batch
      expect(sent_file[:remote_path]).to eq('/141128_000000_3.csv')
    end

  end

  describe 'getting returns' do

    context 'processed files' do

      let(:date){Date.new(2014, 11, 28)}
      let(:all_records) { subject.pull(date)}

      before do
        Achis::MockConnection.remote_files = %w[
          /Outbound/141129093515_000000_Return_Processed.csv
        ]
      end

      it "ignore all files that have the name 'Processed' in it" do
        expect(all_records.size).to eq 0
      end
    end

    describe '#pull' do
      include_examples 'provider#pull'

      let(:returns_file_path) do
        %w[
          /Outbound/141128093515_000000something_extra_Return.csv
          /Outbound/141128093515_000000_Settle.csv
          /Outbound/141128093515_000000_Result.csv
        ]
      end

      let(:return_record) { return_records[0] }
      let(:settlement_record) { return_records[2] }
      let(:response_record) { return_records[4] }

      before do
        Achis::MockConnection.remote_files += %w[
          /Outbound/141128093515_000000_Fruit.csv
          /Outbound/141129093515_000000.csv
          /Outbound/141129093515_000000_Return.csv
        ]
      end

      it 'parse all the records' do
        return_records
        expected_records = subject.processed_files.
          map{ |file| File.readlines(file).size }.inject(&:+)
        expect(return_records.count).to eq expected_records
      end

      it 'has returns with all the required fields' do
        expect(return_record.transaction_id).to eq "FD00AFA8A0F7"
        expect(return_record.nacha_code).to     eq "R02"
        expect(return_record.date).to           eq Date.new(2014, 11, 28)
        expect(return_record.description).to    eq "Some description"
      end

      it 'returns records are parsed as transaction objs' do
        expect(return_record).to be_kind_of Achis::ReturnRecord
      end

      it 'has settlements with all the required fields' do
        expect(settlement_record.transaction_id).to eq "mjhytredwokj"
        expect(settlement_record.date).to           eq Date.new(2010, 12, 10)
        expect(settlement_record.description).to    eq ''
        expect(settlement_record.nacha_code).to     eq 'S00'
      end

      it 'settlements has always the same nacha code' do
        expect(settlement_record.nacha_code).to eq 'S00'
      end

      it 'response records are parsed as transaction objs' do
        expect(response_record).to be_kind_of Achis::ReturnRecord
      end

      it 'assigns `V` nacha codes to results' do
        expect(response_record.nacha_code).to eq('V01')
      end

      it 'return no records with empty files' do
        Achis::MockConnection.teardown_mocks
        Achis::MockConnection.setup_mock_file(
          '/Outbound/141128093515_000000_Result.csv', '' )
        expect(return_records.count).to eq 0
      end

    end
  end

end
