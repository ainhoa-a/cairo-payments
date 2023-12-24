// AutoPaymentContract_test.cairo
use AutoPaymentContract;
use starknet::transaction::StarkNetTransaction;
use starknet::transaction::StarkNetTransactionKind;

#[test]
#[available_gas(2000000)]
fn AutoPaymentContract_test() {
    // Initialize some arbitrary values for the test
    let owner = ContractAddress(felt252(1), felt252(0));
    let user_address = ContractAddress(felt252(2), felt252(0));
    let token_contract_address = ContractAddress(felt252(3), felt252(0));
    let merchant_address = ContractAddress(felt252(4), felt252(0));
    let payment_frequency = felt252(60); // 1 minute for test purposes
    let maximum_amount = u256 { low: 100_u128, high: 0_u128 }; // 100 tokens max

    // Deploy the contract
    let contract = StarkNetTransaction {
        kind: StarkNetTransactionKind.CONTRACT_DEPLOYMENT,
        contract: AutoPaymentContract,
        arguments: (
            owner,
            user_address,
            token_contract_address,
            merchant_address,
            payment_frequency,
            maximum_amount
        )
    }
        .execute();

    // Get the contract's state
    let contract_state = contract.get_state();

    // Check the initial state
    assert(contract_state.owner == owner);
    assert(contract_state.user_address == user_address);
    assert(contract_state.token_contract_address == token_contract_address);
    assert(contract_state.merchant_address == merchant_address);
    assert(contract_state.payment_frequency == payment_frequency);
    assert(contract_state.maximum_amount.low == maximum_amount.low);
    assert(contract_state.maximum_amount.high == maximum_amount.high);
    assert(contract_state.last_payment_time == 0);

    // Execute the charge function
    contract.charge();

    // Check the state after charging
    assert(contract_state.last_payment_time > 0);
// other state checks...
}
