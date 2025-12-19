// use std::hash::pedersen_hash;
use dep::poseidon::poseidon2;
global CURRENT_YEAR: u32 = 2024;
global CURRENT_MONTH: u32 = 1;
global CURRENT_DAY: u32 = 1;

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
    fn age_in_years(self) -> u32 {
        let mut age = CURRENT_YEAR - self.year;
        if CURRENT_MONTH < self.month {
            age -= 1;
        } else if (CURRENT_MONTH == self.month) & (CURRENT_DAY < self.day) {
            age -= 1;
        }
        age
    }
    fn is_valid(self) -> bool {
        let year_valid = (self.year >= 1900) & (self.year <= CURRENT_YEAR);
        let month_valid = (self.month >= 1) & (self.month <= 12);
        let day_valid = (self.day >= 1) & (self.day <= 31);
        year_valid & month_valid & day_valid
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
    fn prove_minimum_age(self, minimum_age: u32) -> AgeProof {
        let actual_age = self.birth_date.age_in_years();
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
) -> pub bool {
    let birth_date = Date { year: birth_year, month: birth_month, day: birth_day };

    assert(birth_date.is_valid());

    let identity = IdentityCommitment::new(birth_date, secret);

    assert(identity.commitment == expected_commitment);

    let proof = identity.prove_minimum_age(minimum_age);

    
    proof.is_valid
}

#[test]
fn test_basic_date_operations() {
    let birth_date = Date { year: 1990, month: 6, day: 15 };

    assert(birth_date.is_valid());

    let age = birth_date.age_in_years();
    assert(age == 33);

    let field_value = birth_date.to_field();
    assert(field_value == 19900615);
}
#[test]
fn test_identity_commitment_system() {
    let birth_date = Date { year: 1995, month: 3, day: 20 };
    let secret = 12345;

    let identity = IdentityCommitment::new(birth_date, secret);
    assert(identity.verify_commitment());

    // Test minimum age proof
    let proof = identity.prove_minimum_age(18);
    assert(proof.is_valid); // Should be valid since age is 29

    let proof_underage = identity.prove_minimum_age(30);
    assert(!proof_underage.is_valid); // Should be invalid since age is 29
}
