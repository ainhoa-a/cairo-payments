#[inline]
fn assert_eq<T, impl TPartialEq: PartialEq<T>>(a: @T, b: @T, err_code: felt252) {
    assert(a == b, err_code);
}

#[inline]
fn assert_ne<T, impl TPartialEq: PartialEq<T>>(a: @T, b: @T, err_code: felt252) {
    assert(a != b, err_code);
}

#[inline]
fn assert_le<T, impl TPartialOrd: PartialOrd<T>>(a: T, b: T, err_code: felt252) {
    assert(a <= b, err_code);
}

#[inline]
fn assert_lt<T, impl TPartialOrd: PartialOrd<T>>(a: T, b: T, err_code: felt252) {
    assert(a < b, err_code);
}

#[inline]
fn assert_ge<T, impl TPartialOrd: PartialOrd<T>>(a: T, b: T, err_code: felt252) {
    assert(a >= b, err_code);
}

#[inline]
fn assert_gt<T, impl TPartialOrd: PartialOrd<T>>(a: T, b: T, err_code: felt252) {
    assert(a > b, err_code);
}

#[starknet::interface]
trait IDelegateAutoPayAccount<T> {
    fn emit_event(ref self: T, incremental: bool);
}

#[starknet::contract]
mod DelegateAutoPayAccount {
    use test::test_utils::{assert_eq, assert_ne};
    use array::{ArrayTrait, SpanTrait};
    use box::BoxTrait;
    use ecdsa::check_ecdsa_signature;
    use option::OptionTrait;
    use starknet::account::Call;
    use starknet::{
        call_contract_syscall, get_block_timestamp, get_contract_address, get_caller_address
    };
    use starknet::contract_address_try_from_felt252;
    use starknet::class_hash::ClassHash;
    use starknet::contract_address::ContractAddress;
    use starknet::storage_access::StorageAddress;
    use integer::u256_from_felt252;
    use zeroable::Zeroable;
    use array::ArraySerde;
    #[storage]
    struct Storage {
        owner_public_key: felt252, // PublicKey
        delegate_public_key: felt252, // PublicKey
        payment_interval: felt252, // Time in seconds
        payment_amount: felt252, // Amount of currency
        next_payment_time: felt252, // Timestamp of the next payment
        recipient_address: ContractAddress, // Address of the recipient
        owner_nonce: felt252, // Nonce for the owner
        delegate_nonce: felt252, // Nonce for the delegate
        recurring_payment_active: bool, // 1 if recurring payment is active, 0 otherwise
        balances: (felt252, felt252), // Record of balance
        payments_paused: bool, // 1 if payments are paused, 0 otherwise
        emergency_delegate_public_key: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner_public_key_: felt252,
        delegate_public_key_: felt252,
        payment_interval_: felt252,
        payment_amount_: felt252,
        payment_recipient_: ContractAddress,
        emergency_delegate_public_key_: ContractAddress
    ) -> () {
        self.owner_public_key.write(owner_public_key_);
        self.delegate_public_key.write(delegate_public_key_);
        self.next_payment_time.write(starknet::get_block_timestamp() + payment_interval_);
        self.payment_interval.write(payment_interval_);
        self.payment_amount.write(payment_amount_);
        self.recipient_address.write(payment_recipient_);
        self.recurring_payment_active.write(true);
        self.owner_nonce.write(0);
        self.delegate_nonce.write(0);
        self.payments_paused.write(false);
        self.emergency_delegate_public_key.write(emergency_delegate_public_key_)
    }

    trait StorageTrait {
        fn validate_owner_transaction(self: @ContractState) -> felt252;
        fn validate_delegate_transaction(self: @ContractState) -> felt252;
    }

    impl StorageImpl of StorageTrait {
        #[external(v0)]
        fn validate_owner_transaction(self: @ContractState) -> felt252 {
            let tx_info = starknet::get_tx_info().unbox();
            let signature = tx_info.signature;
            assert(signature.len() == 2_u32, 'INVALID_SIGNATURE_LENGTH');
            assert(
                check_ecdsa_signature(
                    message_hash: tx_info.transaction_hash,
                    public_key: self.owner_public_key.read(),
                    signature_r: *signature[0_u32],
                    signature_s: *signature[1_u32],
                ),
                'INVALID_SIGNATURE',
            );
            starknet::VALIDATED
        }
        #[external(v0)]
        fn validate_delegate_transaction(self: @ContractState) -> felt252 {
            let tx_info = starknet::get_tx_info().unbox();
            let signature = tx_info.signature;
            assert(signature.len() == 2_u32, 'INVALID_SIGNATURE_LENGTH');
            assert(
                check_ecdsa_signature(
                    message_hash: tx_info.transaction_hash,
                    public_key: self.delegate_public_key.read(),
                    signature_r: *signature[0_u32],
                    signature_s: *signature[1_u32],
                ),
                'INVALID_SIGNATURE',
            );
            starknet::VALIDATED
        }
    }

    #[external(v0)]
    fn pause_payments(self: @ContractState) -> () {
        self.validate_owner_transaction(); // Validate transaction
        self
            .payments_paused
            .write(true); // Set payments_paused to 1 to indicate that payments are paused.
    }

    #[external(v0)]
    fn resume_payments(self: @ContractState) -> () {
        self.validate_owner_transaction(); // Validate transaction
        let delegate_balance = self.balances.read(self.delegate_public_key.read());
        if delegate_balance < self.payment_amount.read() {
            return; // If there are not enough funds, do not resume payments.
        }
        self
            .payments_paused
            .write(false); // Set payments_paused to 0 to indicate that payments are resumed.
    }


