class IO
  module Platforms
    #
    # Typedefs
    #
    typedef :int32,   :tv_sec

    # attach to functions common to all POSIX-compliant platforms
    attach_function :open, [:pointer, :int, :int], :int, :blocking => true
    attach_function :close, [:int], :int, :blocking => true
    attach_function :read, [:int, :pointer, :size_t], :ssize_t, :blocking => true
    attach_function :pread, [:int, :pointer, :size_t, :off_t], :ssize_t, :blocking => true
    attach_function :pwrite, [:int, :pointer, :size_t, :off_t], :ssize_t, :blocking => true
    attach_function :write,       [:int, :pointer, :size_t], :ssize_t
    attach_function :socket, [:int, :int, :int], :int, :blocking => true
    attach_function :getaddrinfo, [:string, :string, :pointer, :pointer], :int, :blocking => true
    attach_function :freeaddrinfo, [:pointer], :int, :blocking => true
    attach_function :inet_ntop, [:int, :pointer, :pointer, :socklen_t], :string, :blocking => true
    attach_function :htons, [:uint16], :uint16, :blockinger => true
    attach_function :bind, [:int, :pointer, :socklen_t], :int, :blocking => true
    attach_function :connect, [:int, :pointer, :socklen_t], :int, :blocking => true
    attach_function :listen, [:int, :int], :int, :blocking => true
    attach_function :accept, [:int, :pointer, :pointer], :int, :blocking => true
    attach_function :ssend, :send, [:int, :pointer, :size_t, :int], :ssize_t, :blocking => true
    attach_function :sendmsg, [:int, :pointer, :int], :ssize_t, :blocking => true
    attach_function :sendto, [:int, :pointer, :size_t, :int, :pointer, :socklen_t], :ssize_t, :blocking => true
    attach_function :recv, [:int, :pointer, :size_t, :int], :ssize_t, :blocking => true
    attach_function :pipe, [:pointer], :int, :blocking => true
    attach_function :getsockopt, [:int, :int, :int, :pointer, :pointer], :int, :blocking => true

    # utilities
    attach_function :fcntl, [:int, :int, :int], :int, :blocking => true
    attach_function :getpagesize, [], :int

    class TimeValStruct < ::FFI::Struct
      layout \
        :tv_sec, :time_t,
        :tv_usec, :int32
    end

    class TimeSpecStruct < ::FFI::Struct
      layout \
        :tv_sec, :long,
        :tv_nsec, :long
    end
  end
end
