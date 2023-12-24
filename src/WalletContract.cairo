// WalletContract.cairo

#[contract]
mod WalletContract {
    use traits::starknet;
    use starknet::ContractAddress;
    use traits::Into;
    use IDelegableAccount;
    use IAutoPaymentContract;

    struct Storage {
        owner: ContractAddress,
        delegable_account: ContractAddress,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, owner_: ContractAddress, delegable_account_: ContractAddress
    ) {
        self.owner.write(owner_);
        self.delegable_account.write(delegable_account_);
    }

    #[external]
    fn approve_new_contract(ref self: ContractState, contract_to_approve: ContractAddress) {
        assert_eq(
            get_caller_address(), self.owner.read(), 'Only the owner can approve new contracts.'
        );
        let delegable_account_interface =
            starknet::contract_interface::get_contract_interface::<IDelegableAccount>(
            self.delegable_account.read()
        );
        delegable_account_interface
            .approve_contract(contract_to_approve); // Correct method name is approve_contract
    }
}
