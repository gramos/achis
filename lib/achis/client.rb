require 'tempfile'
require 'achis/error'
require 'achis/return_record'

module Achis
  class Client

    class << self
      attr_accessor :connection_adapter_class
    end

    # A list of files sent and received to the provider.
    #
    # It is intended for backup of the interaction with the provider.
    # Should be consumed so the tempfiles that are created gets deleted.
    attr_accessor :processed_files
    attr_reader :credentials

    def initialize credentials = {}
      @credentials = credentials
      set_default_proc_for_credentials
      @processed_files = []
    end

    ##
    # Download return files and parse them
    #
    def pull(date)
      remote_files = connection.glob returns_path, returns_files_pattern(date)
      remote_files.map do |remote_path|
        local_file = download_file remote_path
        processed_files << local_file
        parse_returns(local_file).map{ |attrs| ReturnRecord.new attrs }
      end.flatten
    ensure
      close_connection
    end

    ##
    # Upload a batch of payment transactions, it first generate
    # the csv file.
    #
    def push batch
      raise EmptyBatchError if batch.empty?
      batch      = batch.map{ |t| Transaction.new t } if batch.first.is_a? Hash
      batch_file = write_tmp_file! file_name, batch_file_contents(batch)
      connection.send_file batch_file.path, push_remote_file_path
      @processed_files << batch_file
    ensure
      close_connection
    end

    def connection
      @connection ||= self.class.connection_adapter_class.start(*connection_settings)
    end

    private

    def set_default_proc_for_credentials
      @credentials.default_proc = proc do |_, key|
        value_from_env = ENV["ACHIS:#{provider_name.upcase}:#{key.upcase}"]
        err_msg        = "#{ key } is required for #{ self.class }."

        raise MissingCredentialError, err_msg if value_from_env.nil?
        value_from_env
      end
    end

    ##
    # download a file from the remote to a well named tempfile
    #
    def download_file remote_path
      file_contents = connection.get_file(remote_path)
      local_file_name = remote_path.split("/").last
      write_tmp_file! local_file_name, file_contents
    end

    def write_tmp_file!(file_name, file_content)
      raise ArgumentError, "file_name can't be nil!" if file_name.nil?

      Tempfile.open(file_name) do |f|
        f.puts file_content
        f
      end
    end

    def file_date
      Date.today.strftime('%Y-%m-%d')
    end

    def close_connection
      connection.close if @connection
      @connection = nil
    end
  end
end
