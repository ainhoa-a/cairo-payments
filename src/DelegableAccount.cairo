// DelegableAccount.cairo

use starknet::ContractAddress;
use starknet::collections::LegacyMap;

#[contract]
mod DelegableAccount {
    use starknet::ContractAddress;
    use starknet::account::Call;
    use starknet::collections::LegacyMap;
    use starknet::get_caller_address;
    use starknet::call_contract_syscall;

    // Imports of other necessary contracts or interfaces would go here
    use IERC20;

    struct Storage {
        owner: ContractAddress,
        token_contract_address: ContractAddress,
        approved_contracts: LegacyMap<ContractAddress, bool>,
        balances: LegacyMap<ContractAddress, u256>, // Balance mapping
    }

    #[constructor]
    fn constructor(
        ref self: ContractState, owner_: ContractAddress, token_contract_address_: ContractAddress, 
    ) {
        self.owner.write(owner_);
        self.token_contract_address.write(token_contract_address_);
    }

    // Function to approve a new contract
    #[external]
    fn approve_contract(ref self: ContractState, contract_address: ContractAddress) {
        assert_eq(get_caller_address(), self.owner.read(), 'Only the owner can approve contracts.');

        self.approved_contracts[contract_address] = true;
        ContractApproved.emit(self.owner.read(), contract_address);
    }

    // Function to transfer tokens on behalf of approved contracts
    #[external]
    fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) {
        assert_eq(
            self.approved_contracts[get_caller_address()],
            true,
            'Only approved contracts can initiate transfers.'
        );

        let token_contract_interface =
            starknet::contract_interface::get_contract_interface::<IERC20>(
            self.token_contract_address.read()
        );

        // Transferring tokens
        token_contract_interface.transfer(recipient, amount);
        TokensTransferred.emit(self.owner.read(), recipient, amount);
    }
    #[external]
    fn revoke_contract(ref self: ContractState, contract_address: ContractAddress) {
        assert_eq(get_caller_address(), self.owner.read(), 'Only the owner can revoke contracts.');
        self.approved_contracts[contract_address] = false;
        ContractRevoked
            .emit(self.owner.read(), contract_address); // Emit an event when a contract is revoked
    }

    #[event]
    fn ContractRevoked(owner: ContractAddress, contract: ContractAddress) {}

    #[event]
    fn ContractApproved(owner: ContractAddress, contract: ContractAddress) {}

    #[event]
    fn TokensTransferred(from: ContractAddress, to: ContractAddress, value: u256) {}
}
