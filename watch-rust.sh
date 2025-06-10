# Re-build rust libraries whenever rust source code changes
(cd rust && cargo build && while inotifywait -e close_write src/**/*.rs; do cargo build; done)
