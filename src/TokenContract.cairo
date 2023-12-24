// TokenContract.cairo
use starknet::collections::LegacyMap;
use starknet::ContractAddress;
use starknet::get_caller_address;

#[contract]
mod TokenContract {
    use starknet::collections::LegacyMap;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use IERC20;

    struct Storage {
        total_supply: u256,
        balances: LegacyMap<ContractAddress, u256>,
        allowances: LegacyMap<(ContractAddress, ContractAddress), u256>,
    }

    #[constructor]
    fn constructor(ref self: ContractState, total_supply_: u256) {
        self.total_supply.write(total_supply_);

        // Assign the total supply to the creator of the contract
        let creator_address = get_caller_address();
        self.balances[creator_address] = total_supply_;

        // Set an initial allowance for the AutoPaymentContract
        self.allowances[(creator_address, AUTO_PAYMENT_CONTRACT_ADDRESS)] = INITIAL_ALLOWANCE;
    }

    #[external]
    fn approve(ref self: ContractState, spender: ContractAddress, value: u256) {
        let owner = get_caller_address();
        self.allowances[(owner, spender)] = value;
        Approval.emit(owner, spender, value);
    }

    // Function to transfer tokens from the sender's account to a recipient's account
    #[external]
    fn transfer(ref self: ContractState, to: ContractAddress, value: u256) {
        let from = get_caller_address();
        // Check if the sender has enough balance
        assert_ge(self.balances[from], value, 'Insufficient balance');
        // Update balances and allowance
        self.balances[from] -= value;
        self.balances[to] += value;
        Transfer.emit(from, to, value); // Emit Transfer event
    }

    #[external]
    fn transfer_from(
        ref self: ContractState, from: ContractAddress, to: ContractAddress, value: u256
    ) {
        // Check if the spender has enough allowance
        assert_ge(self.allowances[(from, get_caller_address())], value, 'Insufficient allowance');
        // Check if the sender has enough balance
        assert_ge(self.balances[from], value, 'Insufficient balance');
        // Update balances and allowance
        self.balances[from] -= value;
        self.balances[to] += value;
        self.allowances[(from, get_caller_address())] -= value;
        Transfer.emit(from, to, value); // Emit Transfer event
    }

    // Function to get balance of an account
    #[external(view)]
    fn balance_of(ref self: ContractState, account: ContractAddress) -> u256 {
        self.balances[account]
    }

    #[event]
    fn Transfer(from: ContractAddress, to: ContractAddress, value: u256) {}

    #[event]
    fn Approval(owner: ContractAddress, spender: ContractAddress, value: u256) {}
}
