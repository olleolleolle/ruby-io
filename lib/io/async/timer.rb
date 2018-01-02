class IO
  module Async

    class Timer
      # Time is additive, so if given +seconds+, +milliseconds+, and
      # +nanoseconds+ then they will all be added together for a
      # total timeout.
      def self.sleep(seconds: 0, milliseconds: 0, nanoseconds: 0)
        Private.setup
        @timeout = (seconds * 1_000) + milliseconds + (nanoseconds / 1_000)
        Internal::Backend::Async.timer(duration: @timeout)
      end
    end

  end
end

