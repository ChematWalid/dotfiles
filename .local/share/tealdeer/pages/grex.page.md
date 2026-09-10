# grex

> Command-line tool and library for generating regular expressions from user-provided test cases.

- Generate regex from string arguments:
  `grex "a" "b" "c"`

- Generate regex with digit/word shorthand:
  `grex -s "2026-09-11" "2026-10-15"`

- Generate case-insensitive regex:
  `grex -c "apple" "Apple" "APPLE"`
