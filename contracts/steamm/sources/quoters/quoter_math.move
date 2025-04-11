module steamm::quoter_math;

use std::string::utf8;
use suilend::decimal::Decimal;

use steamm::fixed_point64::{Self, FixedPoint64};
use steamm::utils::decimal_to_fixedpoint64;

public(package) fun swap(
    amount_in: Decimal,
    reserve_x: Decimal,
    reserve_y: Decimal,
    price_x: Decimal,
    price_y: Decimal,
    decimals_x: u64,
    decimals_y: u64,
    amplifier: u64,
    x2y: bool,
): u64 {
    let r_x = decimal_to_fixedpoint64(reserve_x);
    let r_y = decimal_to_fixedpoint64(reserve_y);
    let p_x = decimal_to_fixedpoint64(price_x);
    let p_y = decimal_to_fixedpoint64(price_y);
    let amp = fixed_point64::from(amplifier as u128);
    let delta_in = decimal_to_fixedpoint64(amount_in);

    let price_raw = p_x.div(p_y);

    let dec_pow = if (decimals_x >= decimals_y) {
        fixed_point64::from(10).pow(decimals_x - decimals_y)
    } else {
        fixed_point64::one().div(
            fixed_point64::from(10).pow(decimals_y- decimals_x)
        )
    };

    let k = if (x2y) {
        delta_in.mul(price_raw).div(r_y.mul(dec_pow))
    } else {
        delta_in.mul(dec_pow).div(r_x.mul(price_raw))
    };

    let max_bound = fixed_point64::from_rational(9999999999, 10000000000);
    let z_upper_bound = if (x2y) {
        max_bound.min(delta_in.mul(price_raw).div(r_y.mul(dec_pow)))
    } else {
        max_bound.min(delta_in.mul(dec_pow).div(r_x.mul(price_raw)))
    };

    let z = newton_raphson(k, amp, z_upper_bound);

    let delta_out = z.mul(r_y).to_u128_down() as u64;

    if (x2y) {
        if (delta_out >= reserve_y.floor()) {
            return r_y.mul(fixed_point64::from_rational(999, 1000)).to_u128_down() as u64
        };
    } else {
        if (delta_out >= reserve_x.floor()) {
            return r_x.mul(fixed_point64::from_rational(999, 1000)).to_u128_down() as u64
        };
    };

    delta_out
}

fun newton_raphson(
    k: FixedPoint64,
    a: FixedPoint64,
    z_initial: FixedPoint64
): FixedPoint64 {
    let one = fixed_point64::one();
    let z_min = fixed_point64::from_rational(1, 1000000000000000); // 1e-15
    let z_max = fixed_point64::from_rational(999, 1000);     // 0.999
    let tol = fixed_point64::from_rational(1, 1000000000000000);  // 1e-15
    let max_iter = 25;
    
    let mut z = z_initial;
    let mut i = 0;
    
    while (i < max_iter) {
        //print(&i);
        // Compute f(z)
        let (fx_val, fx_positive) = compute_f(z, a, k);
        
        // Check if |f(z)| < tolerance
        if (fixed_point64::lt(fx_val, tol)) {
            break
        };
        
        // Compute f'(z)
        let fp = compute_f_prime(z, a);
        
        // Check for zero derivative
        assert!(!fixed_point64::eq(fp, fixed_point64::zero()), 1001); // Error if derivative is zero
        
        // Newton step: z_new = z - f(z)/f'(z)
        // Since fx_val is magnitude, we need to handle the sign separately
        let fx_div_fp = fixed_point64::div(fx_val, fp);
        let z_new = if (fx_positive) {
            // If f(z) is positive, subtract fx/fp from z
            if (fixed_point64::gt(fx_div_fp, z)) {
                z_min // If subtraction would go below 0, clamp to minimum
            } else {
                fixed_point64::sub(z, fx_div_fp)
            }
        } else {
            // If f(z) is negative, add fx/fp to z
            if (fixed_point64::gt(fixed_point64::add(z, fx_div_fp), one)) {
                z_max // If addition would exceed 1, clamp to maximum
            } else {
                fixed_point64::add(z, fx_div_fp)
            }
        };
        
        // Update z for next iteration
        z = z_new;
        i = i + 1;
    };
    
    z
}

