module Achis
  class ReturnRecord

    # Unique ID provided to identify the transaction
    #
    # @return [String] It should be eq to the transaction.id used in the push.
    #   It should always be 12 characters long with alfanumeric
    #   characters.
    #
    attr_accessor :transaction_id
    alias_method :unique_transaction_id, :transaction_id

    # Nacha like code
    #
    # @return [String] a single uppercase letter followed by two digits
    #
    # Standard return codes are used when possible, but as Achis will
    # parse everything (validations, settlements, etc.) non standard
    # codes are also used. 'V' codes for validations, 'C' codes for
    # corrections and 'S' codes for settlements.
    #
    attr_accessor :nacha_code
    alias_method :return_reason_code, :nacha_code

    attr_accessor :date
    alias_method :return_date, :date

    # Human readable description
    #
    # @return [String] The description provided not meant to be machine
    #   parseable, neither stable.
    #
    attr_accessor :description
    alias_method :correction_detail, :description

    def initialize attributes
      attributes.each do |key, value|
        send "#{ key }=", value
      end
    end
  end
end
