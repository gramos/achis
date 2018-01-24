require 'double_bag_ftps'

module Achis
  module ConnectionAdapters

    # Adapts the DoubleBagFTPS implementation to work as an abstract
    # connection object.
    #
    # A debug mode can be enabled with the environment variable 'DEBUG_CONNECTION'
    class FTPS

      attr_accessor :ftps

      def self.start(*args)
        new(*args)
      end

      # Connect to the server and log in.
      #
      # @option options [:implicit, nil] :ftps_mode set the connection mode
      # @option options [:none, nil] :verify set to :none to disable ssl verification
      #
      # @raise ArguementError when the host is nil or emtpy to find
      #   errors earlier
      #
      # The ACHIS_ENV environment variable can be set to TEST to disable
      # the connection for testing internals.
      #
      def initialize host, user, password, account = nil, options = {}
        raise ArgumentError, 'A host is required' unless host && !host.empty?
        @host      = host
        @user      = user
        @password  = password
        @account   = account
        @options   = options

        setup
        connect unless ENV['ACHIS_ENV'] == 'test'
      end

      def send_file file_path, remote_path
        ftps.puttextfile file_path, remote_path
      end

      def get_file remote_path
        ftps.gettextfile(remote_path, nil).force_encoding('UTF-8')
      end

      def remove(file_remote_path)
        ftps.delete file_remote_path
      end

      # search files matching a pattern in a given path
      #
      # this get rid of the differences between the different
      # implementations
      #
      # path should not include the final '/'
      def glob path, pattern
        path = "#{ path}/"
        matching_files = nlst(path).select do |remote_file|
          File.fnmatch pattern, remote_file.gsub(path, '')
        end

        matching_files.map do |file|
          if file.include? path
            file
          else
            File.join(path, file)
          end
        end
      end

      def close
        ftps.close
      end

      private

      def setup
        self.ftps         = DoubleBagFTPS.new
        ftps.passive      = true
        ftps.debug_mode   = true if ENV['DEBUG_CONNECTION']
        ftps.ftps_mode    = DoubleBagFTPS::IMPLICIT if @options[:ftps_mode] == :implicit
        ftps.ssl_context  = ssl_context
      end

      def connect
        ftps.connect @host
        ftps.login @user, @password, @account
      end

      def nlst(path)
        ftps.nlst(path)
      end

      def ssl_context
        ssl_context_params = {}
        ssl_context_params[:verify_mode] = OpenSSL::SSL::VERIFY_NONE if @options[:verify] == :none
        DoubleBagFTPS.create_ssl_context(ssl_context_params)
      end

    end
  end
end
