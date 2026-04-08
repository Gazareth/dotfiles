# Probes

Each probe receives an already-parsed treesitter node and interprets it into a normalised Atlantis shape. They do not parse text — that is treesitter's job. Probes translate the raw node into something Atlantis can act on uniformly across languages.

| Module | What it probes |
|---|---|
| `assignment` | Left/right sides of an assignment — name, value, jump targets |
| `identifier` | Symbol name and context for a bare identifier node |
| `binary_expression` | Operands and operator of a binary expression |
| `function` | Function name, parameters, body shape |
| `generic` | Fallback for any unrecognised node — returns minimal role/display info |
