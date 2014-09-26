
require "resque/plugins/priority_enqueue/version"

require 'resque'
require 'resque/job'
require 'resque/plugin'
require 'resque/plugins/priority_enqueue/priority_enqueue'

Resque.send(:extend, Resque::Plugins::PriorityEnqueue::Resque)


