require 'achis/mock_connection'
require 'achis/return_record'

RSpec.shared_examples "provider" do

  subject do
    described_class.new(credentials)
  end

  before do
    @original_connection_adapter = described_class.connection_adapter_class
    described_class.connection_adapter_class = Achis::MockConnection
    allow(Date).to receive(:today) { Date.new(2014, 11, 28) }
    allow(Time).to receive(:now)   { Time.new(2014, 11, 28, 13, 30, 0, 0) }
    allow(DateTime).to receive(:now) { DateTime.new(2014, 11, 28) }
  end

  after do
    described_class.connection_adapter_class = @original_connection_adapter
    Achis::MockConnection.teardown_mocks
  end

  it 'has a provier name' do
    expect(subject.provider_name).to eq provider_name
  end
end

RSpec.shared_examples "provider#push" do

  let :batch do
    [ transaction_debit, transaction_credit ]
  end
  let(:sent_file)      { Achis::MockConnection.sent_files.first }
  let(:generated_file) { File.read(sent_file[:local_file]) }

  let(:sample_file) do
    fixture_file "#{ provider_name }/#{ push_file_path.split('/').last }"
  end

  it 'send a file to the correct path' do
    subject.push batch
    expect(sent_file[:remote_path]).to eq(push_file_path)
  end

  it 'send a file with the correct format' do
    subject.push batch
    expect(generated_file).to eq sample_file.read
  end

  it 'could take an array of hashes as batch' do
    subject.push [transaction_debit_hash, transaction_credit_hash]
    expect(sent_file[:remote_path]).to eq(push_file_path)
  end
end

RSpec.shared_examples "provider#pull" do
  let(:date)          { Date.new(2014, 11, 28) }
  let(:return_records){ subject.pull(date) }
  let(:return_record) { return_records.first }

  before do
    [ *returns_file_path ].each do |path|
      fixture = fixture_file "#{ provider_name }/#{ path.split('/').last }"
      Achis::MockConnection.setup_mock_file(path, File.read(fixture))
    end
  end

  it 'return a list of return records with all the required values' do
    return_records
    warnings = Achis::MockConnection.warnings
    expect(warnings).to be_empty, warnings.join("\n")
    expect(return_records).to_not be_empty, 'No returns files were returned.'
    expect(return_records).to all(
      be_kind_of(Achis::ReturnRecord).and(
        have_attributes(
          transaction_id: matching(/^\w{12}$/),
          nacha_code:     matching(/^(?:C|R|S|V)\d\d$/),
          date:           a_kind_of(Date),
          description:    a_kind_of(String)
        )
      )
    )
  end

end
