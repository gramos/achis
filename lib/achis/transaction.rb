require 'achis/error'
require 'validated_accessors'
require 'achis/stripped_accessors'

module Achis

  # Normalized transactions that can be used to interact with any
  # provider.
  class Transaction
    extend ValidatedAccessors
    extend StrippedAccessors

    VALID_TRANSACTION_TYPES = [ :debit, :credit ]
    VALID_ACCOUNT_TYPES     = [ :saving, :checking ]

    # Date when the transaction should take place.
    # Should be a working day.
    attr_accessor :effective_date

    # Unique transaction ID.
    attr_accessor :id

    # Can be a `:debit` or `:credit`.
    validated_accessor(:transaction_type, valid: VALID_TRANSACTION_TYPES) { |t| t.to_sym }

    # Customer name.
    stripped_accessor :first_name, :last_name

    # Customer contact information.
    stripped_accessor :address, :city, :state, :postal_code, :telephone
    attr_accessor :email

    # Account number.
    attr_accessor :account_number

    # Unique Id for the bank.
    attr_accessor :routing_number

    # It can be a :saving or :checking
    validated_accessor(:account_type, valid: VALID_ACCOUNT_TYPES) { |t| t.to_sym }

    # In dolars.
    attr_accessor :amount

    def initialize attributes
      attributes.each do |attribute, value|
        send("#{ attribute }=", value)
      end
    end
  end
end
