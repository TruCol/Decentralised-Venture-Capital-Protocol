# Chain Interaction

This document describes how to interact with the (Solidity) blockchain. It is
based on [this](https://ethereum.org/en/developers/docs/apis/json-rpc/) link.

One thing to note is that you do not know in advance what the address of your
contract will be. Instead, you have to look at the transaction that you do to
deploy your contract, and then write down at what address the contract is
deployed.

## Documentation Example

You should find an url to post to, which hosts an Ethereum node, or you should
ask it to your local Ethereum network fork at localhost:xxxx

### Request

```sh
curl -X POST \
--data '{
  "jsonrpc":"2.0",
  "method":"eth_getBalance",
  "params":["0x407d73d8a49eeb85d32cf465507dd71d507100c1",
  "latest"],
  "id":1}'
```

### Result

```json
{
  "id":1,
  "jsonrpc": "2.0",
  "result": "0x0234c8a3397aab58" // 158972490234375000
}
```

## Stack Example

[Source](https://ethereum.stackexchange.com/questions/95023/hardhat-how-to-interact-with-a-deployed-contract/123005#123005)

```js
const MyContract = await ethers.getContractFactory("MyContract");
const contract = MyContract.attach(
  "0x..." // The deployed contract address
);

// Now you can call functions of the contract
await contract.doTheThing();
```

You may be able to remove the await.

## Payable Functions

Source: <https://docs.alchemy.com/docs/solidity-payable-functions>
