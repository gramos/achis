require 'achis/client'
require 'achis/formatters/csv'
require 'achis/transaction'
require 'achis/connection_adapters/ftps'

module Achis ; module Providers
  class FFS < Client

    TRANSACTION_CODES = { debit: 'usach_ppd_debit', credit: 'usach_ppd_credit' }
    ACCOUNT_CODES     = { checking: 'checking', saving: 'savings' }

    self.connection_adapter_class = ConnectionAdapters::FTPS

    include Formatters::Csv

    def provider_name
      'ffs'
    end

    def parse_returns file
      file_no_headers = File.read(file).split("\n")[2..-2].join("\n")
      CSV.parse(file_no_headers).map{ |row| build_return(row) }
    end

    private

    def connection_settings
      [ credentials[:host], credentials[:username], credentials[:password],
        nil, ftps_mode: :explicit, verify: :none, passive: true ]
    end

    def returns_path
      "/Returns"
    end

    def returns_files_pattern(date)
      "#{return_file_base_name(date)}*.txt"
    end

    def return_file_base_name(date)
      "Spotloan #{date.strftime('%Y-%m-%d')} Returns"
    end

    def file_footer batch
      total_amount = batch.map{ |t| format_as_cents(t.amount) }.reduce(:+)
      ["FFSFooter", batch.size, total_amount]
    end

    def file_header
      [ ["FFSPaymentFile_v1.0", nil, nil], csv_attribute_names ]
    end

    def row_separator
      "\r\n"
    end

    def csv_attribute_names
      %w[ PaymentRoutingNumber PaymentType Amount BankNumber
          AccountNumber CurrencyCode AccountType AccountName
          Description Reference Comment ]
    end

    def next_sequence_number
      @next_sequence_number ||= Time.now.to_i
    end

    def push_remote_file_path
      "Requests/#{file_name}"
    end

    def file_name
      "ffs_payments_#{file_date}_#{next_sequence_number}.csv"
    end

    def generate_row transaction
      [332103,
       TRANSACTION_CODES[transaction.transaction_type],
       format_as_cents(transaction.amount),
       transaction.routing_number,
       transaction.account_number,
       'USD',
       ACCOUNT_CODES[transaction.account_type],
       "#{transaction.first_name} #{transaction.last_name}"[0..21],
       transaction.id,
       transaction.id,
       nil
      ]
    end

    # Amount should be in cents for FF
    #
    def format_as_cents(amount)
      (amount.to_f * 100).to_i
    end

    def build_return row
      {
        transaction_id: row[4].strip,
        nacha_code:     row[8].strip,
        date:           Date.strptime(row[10].strip, '%m/%d/%Y'),
        description:    row[8].strip.start_with?('C') ? row[13].strip : ''
      }
    end

  end
end ; end
