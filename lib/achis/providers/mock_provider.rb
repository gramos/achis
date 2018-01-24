require 'achis/client'
require 'achis/mock_connection'

module Achis
  module Providers
    class MockProvider < Achis::Client

      self.connection_adapter_class = Achis::MockConnection

      def provider_name
        'mock_provider'
      end

      def connection_settings
        [ credentials[:sample_credential] ]
      end

      def returns_path
        '/returns'
      end

      def returns_files_pattern(date)
        "sample_return-#{ date.strftime('%Y-%m-%d') }.*.csv"
      end

      def parse_returns returns_file
        File.read(returns_file).chomp.split(',').map do |transaction|
          {
            transaction_id: 'sample',
            nacha_code:     transaction.downcase,
            date:           Date.new(2014, 10, 12),
            description:    'a sample return'
          }
        end
      end

      def file_name
        'mock_transactions.csv'
      end

      def batch_file_contents batch
        batch.map do |transaction|
          [ transaction.id, transaction.amount ]
        end.join("\n")
      end

      def push_remote_file_path
        '/inbox'
      end
    end
  end
end
