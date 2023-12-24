// AutoPaymentContract.cairo
use starknet::ContractAddress;

#[contract]
mod AutoPaymentContract {
    use starknet::ContractAddress;
    use starknet::account::Call;
    use starknet::get_caller_address;
    use starknet::call_contract_syscall;
    use IERC20;

    struct Storage {
        owner: ContractAddress,
        user_address: ContractAddress,
        token_contract_address: ContractAddress,
        merchant_address: ContractAddress,
        payment_frequency: felt252,
        maximum_amount: u256,
        last_payment_time: felt252,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner_: ContractAddress,
        user_address_: ContractAddress,
        token_contract_address_: ContractAddress,
        merchant_address_: ContractAddress,
        payment_frequency_: felt252,
        maximum_amount_: u256
    ) {
        self.owner.write(owner_);
        self.user_address.write(user_address_);
        self.token_contract_address.write(token_contract_address_);
        self.merchant_address.write(merchant_address_);
        self.payment_frequency.write(payment_frequency_);
        self.maximum_amount.write(maximum_amount_);
        self.last_payment_time.write(0); // Last payment time initialized to 0
    }
    #[external]
    fn charge(ref self: ContractState) {
        assert_eq(
            get_caller_address(),
            self.owner.read(),
            'Only the contract owner can call the charge function.'
        );

        let current_time = starknet::get_current_time();

        assert_ge(
            current_time,
            self.last_payment_time.read() + self.payment_frequency.read(),
            'The payment frequency criteria is not met.'
        );

        let token_contract_interface =
            starknet::contract_interface::get_contract_interface::<IERC20>(
            self.token_contract_address.read()
        );
        let balance = token_contract_interface.balanceOf(self.user_address.read());

        assert_ge(balance, self.maximum_amount.read(), 'The maximum amount criteria is not met.');

        // Process the payment
        let transfer_amount = min(balance, self.maximum_amount.read());
        token_contract_interface.transfer(self.merchant_address.read(), transfer_amount);

        // Deduct the transferred amount from the user's balance
        token_contract_interface.balances[self.user_address.read()] -= transfer_amount;

        // Update the last payment time
        self.last_payment_time.write(current_time);
        PaymentCharged
            .emit(self.user_address.read(), self.merchant_address.read(), transfer_amount);
    }

    #[external]
    fn change_payment_details(
        ref self: ContractState, payment_frequency_: felt252, maximum_amount_: u256
    ) {
        assert_eq(
            get_caller_address(),
            self.owner.read(),
            'Only the contract owner can change the payment details.'
        );
        self.payment_frequency.write(payment_frequency_);
        self.maximum_amount.write(maximum_amount_);
    }

    #[event]
    fn PaymentCharged(user: ContractAddress, merchant: ContractAddress, value: u256) {}
}
