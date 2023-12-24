#[starknet::contract]
mod PullPaymentContract {
    #[storage]
    struct Storage {
        balances: Mapping<felt252, felt252>,
        allowances: Mapping<(felt252, felt252), felt252>,
        last_payment_timestamp: Mapping<felt252, felt252>
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        // Initialize the storage.
        self.balances.write(None);
        self.allowances.write(None);
        self.last_payment_timestamp.write(None);
    }

    #[external(v0)]
    fn deposit(ref self: ContractState, from_address: felt252, amount: felt252) {
        let current_balance = self.balances.read(from_address).unwrap_or_default();
        self.balances.write(from_address, current_balance + amount);
    }

    #[external(v0)]
    fn approve(
        ref self: ContractState, from_address: felt252, contract_address: felt252, amount: felt252
    ) {
        // Allow the contract to spend a certain amount of tokens on behalf of the sender.
        self.allowances.write((from_address, contract_address), amount);
    }

    #[external(v0)]
    fn pull_payment(
        ref self: ContractState, from_address: felt252, contract_address: felt252, amount: felt252
    ) {
        // Check that the sender has enough balance and has approved enough tokens to the contract.
        let sender_balance = self.balances.read(from_address).unwrap_or_default();
        let approved_amount = self
            .allowances
            .read((from_address, contract_address))
            .unwrap_or_default();

        assert(sender_balance >= amount, error_code = 1);
        assert(approved_amount >= amount, error_code = 2);

        // Check that at least a month has passed since the last payment.
        let current_timestamp = starknet::info::get_current_block_number();
        let last_payment_timestamp = self
            .last_payment_timestamp
            .read(from_address)
            .unwrap_or_default();

        assert(
            current_timestamp >= last_payment_timestamp + 4_000_000, error_code = 3
        ); // Assuming ~4 million blocks per month.

        // Decrease the sender's balance and the approved amount.
        self.balances.write(from_address, sender_balance - amount);
        self.allowances.write((from_address, contract_address), approved_amount - amount);

        // Increase the contract's balance.
        let contract_balance = self.balances.read(contract_address).unwrap_or_default();
        self.balances.write(contract_address, contract_balance + amount);

        // Update the last payment timestamp.
        self.last_payment_timestamp.write(from_address, current_timestamp);
    }

    #[external(v0)]
    fn get_balance(self: @ContractState, address: felt252) -> felt252 {
        self.balances.read(address).unwrap_or_default()
    }
}
