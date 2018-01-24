require 'spec_helper'
require 'shared_examples_for_providers'
require 'achis/providers/sarf'

describe Achis::Providers::SARF do

  include_examples 'provider'

  let(:credentials) do
    {
      :host           => 'host.com',
      :username       => 'username',
      :password       => 'password',
      :processor_code => 'rbl',
      :file_type      => 'debit'
    }
  end

  let(:provider_name){'sarf'}

  it 'uses the provided host and credentials to log in' do
    credentials = subject.connection.class.started_with
    expect(credentials).to eq(['host.com', 'username', 'password', nil,
                               ftps_mode: :implicit,
                               passive: true,
                               verify: :none ])
  end

  describe '#push' do
    include_examples 'provider#push'

    let(:push_file_path){'/SARF/Requests/rbl_ach_debit_20141128_1417181400.xls'}

    it 'uses "/SARF/Requests/rbl_ach_credit_20141128_1417181400.xls" ' \
       'for credit batches' do
      subject.credentials[:file_type] = 'credit'
      subject.push [ transaction_credit ]
      expect(sent_file[:remote_path]).to eq('/SARF/Requests/rbl_ach_credit_20141128_1417181400.xls')
    end

    it 'sends credits with a different format' do
      subject.credentials[:file_type] = 'credit'
      subject.push [ transaction_credit ]
      expected_file = File.read(fixture_file('sarf/rbl_ach_credit_20141128_1417181400.xls'))
      expect(File.read(sent_file[:local_file])).to eq(expected_file)
    end

  end

  describe '#pull' do
    include_examples 'provider#pull'

    let(:returns_file_path) do
      %w[
        /SARF/Responses/report-rbl_ach_debit_20141128_1413938665_returns.csv
      ]
    end

    let(:ignored_files) do
      %w[
        /SARF/Returns/report-rbl_ach_debit_20141128_1417181400.csv
        /SARF/report-rbl_ach_credit_20141128_1417181400.csv
        /SARF/Responses/report-oth_ach_debit_20141128_1417181400.csv
        /SARF/Responses/report-rbl_ach_credit_20131128_1417181400.csv
        /SARF/Responses/report-rbl_ach_credit_20151128_1417181400.csv
      ]
    end

    before do
      Achis::MockConnection.remote_files += ignored_files
    end

    it 'parse all the records' do
      expect(return_records.size).to eq 20
    end

    it 'can process windows-1251 encoded files'do
      expect(return_records).to include(
        have_attributes(transaction_id: '0BBF0DC367BF')
      )
    end

    it 'parse P codes as settlements' do
      expect(return_records).to include(
        have_attributes(nacha_code: 'S01')
      )
    end
  end
end
