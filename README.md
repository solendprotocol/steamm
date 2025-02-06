# STEAMM

Build:`just sui build`

Sui Move Tests: `just sui test`

Typescript Tests (Atomically):
`just sui localnew` then `just sdk test`

Alternatively, run the tests setup manually:
- `just sui localnew` to spin up localnet
- `just sdk setup` to deploy contracts and setup on-chain state
- `bun test` to run tests
- `just sdk unset` to cleanup
