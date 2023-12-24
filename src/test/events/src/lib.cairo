use core::debug::PrintTrait;
use core::traits::Into;
use core::result::ResultTrait;
//use test::test_utils::{assert_eq, assert_ne};
use starknet::syscalls::{deploy_syscall, get_block_hash_syscall};
use traits::TryInto;
use option::OptionTrait;
use starknet::SyscallResultTrait;
use starknet::class_hash::Felt252TryIntoClassHash;
use array::ArrayTrait;
use array::SpanTrait;


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
trait IContractWithEvent<T> {
    fn emit_event(ref self: T, incremental: bool);
}

#[starknet::contract]
mod ContractWithEvent {
    use traits::Into;
    use starknet::info::get_contract_address;
    const TEST_CLASS_HASH: felt252 =
        1601010881861231008477297663414424217411948115109752938040170845939822336344;
    #[storage]
    struct Storage {
        value: u128, 
    }

    #[derive(Copy, Drop, PartialEq, starknet::Event)]
    struct IncrementalEvent {
        value: u128, 
    }

    #[derive(Copy, Drop, PartialEq, starknet::Event)]
    struct StaticEvent {}

    #[event]
    #[derive(Copy, Drop, PartialEq, starknet::Event)]
    enum Event {
        IncrementalEvent: IncrementalEvent,
        StaticEvent: StaticEvent,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.value.write(0);
    }

    #[external(v0)]
    fn emit_event(ref self: ContractState, incremental: bool) {
        if incremental {
            self.emit(Event::IncrementalEvent(IncrementalEvent { value: self.value.read() }));
            self.value.write(self.value.read() + 1);
        } else {
            self.emit(Event::StaticEvent(StaticEvent {}));
        }
    }
}

use ContractWithEvent::{Event, IncrementalEvent, StaticEvent};

#[test]
#[available_gas(30000000)]
fn test_events() {
    internal::revoke_ap_tracking();
    // Set up.
    let (contract_address, _) = deploy_syscall(
        ContractWithEvent::TEST_CLASS_HASH.try_into().unwrap(), 0, Default::default().span(), false
    )
        .unwrap();
    let mut contract = IContractWithEventDispatcher { contract_address };
    contract.emit_event(true);
    contract.emit_event(true);
    contract.emit_event(false);
    contract.emit_event(false);
    contract.emit_event(true);
    contract.emit_event(false);
    contract.emit_event(true);
    let (mut keys, mut data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(
        @starknet::Event::deserialize(ref keys, ref data).unwrap(),
        @Event::IncrementalEvent(IncrementalEvent { value: 0 }),
        'event == IncrementalEvent(0)'
    );
    let (mut keys, mut data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(
        @starknet::Event::deserialize(ref keys, ref data).unwrap(),
        @Event::IncrementalEvent(IncrementalEvent { value: 1 }),
        'event == IncrementalEvent(1)'
    );
    let (mut keys, mut data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(
        @starknet::Event::deserialize(ref keys, ref data).unwrap(),
        @Event::StaticEvent(StaticEvent {}),
        'event == StaticEvent'
    );
    let (mut keys, mut data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(
        @starknet::Event::deserialize(ref keys, ref data).unwrap(),
        @Event::StaticEvent(StaticEvent {}),
        'event == StaticEvent'
    );
    let (mut keys, mut data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(
        @starknet::Event::deserialize(ref keys, ref data).unwrap(),
        @Event::IncrementalEvent(IncrementalEvent { value: 2 }),
        'event == IncrementalEvent(2)'
    );
    let (mut keys, mut data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(
        @starknet::Event::deserialize(ref keys, ref data).unwrap(),
        @Event::StaticEvent(StaticEvent {}),
        'event == StaticEvent'
    );
    let (mut keys, mut data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(
        @starknet::Event::deserialize(ref keys, ref data).unwrap(),
        @Event::IncrementalEvent(IncrementalEvent { value: 3 }),
        'event == IncrementalEvent(3)'
    );
    assert(starknet::testing::pop_log(contract_address).is_none(), 'no more events');
}

#[test]
#[available_gas(300000)]
fn test_pop_log() {
    let contract_address = starknet::contract_address_const::<0x1234>();
    starknet::testing::set_contract_address(contract_address);
    let mut keys = Default::default();
    let mut data = Default::default();
    keys.append(1234);
    data.append(2345);
    starknet::emit_event_syscall(keys.span(), data.span());
    starknet::emit_event_syscall(keys.span(), data.span());

    let (keys, data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(@keys.len(), @1, 'unexpected keys size');
    assert_eq(@data.len(), @1, 'unexpected data size');
    assert_eq(keys.at(0), @1234, 'unexpected key');
    assert_eq(data.at(0), @2345, 'unexpected data');

    let (keys, data) = starknet::testing::pop_log(contract_address).unwrap();
    assert_eq(@keys.len(), @1, 'unexpected keys size');
    assert_eq(@data.len(), @1, 'unexpected data size');
    assert_eq(keys.at(0), @1234, 'unexpected key');
    assert_eq(data.at(0), @2345, 'unexpected data');
}