    #[external(v0)]
    fn cancel_recurring_payment(self: @ContractState) -> () {
        self.validate_owner_transaction(); // Validate transaction
        self.recurring_payment_active.write(false);
    }

    #[external(v0)]
    fn change_delegate(self: @ContractState, delegate_public_key: felt252) -> () {
        self.validate_owner_transaction(); // Validate transaction
        self.delegate_public_key.write(delegate_public_key);
    }

    #[external(v0)]
    fn change_owner(self: @ContractState, owner_public_key: felt252) {
        self.validate_owner_transaction(); // Validate transaction
        self.owner_public_key.write(owner_public_key);
    }

    #[external(v0)]
    fn get_owner_public_key(self: @ContractState) -> felt252 {
        self.owner_public_key.read()
    }

    #[external(v0)]
    fn get_next_payment_time(self: @ContractState) -> felt252 {
        self.next_payment_time.read()
    }

    #[external(v0)]
    fn get_recurring_payment_active(self: @ContractState) -> bool {
        self.recurring_payment_active.read()
    }

    #[external(v0)]
    fn get_delegate_public_key(self: @ContractState) -> felt252 {
        self.delegate_public_key.read()
    }

    #[external(v0)]
    fn get_balance(self: @ContractState, user: felt252) -> felt252 {
        self.balances.read(user)
    }

    #[external(v0)]
    fn advance_time(self: @ContractState) {
        if self.next_payment_time <= self.get_block_timestamp() {
            let contract_address = self.get_address();
            let contract_balance = self
                .get_balance(contract_address); // Check the contract balance.
            assert_ne(
                contract_balance >= self.payment_amount,
                'Insufficient balance for scheduled payment.'
            );
            self.get_balance() -= self.payment_amount
            self
                .next_payment_time
                .write(self.next_payment_time.read() + self.payment_interval.read())
                .payment_interval
        }
    }

    #[external(v0)]
    fn set_emergency_delegate(self: @ContractState, emergency_delegate_public_key: felt252) -> () {
        self.validate_owner_transaction(); // Validate transaction
        self.emergency_delegate_public_key.write(emergency_delegate_public_key);
    }

    #[external(v0)]
    fn emergency_stop(self: @ContractState) -> () {
        let tx_info = starknet::get_tx_info().unbox();
        let signature = tx_info.signature;
        assert(signature.len() == 2_u32, 'INVALID_SIGNATURE_LENGTH');
        assert(
            check_ecdsa_signature(
                message_hash: tx_info.transaction_hash,
                public_key: self.emergency_delegate_public_key.read(),
                signature_r: *signature[0_u32],
                signature_s: *signature[1_u32],
            ),
            'INVALID_SIGNATURE',
        );
        self.recurring_payment_active.write(false);
    }

    #[external(v0)]
    fn make_payment(ref self: ContractState) -> () {
        assert_ne(self.recurring_payment_active.read(), true, 'RECURRING_PAYMENT_INACTIVE');
        assert_ne(self.payments_paused.read(), true, 'PAYMENTS_PAUSED');
        assert_ne(starknet::get_current_time() >= self.next_payment_time.read(), 1, 'TOO_EARLY');
        let delegate_balance = self.balances.read(self.delegate_public_key.read());

        if delegate_balance < self.payment_amount.read() {
            self.payments_paused.write(false);
            return;
        }
        self.validate_delegate_transaction(); // Validate transaction

        let contract_address = starknet::get_address();
        let contract_balance = starknet::get_balance(
            contract_address
        ); // Check the contract balance.
        assert(contract_balance >= self.payment_amount.read(), 'INSUFFICIENT_CONTRACT_FUNDS');

        // Deduct payment amount from the delegate's balance before the transfer operation.
        self
            .balances
            .write(self.delegate_public_key.read(), delegate_balance - self.payment_amount.read());

        starknet::transfer(self.payment_recipient.read(), self.payment_amount.read());

        // Update the next payment time.
        self
            .next_payment_time
            .write(starknet::get_block_timestamp() + self.payment_interval.read());
    }

    #[external(v0)]
    fn withdraw(ref self: ContractState, amount: felt252) -> () {
        // Validate caller
        let caller = starknet::get_caller_address();
        assert_ne(caller, self.owner_public_key.read(), 'NOT_OWNER');
        self.validate_owner_transaction(); // Validate transaction
        let current_balance = self.balances.read(caller);
        assert(
            current_balance >= amount, 'INSUFFICIENT_FUNDS'
        ); // Verify that the current balance is enough for the withdrawal.

        // Subtract the withdrawal amount from the owner's balance.
        self.balances.write(caller, current_balance - amount);

        // Transfer the withdrawn amount to the owner's account.
        starknet::transfer(caller, amount);
    }

    #[external(v0)]
    fn deposit(ref self: ContractState, amount: felt252) -> () {
        // Validate caller.
        let caller = starknet::get_caller_address();
        self.validate_owner_transaction(); // Validate transaction
        assert(
            amount > 0, 'INVALID_DEPOSIT_AMOUNT'
        ); // verify that the deposited amount is positive

        let current_balance = self.get_balance(caller);
        let new_balance = current_balance + amount;
        self.balances.write(caller, new_balance);

        if (self.payments_paused.read() == true) {
            if (new_balance >= self.payment_amount.read()) {
                self.payments_paused.write(false);
            }
        }
    }
}
