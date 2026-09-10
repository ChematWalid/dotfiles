# hyperfine

> High-performance command-line benchmarking tool written in Rust.

- Benchmark a single command:
  `hyperfine '<command>'`

- Compare performance between multiple commands:
  `hyperfine '<command1>' '<command2>'`

- Run with warmups before measuring:
  `hyperfine --warmup 3 '<command>'`

- Export benchmark results to Markdown:
  `hyperfine --export-markdown results.md '<cmd1>' '<cmd2>'`
