require 'achis/client'
require 'achis/formatters/csv'
require 'achis/connection_adapters/sftp'

module Achis ; module Providers
  class Payliance < Client

    self.connection_adapter_class = ConnectionAdapters::SFTP

    include Formatters::Csv

    TRANSACTION_CODES = { debit: 'D', credit: 'C' }
    ACCOUNT_CODES = { checking: 'C', saving: 'S' }

    # Response validation codes
    VALIDATION_CODES = {
      0 => 'V00',   1 => 'V01', 2  => 'V01', 10 => 'V01', 20 => 'V02',
      21 => 'V03', 22 => 'V03', 23 => 'V02', 24 => 'V02', 25 => 'V02',
      26 => 'V02', 27 => 'V02', 28 => 'V02', 29 => 'V02', 30 => 'V02',
      31 => 'V02', 32 => 'V02', 33 => 'V02', 34 => 'V02', 35 => 'V02',
      36 => 'V02', 37 => 'V02', 38 => 'V02', 39 => 'V02', 40 => 'V02',
      41 => 'V02', 42 => 'V02', 43 => 'V02', 44 => 'V02', 45 => 'V02',
      49 => 'V02', 50 => 'V02', 51 => 'V02', 52 => 'V02', 53 => 'V02',
      90 => 'V02', 91 => 'V02', 92 => 'V02', 93 => 'V03', 101 => 'V02',
      105 => 'V02'
    }

    def provider_name
      'payliance'
    end

    private

    # This provider has returns and settlements
    # and we parsed both at the same time.
    #
    def parse_returns file
      case file.path
      when /Processed/
        []  # We do this so that we can prevent processing of _all_ files during prod support cases
      when /Return/
        read_csv(file).map{ |row| build_return(row) }
      when /Settle/
        read_csv(file).map{ |row| build_settlement(row) }
      when /Result/
        read_csv(file).map{ |row| build_result(row) }
      end
    end

    def read_csv(file)
      csv = CSV.read(file)
      csv.first.empty? ? [] : csv
    end

    def date_format(date)
      Date.strptime(date, '%m/%d/%Y')
    end

    def build_return_record *attrs
      {
        transaction_id: attrs[0],
        date:           attrs[1],
        nacha_code:     attrs[2],
        description:    attrs[3]
      }
    end

    def build_settlement row
      build_return_record( row[2], date_format( row[1] ), 'S00', '' )
    end

    def build_return row
      build_return_record( row[2], date_format( row[1] ),
                           row[11], row[12] )
    end

    def build_result row
      build_return_record( row[2], date_format( row[1] ),
                           VALIDATION_CODES[row[7].to_i], row[8] )
    end

    def connection_settings
      [ credentials[:host], credentials[:username],
        password: credentials[:password] ]
    end

    def returns_path
      "/Outbound"
    end

    def returns_files_pattern(date)
      "#{return_file_base_name(date)}.csv"
    end

    # We have to match this with *_Result, *_Settle, *_Return
    #
    def return_file_base_name(date)
      "#{date.strftime('%y%m%d')}*_#{credentials[:cyber_location_id]}*_[R|S]e[t|s]*"
    end

    def file_name
      today = Date.today
      "#{ today.strftime('%y%m%d') }" \
      "_#{ credentials[:cyber_location_id] }_#{ sequence(today) }.csv"
    end

    def generate_row(transaction)
      [
        5,
        credentials[:client_id],
        credentials[:location_id],
        credentials[:store_id],
        transaction.id,
        transaction.routing_number,
        transaction.account_number,
        nil,
        transaction.amount,
        'TEL',
        transaction_type_code(transaction.transaction_type),
        nil,
        ACCOUNT_CODES[transaction.account_type],
        transaction.last_name,
        transaction.first_name,
        transaction.address,
        nil,
        transaction.city,
        transaction.state,
        transaction.postal_code,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        "S"
      ]
    end

    def push_remote_file_path
      "/#{ file_name }"
    end

    def batch_file_contents batch
      CSV.generate(:force_quotes => true) do |csv|
        batch.each { |t| csv << generate_row(t) }
      end
    end

    def sequence today
      glob      = "#{ today.strftime('%y%m%d') }" \
                  "_#{ credentials[:cyber_location_id] }_*.csv"
      files     = connection.glob("", glob)
      last_file = files.sort.last

      return last_file.match(/_(\d+)\.csv/)[1].next if last_file
      1
    end

    def transaction_type_code transaction_type
      TRANSACTION_CODES[transaction_type]
    end

  end
end ; end
