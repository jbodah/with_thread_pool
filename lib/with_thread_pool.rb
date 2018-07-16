require "with_thread_pool/version"
require "thread"

module WithThreadPool
  class ThreadPool
    def initialize(size)
      @queue = Queue.new
      @arr = ThreadSafeArray.new
      @threads = size.times.map { ThreadWorker.new(@queue, @arr) }
    end

    def schedule(idx, callable)
      @queue.enq([idx, callable])
    end

    def shutdown
      @threads.each do
        shutdown = ThreadWorker.method(:shutdown)
        @queue.enq([nil, shutdown])
      end
      @threads.map(&:join)
    end

    def result
      @arr.to_a
    end
  end

  class ThreadSafeArray
    include MonitorMixin

    def initialize
      @arr = []
      super
    end

    def []=(idx, val)
      synchronize { @arr[idx] = val }
    end

    def to_a
      synchronize { @arr }
    end
  end

  module ThreadWorker
    def self.shutdown
      throw(:exit)
    end

    def self.new(queue, arr)
      Thread.new do
        catch(:exit) do
          loop do
            idx, block = queue.deq
            arr[idx] = block.call
          end
        end
      end
    end
  end

  Enumerable.class_eval do
    def with_thread_pool(size)
      return to_enum(:with_thread_pool, size) unless block_given?
      pool = ThreadPool.new(size)
      self.each_with_index do |el, idx|
        pool.schedule(idx, proc { yield el })
      end
      pool.shutdown
      pool.result
    end
  end
end
