module Achis

  # Stripped accessors follows the syntax of attr_accessor makes the getter
  # strip all the special characters.
  #
  # It also adds an extra getter to access the raw value if you need.
  #
  # @example
  #
  #   class Foo
  #     extend StrippedAccessors
  #     stripped_accessor :bar
  #   end
  #
  #   foo = Foo.new
  #   foo.bar = "ar%%s"
  #   foo.bar     #=> "ars"
  #   foo.raw_bar #=> "ar%%s"
  #
  module StrippedAccessors

    # adds some stripped attributes to the class
    #
    def stripped_accessor(*attributes)
      attributes.each do |attribute|
        attr_writer attribute
        define_method(attribute) do
          instance_variable_get("@#{attribute}").gsub(/[^\w\s]/, '')
        end
        define_method("raw_#{attribute}") do
          instance_variable_get("@#{attribute}")
        end
      end
    end

  end
end
