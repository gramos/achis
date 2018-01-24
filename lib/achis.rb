require 'achis/version'
require 'achis/client'
require 'achis/transaction'

module Achis
  module Providers
    autoload :Transact24, 'achis/providers/transact_24'
    autoload :FFS, 'achis/providers/ffs'
    autoload :Payliance, 'achis/providers/payliance'
    autoload :Viking, 'achis/providers/viking'
    autoload :SARF, 'achis/providers/sarf'
  end
end
