# Decentralised Investment Protocol [![Open in Gitpod][gitpod-badge]][gitpod] [![Github Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

This is a decentralised investment protocol for SAAS applications. Investors
can see what the project lead proposes to do with the investment, along with
the proposed multiple ROI (e.g. 20 times the initial investment amount).
The investor can then evaluate the project and estimate whether the project
has a probability of more than `1/20 = 5 [%]` of returning the whole multiple
they may receive for their investment.

Three investment tiers are supported, each with different ROI multiples. E.g.

- Tier 0: 0 to 4 ether, multiple ROI: 10x.
- Tier 0: 4 to 15 ether, multiple ROI: 5x.
- Tier 15: 4 to 30 ether, multiple ROI: 2x.

The idea is that in later stages of investment, the risk becomes lower as more
data is available on whether the project will succeed or not, hence a lower ROI
multiple is offered.

All investors are made whole at the same time, if they are made whole,
regardless of when they invested. Early investors have the advantage of a
higher ROI (if they invested in an earlier investment tier).

The project lead gets a fixed fraction of the SAAS revenue until the investors
are made whole, then the project lead receives all the SAAS payments.

The project lead **alone** can get the investments out of the contract and
distribute it to workers, or allow the workers to retrieve their own investment
fraction.

## Risks

Primary risk is the project lead using a different SAAS payment address to gain
its income. This requires trust in the project lead. Otherwise, all
transactions are automated. An ideal application of this protocol would
include a method to verify the SAAS service is developed as expected, e.g. a
streaming service that provides access to all songs in spotify, through
hashrate. This verification is considered out of scope.

Secondary risk is that this contract is hacked:

- (Branch) code coverage is well below 100%.
- No fuzztests are implemented.
- No formal verification is performed.
- No security-audit is performed.
- No stake on its security is applied.

Ternary risk is that the project may not yield (enough) SAAS revenue to
provide the investors with (their whole) ROI multiple.

## Why

- This can give ordinary people access to opportunities typically only reserved
  for venture capitalists.
- It provides an automated way to negotiate with all venture capitalists (and
  people) simultaneously, rather than going to all their websites, tailoring the
  pitchdecks to their demands, and spending time and resources in the
  negotiations.

## Deployment Prerequisites

```sh
# Install repository configuration.
sudo snap install bun-js
bun install # install Solhint, Prettier, and other Node.js deps
pre-commit install

# Facilitate branch coverage checks.
sudo apt install lcov

# Install foundry
sudo apt install curl -y
curl -L https://foundry.paradigm.xyz | bash
source ~/.bashrc
foundryup
forge build

# Install pre-commit
pre-commit install
git add -A && pre-commit run --all
```

## Build

Build the contracts:

```sh
bun install # run this once.
forge build
```

(If that does not show that the contracts are compiled/does not work, you
probably have the wrong forge, a snap package for Ubuntu installed. See
[solution](https://ethereum.stackexchange.com/questions/139754/when-i-type-forge-init-force-forge-init)
)

## Clean

Delete the build artifacts and cache directories:

```sh
forge clean
```

## Compile

Compile the contracts:

```sh
forge build
```

## Test

Run the tests:

```sh
forge test -vvv
```

Or to run a single test (function):

```sh
clear && forge test --vvv --match-test testInvestorGetsSaasRevenue
```

The `-vvv` is necessary to display the error messages that you wrote with the
assertions, in the CLI. Otherwise it just says: "test failed".

## Branch Code Coverage Report

Get a test coverage report:

```sh
forge coverage --report lcov
genhtml -o report --branch-coverage lcov.info
```

## Gas Usage

Get a gas report:

```sh
forge test --gas-report
```

## Deploy Locally

Deploy to Anvil, first open another terminal, give it your custom `MNEMONIC` as
an environment variable, and run anvil in it:

````sh
# This is a random generated hash with 0 test eth, and the Ethereum test
# network `ethereum-sepolia`
# [faucet](https://www.alchemy.com/faucets/ethereum-sepolia) keeps saying:
# "complete captcha", without showing the captcha (Add block was disabled).
```sh
export MNEMONIC="pepper habit setup conduct material wagon\
captain liquid ill confirm cube easy iron tackle timber"
````

If you can get the faucet to give you test-ETH, you can use your own MNEMONIC
(see [BIP39 mnemonic](https://iancoleman.io/bip39/).). Luckily foundry provides
a standard test wallet with 1000 ETH in it, which can be used with:

```sh
export MNEMONIC="test test test test test test test test test test test junk"
```

While Anvil runs in the background on another terminal, open a new terminal
and run:

```sh
forge script script/Deploy.s.sol --broadcast --fork-url http://localhost:8545
```

By default, this deploys to the HardHat Chain 31337.

## Deploy to Mainnet

For instructions on how to deploy to a testnet or mainnet, check out the
[Solidity Scripting](https://book.getfoundry.sh/tutorials/solidity-scripting.html)
tutorial.

## GitHub Actions

This template comes with GitHub Actions pre-configured. Your contracts will be
linted and tested on every push and pull request made to the `main` branch.

You can edit the CI script in
[.github/workflows/ci.yml](./.github/workflows/ci.yml).

## Related Efforts

- [abigger87/femplate](https://github.com/abigger87/femplate)
- [cleanunicorn/ethereum-smartcontract-template](https://github.com/cleanunicorn/ethereum-smartcontract-template)
- [foundry-rs/forge-template](https://github.com/foundry-rs/forge-template)
- [FrankieIsLost/forge-template](https://github.com/FrankieIsLost/forge-template)

## License

This project is licensed under MIT.

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[gha]: https://github.com/TruCol/foundry-template/actions
[gha-badge]: https://github.com/TruCol/foundry-template/actions/workflows/ci.yml/badge.svg
[gitpod]: https://gitpod.io/#https://github.com/TruCol/foundry-template
[gitpod-badge]: https://img.shields.io/badge/Gitpod-Open%20in%20Gitpod-FFB45B?logo=gitpod
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg
