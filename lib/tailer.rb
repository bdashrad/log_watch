# require 'rbconfig'
# include RbConfig

# Tailer module
module Tailer
  autoload :Bsd, 'tailer/bsd'
  autoload :Linux, 'tailer/linux'
  autoload :Default, 'tailer/default'
end
