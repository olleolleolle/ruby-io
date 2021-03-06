require 'io/internal/states/file/closed'
require 'io/internal/states/file/readonly'
require 'io/internal/states/file/readwrite'
require 'io/internal/states/file/writeonly'

class IO
  module Async
    class File
      include Mixins::Enumerable

      class << self
        def open(path:, flags: nil, timeout: nil, error_policy: nil)
          Private.setup
          mode = Config::Mode.from_flags(flags)
          result = Internal::Backend::Async.open(path: path, flags: flags.to_i, mode: mode.to_i, timeout: timeout)

          if result[:rc] > 0
            if flags.readwrite?
              File.new(fd: result[:rc], flags: flags, mode: mode, state: :readwrite, error_policy: error_policy)
            elsif flags.readonly?
              File.new(fd: result[:rc], flags: flags, mode: mode, state: :readonly, error_policy: error_policy)
            elsif flags.writeonly?
              File.new(fd: result[:rc], flags: flags, mode: mode, state: :writeonly, error_policy: error_policy)
            else
              raise "Unknown file mode!!!"
            end
          else
            nil
          end
        end
      end

      def initialize(fd:, flags:, mode:, state: :readonly, error_policy:)
        @creator = Thread.current
        Private.setup
        @policy = error_policy || Config::Defaults.error_policy
        read_cache = Internal::PReadCache.new(io: self, size: Config::Defaults.read_cache_size)

        @context = if :readonly == state
          Internal::States::File::ReadOnly.new(fd: fd, backend: Internal::Backend::Async, read_cache: read_cache)
        elsif :writeonly == state
          Internal::States::File::WriteOnly.new(fd: fd, backend: Internal::Backend::Async)
        elsif :readwrite == state
          Internal::States::File::ReadWrite.new(fd: fd, backend: Internal::Backend::Async, read_cache: read_cache)
        else
          Internal::States::File::Closed.new(fd: -1, backend: Internal::Backend::Async)
        end
      end

      def to_i
        safe_delegation do |context|
          context.to_i
        end
      end

      def close(timeout: nil)
        safe_delegation do |context|
          rc, errno, behavior = context.close
          [rc, errno]
        end
      end

      # Reads +nbytes+ starting at +offset+ from the file and puts
      # the result into +buffer+. Buffer must be a FFI::MemoryPointer
      # large enough to accommodate +nbytes+.
      #
      # When no +buffer+ is given by the user, the system will allocate
      # its own. Given a successful read operation, this method will return
      # an array in the order:
      #  [return_code, error_number, string, new_offset]
      #
      # When user has provided their own buffer, a successful read operation
      # will return an array in the order:
      #  [return_code, error_number, nil, new_offset]
      #
      # In this case, the user is expected to extract the string from the
      # +buffer+ manually.
      #
      def read(nbytes:, offset:, buffer: nil, timeout: nil)
        safe_delegation do |context|
          rc, errno, string = context.read(nbytes: nbytes, offset: offset, buffer: buffer, timeout: timeout)

          offset = rc >= 0 ? offset + rc : offset
          block_given? ? yield([rc, errno, string, offset]) : [rc, errno, string, offset]
        end
      end

      def __pread__(nbytes:, offset:, buffer: nil, timeout: nil)
        safe_delegation do |context|
          rc, errno, string = context.__pread__(nbytes: nbytes, offset: offset, buffer: buffer, timeout: timeout)

          offset = rc >= 0 ? offset + rc : offset
          block_given? ? yield([rc, errno, string, offset]) : [rc, errno, string, offset]
        end
      end

      # Writes +string.bytesize+ bytes starting at +offset+ into file.
      #
      # A successful write returns an array in the order:
      #  [return_code, error_number, new_offset]
      #
      def write(offset:, string:, timeout: nil)
        safe_delegation do |context|
          rc, errno = context.write(offset: offset, string: string, timeout: timeout)
          offset = rc >= 0 ? offset + rc : offset
          block_given? ? yield([rc, errno, offset]) : [rc, errno, offset]
        end
      end


      private

      def safe_delegation
        # Always call Private.setup. User may have created object in a thread and
        # already run Private.setup. However, transferring the object to another
        # thread means that it might not have the same async setup performed yet, so
        # any instance method must check first and perform setup.
        Private.setup
        if Config::Defaults.multithread_policy.check(io: self, creator: @creator)
          yield @context
        end
      end

      def update_context(behavior)
        @context = behavior
      end
    end
  end
end
