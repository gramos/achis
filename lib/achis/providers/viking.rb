require 'achis/client'
require 'achis/formatters/csv'
require 'achis/connection_adapters/sftp'
require 'guevara'

module Achis ; module Providers

  class Viking < Client

    ACCOUNT_TYPE_CODE     = { checking: '2', saving: '3' }
    TRANSACTION_TYPE_CODE = { credit: '2', debit: '7' }

    self.connection_adapter_class = ConnectionAdapters::SFTP

    def provider_name
      'viking'
    end

    private

    def connection_settings
      [credentials[:host], credentials[:username], password: credentials[:password]]
    end

    def file_name sequence_number = next_sequence_number
      "#{credentials[:processor_code]}_#{credentials[:lender_code]}" \
        "#{file_type_indicator}"\
        "_#{credentials[:file_type]}_#{ Date.today.strftime("%Y%m%d") }_#{ sequence_number }.txt"
    end

    def returns_path
      "/To_#{ credentials[:processor_code] }"
    end

    def returns_files_pattern(date)
      "#{ credentials[:processor_code ] }_*_*_#{date.strftime('%Y%m%d')}_ToClnt*.*"
    end

    def parse_returns file
      CSV.read(file).map do |row|
        {
          transaction_id: row[29],
          nacha_code:     parse_nacha_code(row[23]),
          date:           parse_date(row[17]),
          description:    row[22]
        }
      end
    end

    def parse_date date_string
      Date.strptime(date_string, '%m/%d/%Y')
    rescue TypeError, ArgumentError
      Date.today
    end

    def parse_nacha_code code
      case code
      when 'R93'
        'V02'
      else
        code
      end
    end

    def batch_file_contents batch
      @file_generation_time = DateTime.now.to_s

      nacha = Guevara::Nacha.new(
        priority_code:    1,
        destination_id:   credentials[:destination],
        origin_id:        credentials[:origin],
        created_at:       @file_generation_time,
        id:               'A',
        destination_name: credentials[:destination_name],
        origin_name:      credentials[:origin_name],
        batches:          batches(batch)
      )

      nacha.to_s
    end

    # Viking is not capable of parsing multiple batches and ignores effective
    # dates. so we merge all the transactions in the same batch.
    def batches transactions
      [
        {
          service_class:  service_class(transactions),
          company_name:   credentials[:company_name],
          company_id:     credentials[:company_id],
          company_date:   @file_generation_time.to_s,
          origin_id:      credentials[:origin],
          effective_date: transactions.first.effective_date.to_s,
          discretionary_data: credentials[:discretionary_data],
          entry_description: credentials[:entry_description],
          transactions:   guevara_transactions(transactions)
        }
      ]
    end

    # build transactions for guevara
    def guevara_transactions batch
      batch.map do |transaction|
        {
          id: transaction.id,
          type: transaction.transaction_type.to_s,
          amount: (transaction.amount.to_f * 100).to_i,
          name: "#{transaction.first_name} #{transaction.last_name}",
          additional_info: [
            transaction.city,
            transaction.state,
            transaction.postal_code,
            transaction.address, ""].join('|'),
          account_type: transaction.account_type.to_s,
          routing_number: transaction.routing_number.to_i,
          account_number: transaction.account_number
        }
      end
    end

    def service_class batch
      case
      when batch.all? { |t| t.transaction_type == :debit }
        '225'
      when batch.all? { |t| t.transaction_type == :credit }
        '220'
      else
        '200'
      end
    end

    def push_remote_file_path
      "To_Viking/#{ file_name }"
    end

    def next_sequence_number
      glob  = file_name('*')
      files = connection.glob("To_Viking", glob)
      last_file = files.sort.last

      if last_file
        last_file.match(/(\d{1})\.txt/)[1].next
      else
        '0'
      end
    end

    def file_type_indicator
      credentials[:file_type][0]
    end

  end
end ; end
