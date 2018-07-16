RSpec.describe WithThreadPool do
  it "returns the correct result" do
    10.times do
      result =
        [1,2,3].with_thread_pool(5) do |n|
          dur = [0, 0.1, 0.2].sample
          sleep(dur)
          n
        end
      expect(result).to eq([1,2,3])
    end
  end

  it "runs blocks concurrently" do
    call_orders =
      10.times.map do
        mutex = Mutex.new
        call_order = []

        [1,2,3].with_thread_pool(5) do |n|
          dur = [0, 0.1, 0.2].sample
          sleep(dur)
          mutex.synchronize { call_order << n }
          n
        end

        call_order
      end

    all_in_order = call_orders.all? { |order| order == [1,2,3] }
    expect(all_in_order).to be(false)
  end

  it "returns the correct class" do
    return_class = (1..10).with_thread_pool(5) { |n| n }.class
    expect(return_class).to be(Array)
  end
end
