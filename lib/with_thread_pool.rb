require "with_thread_pool/version"
require "thread"

module WithThreadPool
  class ThreadPool
    def initialize(size)
      @queue = Queue.new
      @threads = size.times.map { ThreadWorker.new(@queue) }
    end

    def schedule(callable)
      @queue.enq(callable)
    end

    def shutdown
      @threads.each do
        shutdown = ThreadWorker.method(:shutdown)
        @queue.enq(shutdown)
      end
      @threads.map(&:join)
    end
  end

  module ThreadWorker
    def self.shutdown
      throw(:exit)
    end

    def self.new(queue)
      Thread.new do
        catch(:exit) do
          loop do
            block = queue.deq
            block.call
          end
        end
      end
    end
  end

  Enumerable.class_eval do
    def with_thread_pool(size)
      return to_enum(:with_thread_pool, size) unless block_given?
      pool = ThreadPool.new(size)
      self.each do |el|
        pool.schedule(proc { yield el })
      end
    ensure
      pool.shutdown
    end
  end
end
