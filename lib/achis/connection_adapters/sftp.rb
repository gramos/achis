require 'net/sftp'

module Achis
  module ConnectionAdapters
    class SFTP

      def self.start(*args)
        new(*args)
      end

      def initialize host, username, options
        raise ArgumentError, 'A host is required' unless host && !host.empty?
        @sftp = ::Net::SFTP.start host, username, options
      end

      def send_file file_path, remote_path
        @sftp.upload! file_path, remote_path
      end

      def get_file remote_path
        @sftp.download! remote_path
      end

      def remove(file_remote_path)
        @sftp.remove file_remote_path
      end

      def glob path, pattern
        @sftp.dir.glob(path, pattern).map{|e| "#{path}/#{e.name}" }
      end

      def close
        @sftp.session.close
      end
    end
  end
end
