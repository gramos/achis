require 'spec_helper'
require 'shared_examples_for_providers'
require 'achis/providers/viking'
require 'achis/mock_connection'

describe Achis::Providers::Viking do

  include_examples 'provider'

  let(:credentials) do
    {
      destination:      '91017329',
      destination_name: "Signature Bank",
      origin:           '91017329',
      origin_name:      "VBS Blue Chip Financial",
      host:             'provider.net',
      username:         'user',
      password:         'fruit',
      company_name:     'VBS Blue Chip Finanical',
      company_id:       '1234567',
      processor_code:   'RBL',
      lender_code:      'RB',
      file_type:        'Post',
      discretionary_data: "test discretionary data",
      entry_description:  "8187777777"
    }
  end
  let(:provider_name){'viking'}

  describe '#push' do

    include_examples 'provider#push'

    let(:push_file_path) { 'To_Viking/RBL_RBP_Post_20141128_0.txt' }
    let(:sequenced_file_name) { 'To_Viking/RBL_RBP_Post_20141128_2.txt' }

    it 'uses "/To_Viking/processor_code_lender_code}_Fund_YYYYMMDD_sequence.txt" ' \
       'for credit batches' do
      subject.credentials[:file_type] = 'Fund'
      subject.push [ transaction_credit ]
      expect(sent_file[:remote_path]).to eq('To_Viking/RBL_RBF_Fund_20141128_0.txt')
    end

    it 'sequences the file name when another file on same day already exists' do
      Achis::MockConnection.remote_files = ['To_Viking/RBL_RBP_Post_20141128_1.txt']
      subject.push batch
      file = Achis::MockConnection.sent_files.first
      expect(file[:remote_path]).to eq(sequenced_file_name)
    end

    it 'uses service class 225 for debit only batches' do
      subject.push [ transaction_debit ]
      service_class = generated_file.lines.to_a[1][1, 3]
      expect(service_class).to eq('225')
    end

    it 'uses service class 220 for credit only batches' do
      subject.push [ transaction_credit ]
      service_class = generated_file.lines.to_a[1][1, 3]
      expect(service_class).to eq('220')
    end

    it 'uses a single batch for transactions with different effective date' do
      transactions = [27, 28, 29].map do |day|
        transaction = transaction_credit.clone
        transaction.effective_date = Date.new(2014, 11, day)
        transaction
      end
      subject.push transactions
      batch_count = generated_file.lines.to_a.
        select{ |row| row[0] == '5' }. # 5 is batch header
        size
      expect(batch_count).to eq(1)
    end

  end

  describe '#pull' do

    include_examples 'provider#pull'

    let(:returns_file_path) do
      %w[
        /To_RBL/RBL_SL1_BankReturns_20141128_ToClnt.csv
        /To_RBL/RBL_SL2_BankReturns_20141128_ToClnt.csv
        /To_RBL/RBL_SL2_ScrubReturn_20141128_ToClnt_INT3_160052.txt
      ]
    end

    it 'get the return values from the file' do
      expect(return_record.transaction_id).to eq "ADFEC412CB90"
      expect(return_record.nacha_code).to     eq "C03"
      expect(return_record.date).to           eq Date.new(2014, 11, 28)
      expect(return_record.description).to    eq "555555555/0000"
    end

    it 'gets disbursements files on pull' do
      Achis::MockConnection.remote_files += %w[
        /To_RBL/ZZZ_SLF_BankReturns_20141128_ToClnt.csv
        /To_RBL/ZZZ_SLG_BankReturns_20141128_ToClnt.csv
      ]
      subject.pull(date)
      expect(subject.processed_files.size).to eq returns_file_path.size
    end

    it 'ignore trailing characters for return file names' do
      Achis::MockConnection.setup_mock_file(
        "/To_RBL/RBL_SL1_BankReturns_20141128_ToClnt_28863.csv",
        File.read(fixture_file 'viking/RBL_SL1_BankReturns_20141128_ToClnt.csv'))

      subject.pull(date)
      expect(subject.processed_files.size).to eq(returns_file_path.size + 1)
    end

    it 'assigns todays date when date is not given' do
      return_records = subject.pull(date)
      expect(return_records[1].date).to eq Date.today
      expect(return_records[2].date).to eq Date.today
    end

    it 'parses scrub files as V02 codes' do
      return_records = subject.pull(date)
      expect(return_records).to include(have_attributes(nacha_code: 'V02'))
    end

  end
end
