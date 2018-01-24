require 'achis/client'
require 'achis/formatters/csv'
require 'achis/connection_adapters/ftps'
require 'csv'

module Achis ; module Providers
  class SARF < Client

    self.connection_adapter_class = ConnectionAdapters::FTPS

    include Formatters::Csv

    ACCOUNT_CODES = { checking: 'checking', saving: 'savings' }

    def provider_name
      'sarf'
    end

    private

    def connection_settings
      [ credentials[:host], credentials[:username], credentials[:password],
        nil, ftps_mode: :implicit, passive: true, verify: :none ]
    end

    def push_remote_file_path
      "/SARF/Requests/#{file_name}"
    end

    def file_name
      "#{ credentials[:processor_code] }_ach_#{ credentials[:file_type] }" \
      "_#{ Date.today.strftime('%Y%m%d') }_#{ Time.now.to_i }.xls"
    end

    def generate_row transaction
      if credentials[:file_type] == 'credit'
        generate_row_for_credit transaction
      else
        generate_row_for_debit transaction
      end
    end

    def generate_row_for_credit transaction
      [
        transaction.first_name,
        transaction.last_name,
        transaction.address,
        transaction.city,
        transaction.state,
        transaction.postal_code,
        'US',
        transaction.telephone,
        transaction.email,
        transaction.amount,
        transaction.routing_number,
        ACCOUNT_CODES[transaction.account_type],
        transaction.account_number,
        transaction.id
      ]
    end

    def generate_row_for_debit transaction
      [ "#{transaction.first_name} #{transaction.last_name}",
        [ transaction.address, transaction.city,
          transaction.state,   transaction.postal_code
        ].join(" | "),
        transaction.telephone,
        transaction.amount,
        transaction.id,
        transaction.routing_number,
        transaction.account_number,
        nil
      ]
    end

    def file_header
      if credentials[:file_type] == 'credit'
        [ %w[ firstName lastName address city state zip country phone email amount
              routing accountType accountNumber memo ] ]
      else
        [ %w[ name address phone amount check_number routing acc_number memo ] ]
      end
    end

    def returns_path
      '/SARF/Responses'
    end

    def returns_files_pattern date
      "report-#{ credentials[:processor_code] }_ach_*" \
        "#{ date.strftime('%Y%m%d') }_*.csv"
    end

    def parse_returns file_path
      file = File.open(file_path, 'rb', encoding: 'windows-1251:utf-8')
      file_contents = file.read.gsub(/\r\n?/, "\n")
      CSV.parse(file_contents, headers: true, row_sep: :auto).map do |row|
        if file_path.to_path =~ /_credit_/
          parse_credit_return row
        else
          parse_debit_return row
        end
      end
    ensure
      file.close
    end

    def parse_credit_return row
      {
        transaction_id: row[20],
        nacha_code:     normalized_nacha_code(row[14]),
        date:           Date.parse(row[7]),
        description:    row[13]
      }
    end

    def parse_debit_return row
      {
        transaction_id: row[19],
        nacha_code:     normalized_nacha_code(row[14]),
        date:           Date.strptime(row[7], "%m-%d-%y"),
        description:    row[13]
      }
    end

    def normalized_nacha_code original_code
      original_code.tr('PO', 'S0')
    end
  end

end ; end
