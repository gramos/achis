require 'spec_helper'
require 'achis/error'
require 'achis/providers/mock_provider'

describe Achis::Client do

  subject do
    Achis::Providers::MockProvider.new sample_credential: 'foo'
  end

  it 'provider implementation can access the supplied credentials' do
    expect(subject.send(:credentials)[:sample_credential]).to eq 'foo'
  end

  it 'raises an error for missing credentials' do
    expect do
      subject.send(:credentials)[:missing_credential]
    end.to raise_error Achis::MissingCredentialError
  end

  it 'have processed_files method that is filled after process files' do
    expect(subject.processed_files).to eq []
  end

  it 'uses env variables if credentials are empty' do
    ENV['ACHIS:MOCK_PROVIDER:HOST']     = 'from_env.com'
    ENV['ACHIS:MOCK_PROVIDER:PASSWORD'] = 'maradona'
    provider = Achis::Providers::MockProvider.new

    expect(provider.send(:credentials)[:host]).to eq 'from_env.com'
    expect(provider.send(:credentials)[:password]).to eq 'maradona'
  end

  describe '#push' do
    before do
      allow(Date).to receive(:today) { Date.new(2014, 11, 28) }
    end

    let(:batch) { [ transaction_debit, transaction_credit ] }

    it 'deletes the connection obj cache and set a new one so that' \
       'we can re-use the connection' do
      subject.push(batch)
      expect(subject.connection).to be_open
    end

    it 'load the sent files in #processed_files' do
      subject.push batch
      expect(subject.processed_files).to_not be_empty
      pushed_file = File.read(subject.processed_files.first)
      expect(pushed_file).to match <<-FILE.gsub(/^\s+|/, '')
        |FD00AFA8A0F7
        |16
        |665E0601D848
        |20.50
      FILE
    end

    it 'raise an Achis::EmptyBatch exception for an empty batch' do
      expect {subject.push []}.to raise_error(Achis::EmptyBatchError)
    end

  end

  describe '#pull' do
    let(:date)      { Date.new(2014, 11, 28) }

    before do
      Achis::MockConnection.setup_mock_file(
        '/returns/sample_return-2014-11-28.1.csv',
        'OK,BAD'
      )
    end

    after do
      Achis::MockConnection.teardown_mocks
    end

    it 'load the processed file in #processed_files' do
      subject.pull(date)
      expect(subject.processed_files).to_not be_empty
      expect(File.read(subject.processed_files.first)).to match('OK,BAD')
    end

    it 'returns the parsed returns as return records' do
      return_records = subject.pull(date)
      expect(return_records).to all be_a_kind_of Achis::ReturnRecord
      expect(return_records[0].nacha_code).to eq 'ok'
    end

    it 'deletes the connection obj cache and set a new one so that' \
       'we can re-use the connection' do
      subject.pull(date)
      expect(subject.connection).to be_open
    end

  end
end