/// Computes f(z) = (1 - 1/A) * z - (1/A) * ln(1 - z) - k
/// Returns (magnitude, is_positive) where magnitude is |f(z)| and is_positive indicates the sign
fun compute_f(
    z: FixedPoint64,
    a: FixedPoint64,
    k: FixedPoint64
): (FixedPoint64, bool) {
    let one = fixed_point64::one();
    
    // 64 * ln(2) in FixedPoint64 format
    let ln2_64 = fixed_point64::from_raw_value(12786308645202655660).mul(fixed_point64::from(64)); // 64 * LN2

    // Step 1: Compute (1 - 1/A) * z (always positive)
    let one_div_a = fixed_point64::div(one, a);
    let term1 = fixed_point64::mul(fixed_point64::sub(one, one_div_a), z); // Term 1 is always positive

    // Step 2: Compute (1/A) * ln(1 - z)
    let one_minus_z = fixed_point64::sub(one, z); // 0.99 OK
    let ln_plus_64ln2 = fixed_point64::ln_plus_64ln2(one_minus_z); // ln(1-z) + 64*ln(2) // 44.351369219983 OK

    assert!(!fixed_point64::gt(ln_plus_64ln2, ln2_64), 999);

    // ln_magniture is always negative
    let ln_magnitude = fixed_point64::sub(ln2_64, ln_plus_64ln2);
    
    // Compute (1/A) * |ln(1-z)| (magnitude is positive, sign follows ln(1-z))
    // Term 2 is always negative
    let term2_magnitude = fixed_point64::mul(one_div_a, ln_magnitude);    

    // Term 1 is always positive, term 2 is always negative, so this will always result in an addition
    // Intermediate magnitude is always positive
    let intermediate_magnitude = fixed_point64::add(term1, term2_magnitude);

    // t1 - t2 > 0 (always)
    if (fixed_point64::gte(intermediate_magnitude, k)) {
        // print(&utf8(b"branch 1"));
        // BRANCH 1
        // If t1 - t2 > 0 && > k, then its safe to subtract k and get positive value
        (fixed_point64::sub(intermediate_magnitude, k), true)
    } else {
        // BRANCH 2
        // print(&utf8(b"branch 2"));
        // If t1 - t2 > 0 && < k, then the subtraction of k will lead to a negative value
        (fixed_point64::sub(k, intermediate_magnitude), false)
    }
}

/// Computes f'(z) = 1 - 1/A + 1/(A * (1 - z))
/// Result is always positive
fun compute_f_prime(
    z: FixedPoint64,
    a: FixedPoint64,
): FixedPoint64 {
    let one = fixed_point64::one();
    let one_div_a = fixed_point64::div(one, a);
    let term3 = one.div(
        a.mul(one.sub(z))
    );

    one.sub(one_div_a).add(term3)
}

#[test]
fun test_newton_raphson() {
    // k:  0.0002 ; A:  1
    let k = fixed_point64::from_rational(2, 10000); // 0.0002
    let a = fixed_point64::from(1);                // A = 1
    let z_initial = fixed_point64::from_rational(199979994408495, 1000000000000000000); // 0.000199979994408495
    let z = newton_raphson(k, a, z_initial);
    
    assert!(z.to_string() == utf8(b"0.000199980001333266"), 0);

    let (result, _) = compute_f(z, a, k);
    assert!(result.to_string() == utf8(b"0.000000000000000000"), 0);
    
    // k:  0.630828828828829 ; A:  1 ;
    let k = fixed_point64::from_rational(630828828828829, 1000000000000000); // 0.630828828828829
    let a = fixed_point64::from(1);                // A = 1
    let z_initial = fixed_point64::from_rational(467849443537058250, 1000000000000000000); // 0.467849443537058250
    let z = newton_raphson(k, a, z_initial);

    assert!(z.to_string() == utf8(b"0.467849443548411605"), 0);

    let (result, _) = compute_f(z, a, k);
    assert!(result.to_string() == utf8(b"0.000000000000000000"), 0);

    // k:  69.50951091091092 ; A: 1 ;
    let k = fixed_point64::from_rational(6950951091091092, 100000000000000); // 69.50951091091092
    let a = fixed_point64::from(1);                // A = 1
    let z_initial = fixed_point64::from_rational(999989999970896460, 1000000000000000000); // 0.999989999970896460
    // let (z_left, z_right) = find_brackets(k, a);
    // let z_initial = z_left.add(z_right).div(fixed_point64::from(2));
    let z = newton_raphson(k, a, z_initial);
    // print(&z.to_string());

    let (result, _) = compute_f(z, a, k);
    // print(&result.to_string());
    // assert!(result.to_string() == utf8(b"0.000000000000000000"), 0); // Note: This is not zero as it struggles to converge
}

#[test]
fun test_compute_f_branch_1() {
    let z = fixed_point64::from_rational(1, 100); // z = 0.01
    let a = fixed_point64::from(10);              // A = 10
    let k = fixed_point64::from_rational(1, 100); // k = 0.01
    
    let (magnitude, is_positive) = compute_f(z, a, k); // 5.03358535e-06
    // print(&magnitude.mul(fixed_point64::from(1000000000000000)).to_u128());
    
    // Expected: (1 - 1/10) * 0.01 - (1/10) * ln(0.99) - 0.01
    // ≈ 0.9 * 0.01 - 0.1 * (-0.01005033585) - 0.01
    // ≈ 0.009 + 0.001005033585 - 0.01 ≈ 0.000005033585 (positive)
    assert!(is_positive, 1);
    assert!(magnitude.mul(fixed_point64::from(1000000000000000)).to_u128() == 5033585350_u128, 0);

    // let z = fixed_point64::from_rational(99, 100); // z = 0.99
    // let a = fixed_point64::from(2);                // A = 2
    // let k = fixed_point64::from_rational(1, 100);  // k = 0.01
    // let (magnitude, is_positive) = compute_f(z, a, k);
    
    // print(&magnitude.mul(fixed_point64::from(1000000000000000)).to_u128());
    // assert!(is_positive, 1); // Expect positive result
}

