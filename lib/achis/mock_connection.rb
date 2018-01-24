module Achis

  # This class should ease testing and making dry-runs that do not send any
  # real transactions, but should behave as a real connection.
  #
  class MockConnection

    class << self
      attr_accessor :remote_files, :mocks, :sent_files, :started_with, :open,
                    :warnings
    end

    self.remote_files = []
    self.mocks        = {}
    self.sent_files   = []
    self.warnings     = []

    # setup the connection
    #
    # @param *args arguments that would be received by the connection
    #   adapter, can be checked later with started_with.
    #
    def initialize *args
      self.class.started_with = *args
      self.class.open         = true
    end

    def self.start(*args)
      new(*args)
    end

    def send_file file_path, remote_path
      self.class.sent_files   << { local_file: file_path, remote_path: remote_path }
      self.class.remote_files << remote_path

      raise 'Connection wasn\'t open yet' unless open?
    end

    def close
      self.class.open = false
    end

    def open?
      self.class.open
    end

    def closed?
      !open?
    end

    def glob path, pattern
      files = self.class.remote_files.select do |remote_file|
        File.fnmatch("#{ path }/#{ pattern }", remote_file)
      end
      if files.empty?
        self.class.warnings << <<-WARNING.gsub(/^\s*\|/, '')
        | Found no files with the glob.
        | Searched the path: #{ path }
        | With the pattern:  #{ pattern }
        | The mocked files are: #{ self.class.remote_files.inspect }
        WARNING
      end
      files
    end

    def get_file remote_path
      self.class.mocks[remote_path] or raise "'#{ remote_path }' is not mocked"
    end

    def self.setup_mock_file remote_path, mock_object
      remote_files << remote_path
      mocks[remote_path] = mock_object
    end

    # mocks should only work once
    def self.teardown_mocks
      self.remote_files = []
      self.sent_files   = []
      self.mocks        = {}
      self.warnings     = []
    end

  end
end
