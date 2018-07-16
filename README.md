# with_thread_pool

simple lib for wrapping your enumerators with thread pools

## Usage

```
ruby -rwith_thread_pool -e '(1..10).with_thread_pool(5) { |n| sleep (0..3).to_a.sample; puts n }'
```
