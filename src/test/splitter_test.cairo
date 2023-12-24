//splitter_test.cairo

use auto_pay::splitter::Splitter;

use starknet::testing::set_caller_address;

// use debug::PrintTrait;

use starknet::ContractAddress;
use starknet::Felt252TryIntoContractAddress;
use traits::TryInto;
use starknet::OptionTrait;
use integer::u256_from_felt252;

// TESTS

#[test]
#[available_gas(2000000)]
fn split_even_number() {
    let amount: u128 = 100;
    let split_amount: u128 = amount / 2;
    let remaining: u128 = amount - (split_amount * 2);

    let userA: ContractAddress = get_address(1);
    let userB: ContractAddress = get_address(2);
    let caller: ContractAddress = get_address(3);

    set_caller_address(caller);
    Splitter::split(amount, userA, userB);

    // assert((Splitter::get_balance(userA) == split_amount), 'Wrong Balance A');
    assert_get_balance(userA, split_amount);
    assert_get_balance(userB, split_amount);
    assert_get_balance(caller, remaining);
}

#[test]
#[available_gas(2000000)]
fn split_odd_number() {
    let amount: u128 = 101;
    let split_amount: u128 = amount / 2;
    let remaining: u128 = amount - (split_amount * 2);

    let userA: ContractAddress = get_address(1);
    let userB: ContractAddress = get_address(2);
    let caller: ContractAddress = get_address(3);

    set_caller_address(caller);
    Splitter::split(amount, userA, userB);

    assert_get_balance(userA, split_amount);
    assert_get_balance(userB, split_amount);
    assert_get_balance(caller, remaining);
}

#[test]
#[available_gas(2000000)]
fn previous_value_preserved() {
    let amount: u128 = 101;
    let split_amount: u128 = amount / 2;
    let remaining: u128 = amount - (split_amount * 2);

    let userA: ContractAddress = get_address(1);
    let userB: ContractAddress = get_address(2);
    let userC: ContractAddress = get_address(3);
    let caller: ContractAddress = get_address(4);

    set_caller_address(caller);
    Splitter::split(amount, userA, userB);
    Splitter::split(amount, userB, userC);

    assert_get_balance(userA, split_amount);
    assert_get_balance(userB, amount - remaining);
    assert_get_balance(userC, split_amount);
    assert_get_balance(caller, remaining * 2);
}


#[test]
#[available_gas(2000000)]
#[should_panic(expected = ('u128_add Overflow', ))]
fn max_value_passed() {
    let amount: u128 = 340282366920938463463374607431768211455_u128;
    let two: u128 = 2_u128;
    let split_amount: u128 = amount / two;
    let remaining: u128 = amount - (split_amount * two);

    let userA: ContractAddress = get_address(1);
    let userB: ContractAddress = get_address(2);
    let caller: ContractAddress = get_address(4);

    set_caller_address(caller);

    Splitter::split(amount, userA, userB); // (amount - 1)/2
    // Splitter::get_balance(userA).print();

    Splitter::split(amount, userA, userB); // (amount - 1)
    // Splitter::get_balance(userA).print();

    Splitter::split(amount, userA, userB); // Overflow
}

// HELPER FUNCTIONS

fn get_address(value: felt252) -> ContractAddress {
    value.try_into().unwrap()
}

fn assert_get_balance(addr: ContractAddress, value: u128) {
    assert((Splitter::get_balance(addr) == value), 'Wrong Balance');
}
