# arglet

[![Package Version](https://img.shields.io/hexpm/v/arglet?style=for-the-badge&color=75618E)](https://hex.pm/packages/arglet)
[![Hex Docs](https://img.shields.io/website?url=https%3A%2F%2Farglet.hexdocs.pm%2F&style=for-the-badge&label=hex&up_message=docs&up_color=FF891F&down_message=not%20found&down_color=lightgrey)](https://arglet.hexdocs.pm/)
[![Tests](https://img.shields.io/github/actions/workflow/status/peregrinefinch/arglet/test.yml?branch=main&style=for-the-badge&label=tests)](https://github.com/peregrinefinch/arglet/actions/workflows/test.yml)

A little argument parser for Pooka. Give each option a name, and let the words find their seats.

```sh
pooka add arglet
```

```pooka
module main

import arglet

main() {
  let expected = [arglet.flag("quiet", "q", "Say less")]
  let assert Ok(args) = arglet.parse(arglet.arguments(), expected)
  echo args.has("quiet")
}
```

Long and short options, grouped switches, repeated values and `--` are welcome.
Read the [documentation](https://arglet.hexdocs.pm/) for the rest of the guest list.

## Licence

Licensed under the [Apache License, Version 2.0](LICENSE).
