# Search API examples

Example requests and responses for `buf.registry.search.v1beta1`, validated against the
compiled schema with `buf convert`. Because this package has no server implementation in
this repository, the examples serve as both schema validation and documentation of the
request and response shapes.

## Running

```sh
make test
```

This runs `tests/run.sh` with the `buf` version pinned in the Makefile, and CI runs it on
every push. The script uses `.tmp/bin/buf` if present, otherwise `buf` on the `PATH`.

## Layout

- `usecases/`: example requests and responses that must parse against the schema. Each
  fixture is round-tripped to JSON so the parsed message is visible.
- `negative/`: malformed requests that must be rejected by the schema.

## Scope

`buf convert` validates structure: field names, enum values, scalar types, and message
nesting. It does not enforce the protovalidate constraints declared in the protos (for
example `page_size <= 250`, or that a fully-qualified name has no leading `.`); those are
applied at runtime.

## Examples

| # | RPC | Description |
|---|-----|-------------|
| 01 | SearchSymbols | Free-text Symbol search; response carries each match's coordinate. |
| 02 | SearchSymbols | Resolve a package by prefix, ordered by name. |
| 03 | SearchSymbols | Find a message; response includes the dependency and import to use it. |
| 04 | SearchSymbols | A Well-Known Type result, which needs no dependency. |
| 05 | SearchSymbols | Filter to deprecated fields within an Organization. |
| 06 | SearchSymbols | Search within a specific Label of a Module. |
| 07 | ListSymbolReferences | List the Symbols that reference a given Symbol. |
| 08 | SearchModules | Module search with a visibility filter. |
