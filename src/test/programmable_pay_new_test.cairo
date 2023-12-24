// auto_pay_test.cairo

use DelegateAutoPayAccount_new;
use starknet::ContractAddress;
use ecdsa::generate_key_pair;

struct RecurringPayment {
    contract: DelegateAutoPayAccount,
    amount_per_month: felt,
}

fn make_payment_and_check_balance(
    payment: RecurringPayment,
    num_months: felt,
    payment_interval: felt,
    signature: felt,
    nonce: felt
) {
    let i: felt = 0;
    while
    i < num_months
    payment.contract.make_payment(); // make payment
    let balance = payment.contract.get_balance();
    assert(balance == payment.amount_per_month * (2 - i), 'Payment was not made or was incorrect.');
    i = i + 1;
}

fn advance_time_and_check_payments(
    payment: RecurringPayment, num_months: felt, payment_interval: felt
) {
    let i: felt = 0;
    while(i < num_months)
    {
        payment.contract.advance_time();
        let balance = payment.contract.get_balance();
        assert(
            balance == payment.amount_per_month * (2 - i), 'Payment was not made or was incorrect.'
        );
        i = i + 1;
    }
}

#[test]
#[available_gas(2000000)]
fn programmable_pay_test() {
    let anna_key_pair = generate_key_pair();

    // Addresses of the service providers
    let ethereum_services_address = ContractAddress(felt252(2), felt252(0));
    let game_subscription_address = ContractAddress(felt252(3), felt252(0));
    let gym_address = ContractAddress(felt252(4), felt252(0));

    // Amount of payments (in USDC)
    let ethereum_services_amount = felt252(100);
    let game_subscription_amount = felt252(50);
    let gym_amount = felt252(50);

    let payment_interval = felt252(86400 * 30); // 30 days

    // Create the DelegateAutoPayAccount contracts for each service
    let ethereum_services_payment = RecurringPayment(
        contract: DelegateAutoPayAccount
            .constructor(
                anna_key_pair.public_key,
                anna_key_pair.public_key,
                payment_interval,
                ethereum_services_amount,
                ethereum_services_address
            ),
        amount_per_month: ethereum_services_amount
    );

    let game_subscription_payment = RecurringPayment(
        contract: DelegateAutoPayAccount
            .constructor(
                anna_key_pair.public_key,
                anna_key_pair.public_key,
                payment_interval,
                game_subscription_amount,
                game_subscription_address
            ),
        amount_per_month: game_subscription_amount
    );

    let gym_payment = RecurringPayment(
        contract: DelegateAutoPayAccount
            .constructor(
                anna_key_pair.public_key,
                anna_key_pair.public_key,
                payment_interval,
                gym_amount,
                gym_address
            ),
        amount_per_month: gym_amount
    );

    // Simulate Anna depositing funds for 2 months of payments into each of the contracts
    ethereum_services_payment.contract.validate_owner_transaction();
    ethereum_services_payment.contract.deposit(ethereum_services_amount * 2);
    game_subscription_payment.contract.validate_owner_transaction();
    game_subscription_payment.contract.deposit(game_subscription_amount * 2);
    gym_payment.contract.validate_owner_transaction();
    gym_payment.contract.deposit(gym_amount * 2);

    // Simulate making payments and verify balances
    make_payment_and_check_balance(
        ethereum_services_payment, 2, anna_key_pair.signature, anna_key_pair.nonce
    );
    make_payment_and_check_balance(
        game_subscription_payment, 2, anna_key_pair.signature, anna_key_pair.nonce
    );
    make_payment_and_check_balance(gym_payment, 2, anna_key_pair.signature, anna_key_pair.nonce);
}
