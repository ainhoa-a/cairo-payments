// AutoPayDelegateAccount_test.cairo
use AutoPaymentContract;
use DelegableAccount;
use WalletContract;
use TokenContract;
use IERC20;
use math;
use starknet::ContractAddress;

fn setup() -> (TokenContract, DelegableAccount, AutoPaymentContract, WalletContract) {
    // Initial Setup
    let total_supply = u256 { low: 1000_u128, high: 0_u128 };
    let max_payment = u256 { low: 100_u128, high: 0_u128 };
    let payment_frequency = felt252(30); // Charge once per month

    let user_address = ContractAddress(felt252(1), felt252(0));
    let merchant_address = ContractAddress(felt252(2), felt252(0));

    // User deploys TokenContract
    let token_contract = TokenContract.constructor(total_supply);

    // User deploys DelegableAccount with TokenContract
    let delegable_account = DelegableAccount.constructor(user_address, token_contract.address);

    // Merchant deploys AutoPaymentContract
    let auto_payment_contract = AutoPaymentContract
        .constructor(
            merchant_address,
            user_address,
            token_contract.address,
            merchant_address,
            payment_frequency,
            max_payment
        );

    // User visits merchant's site and agrees to auto payments
    // User's WalletContract approves AutoPaymentContract
    let wallet_contract = WalletContract.constructor(user_address, delegable_account.address);
    wallet_contract.approve_new_contract(auto_payment_contract.address);

    return (token_contract, delegable_account, auto_payment_contract, wallet_contract);
}

#[test]
#[available_gas(2000000)]
fn AutoPayDelegateAccount_test() {
    let (token_contract, delegable_account, auto_payment_contract, wallet_contract) = setup();

    // Call the different tests
    constructor_test();
    insufficient_balance_charge_test();
    clean_up_test();
}

#[test]
#[available_gas(2000000)]
fn constructor_test(
    token_contract: TokenContract,
    delegable_account: DelegableAccount,
    auto_payment_contract: AutoPaymentContract,
    wallet_contract: WalletContract
) { // add assertions to check the initial state of each contract
}

#[test]
#[available_gas(2000000)]
fn insufficient_balance_charge_test(
    token_contract: TokenContract,
    delegable_account: DelegableAccount,
    auto_payment_contract: AutoPaymentContract,
    wallet_contract: WalletContract
) {
    // reduce user's balance to less than max_payment
    token_contract
        .burn(token_contract.balance_of(delegable_account.address).low - max_payment.low / 2);

    // Check balance before charging
    let balance_before_charge = token_contract.balance_of(delegable_account.address).low;

    // Merchant tries to trigger a payment, it should fail
    let required_balance = auto_payment_contract.get_maximum_amount();
    if balance_before_charge >= required_balance {
        // If there is enough balance, perform the charge
        auto_payment_contract.charge();
    } else {
        // Balance is insufficient, halt the operation
        assert(0 = 1, 'Insufficient balance for the operation.');
    }
}

#[test]
#[available_gas(2000000)]
fn clean_up_test(
    token_contract: TokenContract,
    delegable_account: DelegableAccount,
    auto_payment_contract: AutoPaymentContract,
    wallet_contract: WalletContract
) { // conduct some operations
// clean up
// add clean up operations if needed
}
