
# Cairo Payments

## Project Overview 

Cairo payments project enables recurring payments via a delegated account and custodial wallet, leveraging L2 Starknet Cairo 1.0. Cairo 1.0 is the upgraded Rust-inspired version of Cairo,
Cairo 1.0 is a rust-inspired fully typed language, making writing the same logic much easier and less error-prone. The following delineates the detailed specifications:

Firstly, the merchant launches an 'AutoPaymentContract.cairo', an automatic payment smart contract. A user with a 'DelegableAccount.cairo', when browsing the merchant's site, will encounter a request for approving recurring payments. The user can review the procedures the auto payment contract will perform on their behalf. These procedures include:

- The user is charged only once monthly.
- Charging cannot exceed a preset maximum amount.
- The user has assurance that the auto payment contract execution adheres strictly to its predetermined terms.
- All payments utilize ERC20 tokens.

Once the user consents to authorize recurring payments, the wallet includes the auto payment contract's address in the user's delegable account's list of approved contracts. Subsequently, the merchant activates a payment by invoking the auto payment contract's charge function, leading the user's account to initialize a push payment, which is valid due to its inclusion in the user's approved list.

## Components

1. `Merchant's Auto Payment Smart Contract`: A contract deployed by the merchant comprising the auto payment rules, such as charging frequency and maximum limit.
2. `User's Delegable Account`: The user's account that will be debited, housing a list of permitted contracts that can initiate its transactions.
3. `Wallet`: The user's interaction interface, handling the process of adding the auto payment contract to the user's delegable account upon approval.
4. `Token Contract`: The contract managing the payment token, facilitating the transfer of tokens from the user's account to the merchant's account.

## Workflow

`Auto Payment Contract Deployment`: The merchant formulates and deploys a smart contract on StarkNet with Cairo 1.0. This contract houses the auto payment logic, including frequency and amount restrictions, and a charge function to initialize a payment.
`Auto Payments Approval`: Users visiting the merchant's website are requested to authorize auto payments. This is managed by the user's wallet, detailing the auto payment contract and seeking user approval. The wallet adds the auto payment contract's address to the user's delegable account's approved contracts list if the user consents.
`Payment Initiation`: The merchant activates the payment by invoking the auto payment contract's charge function during payment time. The contract prompts a transaction on the user's delegable account. Given that the auto payment contract's address is included in the user's approved list, the transaction is deemed valid.
`Payment Processing`: As far as the token contract is concerned, this transaction is identical to any other, transferring the specified token amount from the user's account to the merchant's account.

## Contracts:

 `AutoPaymentContract`: This contract, owned by the merchant, stores payment processing details like frequency, maximum amount, user address, token contract address, and merchant's receiving address. It should also feature a `charge` function to check if payment criteria are met and then engage with the `TokenContract` to transfer funds. The charge function also verifies if the transfer amount doesn't exceed the user's balance at the time of transfer.This contract allows the owner to change the payment frequency and maximum amount.
`DelegableAccount`: This contract denotes the user's account and should feature an approved contracts list and a function to add a contract to this list. If an approved contract requests a token transfer, the `DelegableAccount` should liaise with the `TokenContract` to facilitate the transfer. This contract has a function to revoke approval for a contract. This will provide users the ability to disallow previously allowed contracts.
`WalletInterface`: This contract serves as the user's interaction interface with their `DelegableAccount`, featuring functions to approve a new contract (which includes it in the `DelegableAccount's` list of approved contracts) and to view the `AutoPaymentContract` details.
`TokenContract`: This contract manages the payment token and should feature a function to transfer tokens between accounts. This contract includes an approval mechanism. It will allow tracking of how much an account is allowed to withdraw from another account, which will be beneficial for the AutoPaymentContract. ERC20 tokens are used to charge payments.
