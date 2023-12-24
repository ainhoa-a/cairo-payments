//Testing the `WalletContract` contract would involve:

//Checking whether the `approve_new_contract` method correctly calls the `add_approved_contract` method of the `DelegableAccount` contract.
//Verifying that the `view_auto_payment_contract_details` method correctly calls the `get_details` method of the `AutoPaymentContract` contract.

// WalletContract_test.cairo
use WalletContract;
use starknet::transaction::StarkNetTransaction;
use starknet::transaction::StarkNetTransactionKind;

#[test]
#[available_gas(2000000)]
fn WalletContract_test() {
    // Initialize some arbitrary values for the test
    let owner = ContractAddress(felt252(1), felt252(0));
    let delegable_account = ContractAddress(felt252(2), felt252(0));

    // Mock the IDelegableAccount and IAutoPaymentContract contracts
    // This is pseudocode. The StarkNet ecosystem may not support this kind of operation as of my knowledge cut-off in September 2021.
    let mock_delegable_account = MockIDelegableAccount.new();
    mock_delegable_account.expect_add_approved_contract().returning('|_|', Ok(()));

    let mock_auto_payment_contract = MockIAutoPaymentContract.new();
    mock_auto_payment_contract.expect_get_details().returning('||', Ok(()));

    // Replace the delegable_account with the address of the mock contract
    delegable_account = mock_delegable_account.address;

    // Deploy the contract
    let contract = StarkNetTransaction {
        kind: StarkNetTransactionKind.CONTRACT_DEPLOYMENT,
        contract: WalletContract,
        arguments: (owner, delegable_account)
    }
        .execute();

    // Attempt to approve a new contract, this should succeed and IDelegableAccount.add_approved_contract should be called
    let contract_to_approve = ContractAddress(felt252(4), felt252(0));
    contract.approve_new_contract(contract_to_approve);
    mock_delegable_account.assert_expectations_met();

    // Attempt to view auto payment contract details, this should succeed and IAutoPaymentContract.get_details should be called
    let auto_payment_contract = ContractAddress(felt252(5), felt252(0));
    contract.view_auto_payment_contract_details(auto_payment_contract);
    mock_auto_payment_contract.assert_expectations_met();
}
