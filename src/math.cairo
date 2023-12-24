// math.cairo
use option::OptionTrait;
use traits::{Into, TryInto};

trait MathRounding {
    fn div_up(self: u256, rhs: u256) -> u256;
}

impl MathRoundingImpl of MathRounding {
    fn div_up(self: u256, rhs: u256) -> u256 {
        let q = self.low / rhs.low;
        let r = self.low % rhs.low;
        if (r == 0_u128) {
            u256 { low: q, high: 0_u128 }
        } else {
            u256 { low: q, high: 0_u128 } + u256 { low: 1_u128, high: 0_u128 }
        }
    }
}

fn div_wad_down(a: u256, b: u256) -> u256 {
    let WAD: u256 = 1000000000000000000.into();
    mul_div_down(a, WAD, b)
}

fn mul_div_down(a: u256, b: u256, denominator: u256) -> u256 {
    u256 { low: (a.low * b.low) / denominator.low, high: 0_u128 }
}

/// Raise a number to a power.
/// * `base` - The number to raise.
/// * `exp` - The exponent.
/// # Returns
/// * `u128` - The result of base raised to the power of exp.
fn pow(base: u128, mut exp: u128) -> u128 {
    if exp == 0 {
        1
    } else {
        base * pow(base, exp - 1)
    }
}

/// Function to count the number of digits in a number.
/// # Arguments
/// * `num` - The number to count the digits of.
/// * `base` - Base in which to count the digits.
/// # Returns
/// * `felt252` - The number of digits in num of base
fn count_digits_of_base(mut num: u128, base: u128) -> u128 {
    let mut res = 0;
    loop {
        if num == 0 {
            break res;
        } else {
            num = num / base;
        }
        res += 1;
    }
}

fn fpow(x: u128, n: u128) -> u128 {
    if n == 0 {
        1
    } else if (n & 1) == 1 {
        x * fpow(x * x, n / 2)
    } else {
        fpow(x * x, n / 2)
    }
}

fn shl(x: u128, n: u128) -> u128 {
    x * fpow(2, n)
}

fn shr(x: u128, n: u128) -> u128 {
    x / fpow(2, n)
}
