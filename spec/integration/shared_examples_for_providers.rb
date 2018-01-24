require 'spec_helper'

shared_examples 'a provider' do

  subject do
    described_class.new( provider_args )
  end

  let :batch do
    [ transaction_debit, transaction_credit ]
  end

  it 'pulls returns files and download them as tmp files' do
    date = Date.new(2014, 6, 16)
    subject.pull(date)

    expect(subject.processed_files).to_not be_empty
    subject.processed_files.each do |f|
      expect(File.file? f.path).to be
    end
  end

  it 'push csv payments files via sftp' do
    subject.push(batch)
    sleep 1
    subject.connection.remove subject.send(:push_remote_file_path)
  end
end
