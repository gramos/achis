# -*- coding: utf-8 -*-
require 'spec_helper'
require 'achis/connection_adapters/ftps'

describe Achis::ConnectionAdapters::FTPS do

  describe '#glob' do
    ENV['ACHIS_ENV'] = 'test'

    let(:ftp) do
      described_class.new 'exmple.com', 'root', 'the-pass', {}
    end

    let(:ftps){ double('ftps') }
    let(:return_file_path){ '/outbox/a-return-file.csv' }

    it '#get_file returns content in UTF-8 always, force encoding' do
      allow(ftp).to receive(:ftps){ ftps }
      allow(ftps).to receive(:gettextfile).with(return_file_path, nil) do
        'FILE CONTENT ÑANDÚ'.force_encoding('ISO8859-1')
      end

      file_content = ftp.get_file(return_file_path)
      expect(file_content.encoding.name).to eq 'UTF-8'
    end

    context 'when nlst returns files without the path' do
      it 'returns paths as strings' do
        allow(ftp).to receive(:nlst) do
          ['a-return-file.csv', 'fruit.txt', 'smoke.xls', 'another-return-file.csv']
        end

        expected_paths = ['/outbox/a-return-file.csv', '/outbox/another-return-file.csv']
        expect(ftp.glob '/outbox', '*.csv').to eq expected_paths
      end
    end

    context 'when nlst returns files including path' do
      it 'returns paths as strings as the same way if ' \
        'the server does not includes paths on #nlst' do

        allow(ftp).to receive(:nlst) do
          ['/outbox/a-return-file.csv', '/outbox/fruit.txt',
           '/outbox/smoke.xls', '/outbox/another-return-file.csv']
        end

        expected_paths = ['/outbox/a-return-file.csv', '/outbox/another-return-file.csv']
        expect(ftp.glob '/outbox', '*.csv').to eq expected_paths
      end
    end
  end
end
