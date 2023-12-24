use RePay::{ContractState, approve, deposit, pull_payment, get_balance};

#[test]
#[available_gas(300000)]
fn test_pull_payment_contract() {
    let alice = starknet::account_address_const::<0x1234>();
    let bob_contract = starknet::account_address_const::<0x5678>();

    // Deploy the RePay.
    let (pull_payment_contract_address, _) = deploy_syscall(
        RePay::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        Default::default().span(),
        false
    )
        .unwrap();
    let pull_payment_contract = RePayDispatcher {
        contract_address: pull_payment_contract_address
    };

    // Alice deposits 0.1 ETH into her account.
    deposit(pull_payment_contract.clone(), alice, 0.1);

    // Alice authorizes the contract to pull 0.02 ETH from her account every month.
    approve(pull_payment_contract.clone(), alice, bob_contract, 0.02);

    // A month passes.
    starknet::testing::advance_blocks(4000000); // Assuming ~4 million blocks per month.

    // Bob's contract triggers a transaction to pull the 0.02 ETH from Alice's account.
    pull_payment(pull_payment_contract.clone(), alice, bob_contract, 0.02);

    // Check Alice's balance, it should be 0.1 - 0.02 = 0.08 ETH.
    let alice_balance = get_balance(pull_payment_contract.clone(), alice);
    assert_eq(alice_balance, 0.08, 'unexpected alice balance');

    // Check Bob's contract balance, it should be 0.02 ETH.
    let bob_contract_balance = get_balance(pull_payment_contract, bob_contract);
    assert_eq(bob_contract_balance, 0.02, 'unexpected bob contract balance');
}
