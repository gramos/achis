require 'achis/client'
require 'achis/formatters/csv'
require 'achis/connection_adapters/sftp'

module Achis ; module Providers
  class Transact24 < Client

    ACCOUNT_CODES = { checking: 'C', saving: 'S' }
    TRANSACTION_CODES = { debit: 'D', credit: 'C' }

    self.connection_adapter_class = ConnectionAdapters::SFTP

    include Formatters::Csv

    def provider_name
      'transact24'
    end

    def parse_returns file
      CSV.read(file).map do |row|
        {
          transaction_id: row[3],
          nacha_code:     row[15],
          date:           Date.strptime(row[6], '%m/%d/%Y'),
          description:    row[16]
        }
      end
    end

    private

    def push_remote_file_path
      "#{ inbox_new_path }/#{ file_name }"
    end

    def connection_settings
      [credentials[:host], credentials[:username], keys: credentials[:keys]]
    end

    def return_file_base_name(date)
      "Returns.Transact24.#{credentials[:merchant_id]}." \
      "#{date.strftime('%Y-%m-%d')}"
    end

    def returns_files_pattern(date)
      "#{return_file_base_name(date)}.*.csv"
    end

    def returns_path
      "/outbox/new"
    end

    def inbox_new_path
      "/inbox/new"
    end

    def file_name
      "Transactions.#{ credentials[:merchant_id] }." \
      "Transact24.#{ file_date }.#{ next_sequence_number }.csv"
    end

    def check_transaction! transaction
      raise InvalidTransactionError \
        unless transaction.respond_to? :transaction_type
    end

    def generate_row transaction
      check_transaction! transaction

      [
        '10',
        account_type_code(transaction.account_type),
        transaction_type_code(transaction.transaction_type),
        nil,
        transaction.routing_number,
        transaction.account_number,
        transaction.amount,
        transaction.effective_date.strftime('%Y%m%d'),
        "#{transaction.first_name} #{transaction.last_name}"[0..21],
        transaction.address,
        nil,
        transaction.city,
        transaction.state,
        transaction.postal_code,
        transaction.telephone,
        nil, # Driver license state
        nil, # Driver license number
        nil, # Social security number
        credentials[:merchant_id],
        transaction.id,
        'NONE' # Validation type
      ]
    end

    def account_type_code account_type
      ACCOUNT_CODES[account_type]
    end

    def transaction_type_code transaction_type
      TRANSACTION_CODES[transaction_type]
    end

    def next_sequence_number
      glob   = "Transactions.#{ credentials[:merchant_id] }." \
               "Transact24.#{ file_date }.*.csv"
      files = connection.glob(inbox_new_path, glob)
      last_file = files.sort.last
      if last_file
        last_file.match(/\.(\d{2})\.csv/)[1].next
      else
        '00'
      end
    end

  end
end ; end
