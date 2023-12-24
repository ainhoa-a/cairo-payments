// DelegableAccount_test.cairo
//Testing the `DelegableAccount` contract will involve checking:
//Whether only the owner can approve contracts.
//Whether only approved contracts can initiate transfers.

use DelegableAccount;
use starknet::transaction::StarkNetTransaction;
use starknet::transaction::StarkNetTransactionKind;

#[test]
#[available_gas(2000000)]
fn DelegableAccount_test() {
    // // Initialize values for the test
    let owner = ContractAddress(felt252(1), felt252(0));
    let token_contract_address = ContractAddress(felt252(3), felt252(0));

    // Mock the IERC20 contract
    // This is pseudocode. The StarkNet ecosystem may not support this kind of operation as of my knowledge cut-off in September 2021.
    let mock_ierc20 = MockIERC20.new();
    mock_ierc20.expect_transfer().returning('|_', '_|', Ok(()));

    // Replace the token_contract_address with the address of the mock contract
    token_contract_address = mock_ierc20.address;

    // Deploy the contract
    let contract = StarkNetTransaction {
        kind: StarkNetTransactionKind.CONTRACT_DEPLOYMENT,
        contract: DelegableAccount,
        arguments: (owner, token_contract_address),
    }
        .execute();

    // Attempt to approve a contract from a non-owner address, this should fail
    let non_owner = ContractAddress(felt252(2), felt252(0));
    let result = contract.approve_contract(non_owner);
    assert(result.is_err(), 'Non-owner should not be able to approve contracts');

    // Now approve a contract as the owner, this should succeed
    let contract_to_approve = ContractAddress(felt252(4), felt252(0));
    contract.approve_contract(contract_to_approve);

    // Attempt a transfer from an unapproved contract, this should fail
    let recipient = ContractAddress(felt252(5), felt252(0));
    let amount = u256 { low: 100_u128, high: 0_u128 };
    result = contract.transfer(recipient, amount);
    assert(result.is_err(), 'Unapproved contract should not be able to initiate transfers');

    // Attempt a transfer from an approved contract, this should succeed and IERC20.transfer should be called
    contract.transfer(contract_to_approve, amount);

    // Check if the transfer method was called correctly on the mock contract
    mock_ierc20.assert_expectations_met();
}
