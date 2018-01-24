require 'csv'

module Achis ; module Formatters
  module Csv

    def row_separator
      "\n"
    end

    def batch_file_contents batch
      CSV.generate(:row_sep => row_separator) do |csv|
        make_header(csv) if respond_to?(:file_header, :true)
        batch.each { |t| csv << generate_row(t) }
        csv << file_footer(batch) if respond_to?(:file_footer, :true)
      end
    end

    def make_header(csv)
      file_header.each do |header|
        csv << header
      end
    end

  end
end ; end
