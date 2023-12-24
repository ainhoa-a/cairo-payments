#[starknet::interface]
trait IEthereumServices<TContractState> {
    fn request_payment(self: @TContractState, amount: u128) -> bool;
    fn verify_payment(self: @TContractState, amount: u128) -> bool;
}

#[starknet::interface]
trait IYieldProtocol<TContractState> {
    fn deposit_funds(ref self: TContractState, amount: u128, pool: felt);
    fn withdraw_funds(ref self: TContractState, amount: u128, pool: felt) -> u128;
    fn get_balance(self: @TContractState, pool: felt) -> u128;
}

#[starknet::interface]
trait IRePay<TContractState> {
    fn make_payment(ref self: ContractState);
}
#[starknet::contract]
mod RePay {
    use starknet::ContractAddress;
    use super::{
        IEthereumServicesDispatcher, IEthereumServicesDispatcherTrait, IYieldProtocolDispatcher,
        IYieldProtocolDispatcherTrait
    };

    #[storage]
    struct Storage {
        balance: u128,
        monthly_payment: u128,
        max_payments: u128,
        payments_made: u128,
        ethereum_services: IEthereumServicesDispatcher,
        yield_protocol: IYieldProtocolDispatcher
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_balance: u128,
        monthly_payment: u128,
        max_payments: u128,
        ethereum_services_addr: ContractAddress,
        yield_protocol_addr: ContractAddress
    ) {
        self.balance.write(initial_balance);
        self.monthly_payment.write(monthly_payment);
        self.max_payments.write(max_payments);
        self.payments_made.write(0);

        self
            .ethereum_services
            .write(IEthereumServicesDispatcher { contract_address: ethereum_services_addr });
        self
            .yield_protocol
            .write(IYieldProtocolDispatcher { contract_address: yield_protocol_addr });
    }

    #[external(v0)]
    fn make_payment(ref self: ContractState) {
        let current_balance = self.balance.read();
        let monthly_payment = self.monthly_payment.read();

        if self
            .payments_made
            .read() >= self
            .max_payments
            .read() { //panic("Maximum number of payments made");
        }

        if current_balance < monthly_payment { // handle insufficent funds here
        //panic("Insufficient funds");
        }

        let payment_request = self.ethereum_services.read().request_payment(monthly_payment);
        if !payment_request { //panic("Payment request failed");
        }

        self.balance.write(current_balance - monthly_payment);
        self.payments_made.write(self.payments_made.read() + 1);
    }

    #[external(v0)]
    fn deposit_to_yield(ref self: ContractState, amount: u128, pool: felt) {
        let current_balance = self.balance.read();
        if current_balance < amount { //panic("Insufficient funds for deposit");
        }

        self.yield_protocol.read().deposit_funds(amount, pool);
        self.balance.write(current_balance - amount);
    }

    #[external(v0)]
    fn withdraw_from_yield(ref self: ContractState, amount: u128, pool: felt) {
        let withdrawn = self.yield_protocol.read().withdraw_funds(amount, pool);
        self.balance.write(self.balance.read() + withdrawn);
    }

    #[external(v0)]
    fn get_yield_balance(self: @ContractState, pool: felt) -> u128 {
        self.yield_protocol.read().get_balance(pool)
    }
}

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
