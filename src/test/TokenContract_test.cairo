//To test the `TokenContract` contract, we need to ensure that the `transfer` and `balance_of` methods work as expected.
//This test scenario assumes a way to simulate the `get_caller_address` function in your test environment to control the address of the account that calls the contract's methods.

// TokenContract_test.cairo
use TokenContract;
use starknet::ContractAddress;

#[test]
#[available_gas(2000000)]
fn TokenContract_test() {
    // Initialize some arbitrary values for the test
    let total_supply = u256 { low: 1000_u128, high: 0_u128 };

    // Deploy the contract
    let contract = TokenContract.constructor(total_supply);

    // Creator's address should hold the total supply after contract creation
    let creator_address = ContractAddress(felt252(1), felt252(0));
    assert(contract.balance_of(creator_address).low == total_supply.low, 'invalid initial balance');

    // Attempt to transfer tokens from creator to another account
    let recipient_address = ContractAddress(felt252(2), felt252(0));
    let transfer_amount = u256 { low: 500_u128, high: 0_u128 };
    contract.transfer(recipient_address, transfer_amount);

    // Check balances after the transfer
    assert(
        contract.balance_of(creator_address).low == total_supply.low - transfer_amount.low,
        'invalid balance for creator'
    );
    assert(
        contract.balance_of(recipient_address).low == transfer_amount.low,
        'invalid balance for recipient'
    );

    // Attempt to transfer more tokens than available should fail
    let large_transfer_amount = u256 { low: 1500_u128, high: 0_u128 };
    try
    contract.transfer(recipient_address, large_transfer_amount);
    assert(try_end, 'transfer of amount greater than balance should fail');
}
