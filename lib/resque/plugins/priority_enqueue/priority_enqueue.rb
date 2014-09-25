

module Resque::Plugins
  module PriorityEnqueue
    module Resque

      def priority_push(queue,item)
        watch_queue(queue)
        redis.lpush "queue:#{queue}", encode(item)
      end

      def priority_enqueue(klass, *args)
        priority_enqueue_to(queue_from_class(klass), klass, *args)
      end

      def priority_enqueue_to(queue, klass, *args)
        # Perform before_enqueue hooks. Don't perform enqueue if any hook returns false
        before_hooks = Plugin.before_enqueue_hooks(klass).collect do |hook|
          klass.send(hook, *args)
        end
        return nil if before_hooks.any? { |result| result == false }

        Job.create(queue, klass, *args)

        Plugin.after_enqueue_hooks(klass).each do |hook|
          klass.send(hook, *args)
        end

        return true
      end


    end

  end
end

module Resque
  class Job

    class << self
      alias_method :original_create, :create

      def create(queue, klass, *args)
        Resque.validate(klass, queue)

        if Resque.inline?
          # Instantiating a Resque::Job and calling perform on it so callbacks run
          # decode(encode(args)) to ensure that args are normalized in the same manner as a non-inline job
          new(:inline, {'class' => klass, 'args' => decode(encode(args))}).perform
        else
          Resque.priority_push(queue, :class => klass.to_s, :args => args)
        end
      end
    end

  end
end

