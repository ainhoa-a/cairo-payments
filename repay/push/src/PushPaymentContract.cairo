#[starknet::contract]
mod PushPaymentContract {
    #[storage]
    struct Storage {
        balances: Mapping<felt252, felt252>, 
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        // Initialize the storage.
        self.balances.write(None);
    }

    #[external(v0)]
    fn deposit(ref self: ContractState, from_address: felt252, amount: felt252) {
        let current_balance = self.balances.read(from_address).unwrap_or_default();
        self.balances.write(from_address, current_balance + amount);
    }

    #[external(v0)]
    fn transfer(
        ref self: ContractState, from_address: felt252, to_address: felt252, amount: felt252
    ) {
        // Check that the sender has enough balance.
        let sender_balance = self.balances.read(from_address).unwrap_or_default();
        assert(sender_balance >= amount, error_code = 1);

        // Decrease the sender's balance.
        self.balances.write(from_address, sender_balance - amount);

        // Increase the receiver's balance.
        let receiver_balance = self.balances.read(to_address).unwrap_or_default();
        self.balances.write(to_address, receiver_balance + amount);
    }

    #[external(v0)]
    fn get_balance(self: @ContractState, address: felt252) -> felt252 {
        self.balances.read(address).unwrap_or_default()
    }
}
