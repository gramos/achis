require 'spec_helper'
require 'achis/mock_connection'
require 'tempfile'

describe Achis::MockConnection do

  let(:sample_file) do
    @tempfile_created = true
    Tempfile.new 'sample'
  end

  before do
    described_class.teardown_mocks
  end

  after do
    sample_file.close && sample_file.unlink if @tempfile_created
  end

  it 'globs gets the files that where sent' do
    connection = described_class.start
    connection.send_file sample_file.path, '/a_remotepath/base.csv'

    remote_files = connection.glob( '/a_remotepath', '*.csv')
    expect(remote_files).to eq ['/a_remotepath/base.csv']
  end

  it 'raise an error if any action is done with a closed connection' do
    expect do
      subject.close
      subject.send_file sample_file.path, '/a_remotepath/base.csv'
    end.to raise_error RuntimeError
  end

  it 'let you check if the connection was properly closed' do
    connection = described_class.start
    expect(connection).to be_open
    connection.close
    expect(connection).to be_closed
  end

  it 'lets you spec the sent files' do
    connection = described_class.start
    connection.send_file sample_file.path, '/remote/base.csv'
    sent_file = described_class.sent_files.first
    expect(sent_file[:local_file]).to eq sample_file.path
    expect(sent_file[:remote_path]).to eq '/remote/base.csv'
  end

  it 'lets you do some globbing to find files' do
    expect(subject.glob('/out', '*.csv')).to eq([])
  end

  it 'lets you mock existing files' do
    described_class.remote_files = %w[ /other_file.csv /out/01.csv /out/02.csv /out/05.fch ]
    expect(subject.glob('/out', '*.csv')).to eq(
      %w[ /out/01.csv /out/02.csv ])
  end

  it 'mock remote files are removed with teardown_mocks' do
    described_class.remote_files = %w[ /other_file.csv /out/01.csv /out/02.csv /out/05.fch ]
    described_class.teardown_mocks
    expect(subject.glob('/out', '*.csv')).to be_empty
  end

  it 'let mock getting a file' do
    described_class.setup_mock_file '/out/01.csv', :a_file
    expect(subject.get_file('/out/01.csv')).to eq :a_file
  end

  it 'mocked remote files are find by glob' do
    described_class.setup_mock_file '/out/01.csv', :a_file
    expect(subject.glob('/out', '*.csv')).to eq ['/out/01.csv']
  end

  it 'raises an error if the requested file was not mocked' do
    expect do
      subject.get_file('/out/01.csv')
    end.to raise_error(%r{'/out/01\.csv' is not mocked})
  end

  it 'let you pass any parameters for start and stores them' do
    expect(described_class.started_with).to be_empty
    described_class.start 'important', 'key', should: 'be_stored'
    expect(described_class.started_with).to eq(['important', 'key', { should: 'be_stored' }])
  end

end
