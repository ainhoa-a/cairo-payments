// DelegateAutoPayAccount_test.cairo
use DelegateAutoPayAccount;
use starknet::ContractAddress;
use ecdsa::generate_key_pair;

#[test]
#[available_gas(2000000)]
fn DelegateAutoPayAccount_test() {
    let owner_key_pair = generate_key_pair();
    let delegate_key_pair = generate_key_pair();
    let recipient_address = ContractAddress(felt252(1), felt252(0));

    let payment_interval = felt252(86400 * 30); // 30 days
    let payment_amount = felt252(10);

    // Deploy DelegateAutoPayAccount
    let auto_pay_account = DelegateAutoPayAccount
        .constructor(
            owner_key_pair.public_key,
            delegate_key_pair.public_key,
            payment_interval,
            payment_amount,
            recipient_address
        );

    // Verify initial state
    let initial_time = starknet::get_current_time();
    let next_payment_time = auto_pay_account.get_next_payment_time();
    let recurring_payment_active = auto_pay_account.get_recurring_payment_active();
    assert_eq(next_payment_time, initial_time + payment_interval, 'Incorrect next payment time');
    assert_eq(recurring_payment_active, 1, 'Recurring payment should be active');

    // Simulate one month passing
    starknet::increase_current_time(payment_interval);

    // Simulate delegate signing a transaction
    let make_payment_signature = delegate_key_pair.sign(auto_pay_account.address);
    auto_pay_account.make_payment(make_payment_signature, 1);

    // Check next payment time
    let next_payment_time = auto_pay_account.get_next_payment_time();
    assert_eq(
        next_payment_time,
        initial_time + 2 * payment_interval,
        'Incorrect next payment time after payment'
    );

    // Simulate owner signing a transaction to cancel recurring payments
    let cancel_signature = owner_key_pair.sign(auto_pay_account.address);
    auto_pay_account.cancel_recurring_payment(cancel_signature, 2);

    // Check recurring payment status
    let recurring_payment_active = auto_pay_account.get_recurring_payment_active();
    assert_eq(recurring_payment_active, 0, 'Recurring payment should be inactive');

    // Simulate owner signing a transaction to change the delegate
    let new_delegate_key_pair = generate_key_pair();
    let change_delegate_signature = owner_key_pair.sign(auto_pay_account.address);
    auto_pay_account
        .change_delegate(new_delegate_key_pair.public_key, change_delegate_signature, 3);

    // Check delegate public key
    let delegate_public_key = auto_pay_account.get_delegate_public_key();
    assert_eq(
        delegate_public_key,
        new_delegate_key_pair.public_key,
        'Incorrect delegate public_key after change'
    );

    // Simulate owner signing a transaction to change the owner
    let new_owner_key_pair = generate_key_pair();
    let change_owner_signature = owner_key_pair.sign(auto_pay_account.address);
    auto_pay_account.change_owner(new_owner_key_pair.public_key, change_owner_signature, 4);

    // Check owner public key
    let owner_public_key = auto_pay_account.get_owner_public_key();
    assert_eq(
        owner_public_key, new_owner_key_pair.public_key, 'Incorrect owner public_key after change'
    );
}
