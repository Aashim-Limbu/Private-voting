use std::hash::pedersen_hash;
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
        let commitment = pedersen_hash([birth_date.to_field(), secret]);
        IdentityCommitment { birth_date, secret, commitment }
    }
    fn verify_commitment(self) -> bool {
        let expected_commitment = pedersen_hash([self.birth_date.to_field(), self.secret]);
        expected_commitment == self.commitment
    }
    fn prove_minimum_age(self, minimum_age: u32) -> AgeProof {
        let actual_age = self.birth_date.age_in_years();
        let is_valid = actual_age >= minimum_age;
        let proof_data =
            pedersen_hash([self.commitment, minimum_age as Field, actual_age as Field]);
        AgeProof { commitment: self.commitment, minimum_age, proof_data, is_valid }
    }
}
#[test]
fn test_basic_date_operations() {
    let birth_date = Date { year: 1990, month: 6, day: 15 };

    // Test date validation
    assert(birth_date.is_valid());

    // Test age calculation
    let age = birth_date.age_in_years();
    assert(age == 33); // Based on CURRENT_YEAR = 2024

    // Test field encoding
    let field_value = birth_date.to_field();
    assert(field_value == 19900615);
}
