// use std::hash::pedersen_hash;
use dep::poseidon::poseidon2;

struct Date {
    year: u32,
    month: u32,
    day: u32,
}
struct IdentityCommitment {
    birth_date: Date,
    secret: Field,
    commitment: Field,
}
struct AgeProof {
    commitment: Field,
    minimum_age: u32,
    proof_data: Field,
    is_valid: bool,
}
impl Date {
    fn to_field(self) -> Field {
        (self.year * 10000 + self.month * 100 + self.day) as Field
    }
    fn age_in_years(self, current_date: Date) -> u32 {
        let mut age = current_date.year - self.year;
        if current_date.month < self.month {
            age -= 1;
        } else if (current_date.month == self.month) & (current_date.day < self.day) {
            age -= 1;
        }
        age
    }
    fn is_valid(self) -> bool {
        let year_valid = (self.year >= 1900) & (self.year <= 2100);
        let month_valid = (self.month >= 1) & (self.month <= 12);
        let day_valid = (self.day >= 1) & (self.day <= 31);
        year_valid & month_valid & day_valid
    }
    fn is_before_or_equal(self, other: Date) -> bool {
        if self.year < other.year {
            true
        } else if self.year > other.year {
            false
        } else {
            // Same year
            if self.month < other.month {
                true
            } else if self.month > other.month {
                false
            } else {
                //Same month
                self.day <= other.day
            }
        }
    }
}
impl IdentityCommitment {
    fn new(birth_date: Date, secret: Field) -> Self {
        let commitment = poseidon2::Poseidon2::hash([birth_date.to_field(), secret], 2);
        IdentityCommitment { birth_date, secret, commitment }
    }
    fn verify_commitment(self) -> bool {
        let expected_commitment =
            poseidon2::Poseidon2::hash([self.birth_date.to_field(), self.secret], 2);
        expected_commitment == self.commitment
    }
    fn prove_minimum_age(self, minimum_age: u32, current_date: Date) -> AgeProof {
        let actual_age = self.birth_date.age_in_years(current_date);
        let is_valid = actual_age >= minimum_age;
        let proof_data = poseidon2::Poseidon2::hash(
            [self.commitment, minimum_age as Field, actual_age as Field],
            3,
        );
        AgeProof { commitment: self.commitment, minimum_age, proof_data, is_valid }
    }
}

fn main(
    // Private inputs (hidden)
    birth_year: u32,
    birth_month: u32,
    birth_day: u32,
    secret: Field,
    // Public inputs (visible)
    expected_commitment: pub Field,
    minimum_age: pub u32,
    current_year: pub u32,
    current_month: pub u32,
    current_day: pub u32,
) -> pub bool {
    let birth_date = Date { year: birth_year, month: birth_month, day: birth_day };
    let current_date = Date { year: current_year, month: current_month, day: current_day };

    assert(birth_date.is_valid());
    assert(current_date.is_valid());

    assert(birth_date.is_before_or_equal(current_date));

    let identity = IdentityCommitment::new(birth_date, secret);

    assert(identity.commitment == expected_commitment);

    let proof = identity.prove_minimum_age(minimum_age, current_date);
    assert(proof.is_valid);

    proof.is_valid
}

#[test]
fn test_basic_date_operations() {
    let birth_date = Date { year: 1990, month: 6, day: 15 };
    let current_date = Date { year: 2024, month: 1, day: 1 };
    assert(birth_date.is_valid());

    let age = birth_date.age_in_years(current_date);
    assert(age == 33);

    let field_value = birth_date.to_field();
    assert(field_value == 19900615);
}
#[test]
fn test_identity_commitment_system() {
    let birth_date = Date { year: 1995, month: 3, day: 20 };
    let current_date = Date { year: 2024, month: 1, day: 1 };
    let secret = 12345;

    let identity = IdentityCommitment::new(birth_date, secret);
    assert(identity.verify_commitment());

    // Test minimum age proof
    let proof = identity.prove_minimum_age(18, current_date);
    assert(proof.is_valid); // Should be valid since age is 29

    let proof_underage = identity.prove_minimum_age(30, current_date);
    assert(!proof_underage.is_valid); // Should be invalid since age is 29
}
#[test]
fn test_date_comparison() {
    let earlier = Date { year: 2020, month: 5, day: 15 };
    let later = Date { year: 2024, month: 1, day: 1 };

    assert(earlier.is_before_or_equal(later));
    assert(!later.is_before_or_equal(earlier));

    let same = Date { year: 2024, month: 1, day: 1 };
    assert(later.is_before_or_equal(same));
}
#[test]
fn test_dynamic_current_date() {
    let birth_date = Date { year: 2000, month: 12, day: 31 };
    let secret = 54321;

    let identity = IdentityCommitment::new(birth_date, secret);

    // Test with different current dates
    let date_2024 = Date { year: 2024, month: 6, day: 1 };
    let proof_2024 = identity.prove_minimum_age(21, date_2024);
    assert(proof_2024.is_valid); // Age is 23

    let date_2021 = Date { year: 2021, month: 1, day: 1 };
    let proof_2021 = identity.prove_minimum_age(21, date_2021);
    assert(!proof_2021.is_valid); // Age is 20
}