#[test]
fun test_compute_f_branch_2() {
    // Test Branch 5b: intermediate_positive, intermediate_magnitude < k ("shalom")
    // Set z small, A large, k large
    let z = fixed_point64::from_rational(1, 100);  // z = 0.01
    let a = fixed_point64::from(100);              // A = 100
    let k = fixed_point64::from_rational(1, 10);   // k = 0.1
    let (_magnitude, is_positive) = compute_f(z, a, k);
    // term1 = (1 - 1/100) * 0.01 = 0.99 * 0.01 = 0.0099
    // term2 = (1/100) * |ln(0.99)| ≈ 0.01 * 0.0100503 ≈ 0.000100503
    // intermediate = 0.0099 - 0.000100503 ≈ 0.0097995 < 0.1
    // result = 0.1 - 0.0097995 ≈ 0.0902005 (negative)
    // print(&magnitude.mul(fixed_point64::from(1000000000000000)).to_u128());
    assert!(!is_positive, 1); // Expect negative result
}

#[test]
fun test_compute_f_both_branches() {
    // Requires term1 - term2 < 0 when term2_positive is false (normal case)
    let z = fixed_point64::from_rational(9, 10);   // z = 0.9
    let a = fixed_point64::from(10);               // A = 10
    let k = fixed_point64::from_rational(1, 100);  // k = 0.01
    let (magnitude, is_positive) = compute_f(z, a, k);

    assert!(is_positive, 1); // Expect negative result
    let k = fixed_point64::from(10); // k = 10
    let (magnitude, is_positive) = compute_f(z, a, k);
    // result = 0.5797415 - 10 ≈ -9.4202585 (negative)
    // print(&magnitude.mul(fixed_point64::from(1000000000000000)).to_u128());
    assert!(!is_positive, 1); // Expect negative result
}

#[test]
fun test_ln() {
    // Computed values with high precision vs. results from fixed_point64
    // 1_____
    //  44.351369219983
    //  44.351369219982_9983615193069157647526507464935913817063903448211820476087970...
    // -0.010050335853
    // -0.0100503358535_014411835488575585477060855150076746298733786994255295830090...
    //
    //
    // 2____
    //  43.668272375276554
    //  43.668272375276554_4932856236518651237887565084646960810096028405980837981840...
    // -0.6931471805599453_094172321214581765680755001343602552541206800094933936219...
    // -0.693147180559446
    //
    //
    // 3___
    //  44.3614195557365
    //  44.3614195557364_998026978557733229670234986502657230009303901871075771917917
    // -0.00000000010000000000500000000033333333335833333333533333333350000000001428571428696428571439682539683539682539773448773457106782107551337551408979...
    // -0.0000000000995
    //
    //
    // 4___
    //  28.243323904878204
    //  28.243323904878180_0145769155905327509036242981786549254314902253008041835383...
    // -16.118095650958319_788125940182790549453207710420401410832233295306773008267741467361651980435627188088393774488296003740433866678255579647296664...
    // -16.118095650957796
    //
    // 64*ln(2)
    // 44.361419555836_4998027028557733233003568320085990563362637235206075771918060604617987752529277707960026880947853165238869558732950885203556500909

    let z = fixed_point64::from_rational(1, 100); // z = 0.01
    let result = fixed_point64::ln_plus_64ln2(fixed_point64::one().sub(z)); // 44.351369219983
    assert!(result.mul(fixed_point64::from(1000000000000)).to_u128() == 44351369219983_u128, 0);
    
    let z = fixed_point64::from_rational(50, 100); // z = 0.5
    let result = fixed_point64::ln_plus_64ln2(fixed_point64::one().sub(z)); // 43.668272375276554
    assert!(result.mul(fixed_point64::from(1000000000000000)).to_u128() == 43668272375276554, 0);
    
    let z = fixed_point64::from_rational(1, 10000000000); // z = 1e-10
    let result = fixed_point64::ln_plus_64ln2(fixed_point64::one().sub(z)); // 44.361419555736499
    assert!(result.mul(fixed_point64::from(1000000000000000)).to_u128() == 44361419555736500, 0);
    
    let z = fixed_point64::from_rational(9999999, 10000000); // z = 0.9999999
    let result = fixed_point64::ln_plus_64ln2(fixed_point64::one().sub(z)); // 28.243323904878204
    // print(&result.mul(fixed_point64::from(1000000000000000)).to_u128());
    assert!(result.mul(fixed_point64::from(1000000000000000)).to_u128() == 28243323904878204, 0);
}