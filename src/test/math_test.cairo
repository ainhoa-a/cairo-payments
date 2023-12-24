// math_test.cairo

use math::{pow, fpow, count_digits_of_base, div_wad_down};
// Test power function
#[test]
#[available_gas(2000000)]
fn pow_test() {
    assert(pow(2, 0) == 1, 'invalid result');
    assert(pow(2, 1) == 2, 'invalid result');
    assert(pow(2, 12) == 4096, 'invalid result');
    assert(pow(5, 9) == 1953125, 'invalid result');
}

// Test counting of number of digits function
#[test]
#[available_gas(2000000)]
fn count_digits_of_base_test() {
    assert(count_digits_of_base(0, 10) == 0, 'invalid result');
    assert(count_digits_of_base(2, 10) == 1, 'invalid result');
    assert(count_digits_of_base(10, 10) == 2, 'invalid result');
    assert(count_digits_of_base(100, 10) == 3, 'invalid result');
    assert(count_digits_of_base(0x80, 16) == 2, 'invalid result');
    assert(count_digits_of_base(0x800, 16) == 3, 'invalid result');
    assert(count_digits_of_base(0x888888888888888888, 16) == 18, 'invalid result');
}

// Test fast power function
#[test]
#[available_gas(2000000)]
fn fpow_test() {
    assert(fpow(3, 8) == 6561, 'invalid result');
}
// Test div_wad_down function
#[test]
#[available_gas(2000000)]
fn div_wad_down_test() {
    // Replace these with actual test cases appropriate for your div_wad_down function.
    let a = u256 { low: 500_u128, high: 0_u128 };
    let b = u256 { low: 100_u128, high: 0_u128 };
    let expected = u256 {
        low: 5_u128, high: 0_u128
    }; // assume div_wad_down(a, b) should equal to 5.

    let result = div_wad_down(a, b);
    assert(result.low == expected.low);
    assert(result.high == expected.high, 'invalid result');
}
