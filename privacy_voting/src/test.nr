
 fn prove_minimum_age(self, minimum_age: u32) -> AgeProof{
    let actual_age = self.birth_date.age_in_years();
    let is_valid = actual_age >= minimum_age;
    let proof_data = pedersen_hash([self.commitment, minimum_age as Field, actual_age as Field]);
    AgeProof { commitment: self.commitment, minimum_age, proof_data, is_valid }
    } // Advanced range proof fn prove_age_range(self, min_age: u32, max_age: u32) -> AgeRangeProof {  let actual_age = self.birth_date.age_in_years();  let is_valid = (actual_age >= min_age) & (actual_age <= max_age);  let proof_data = pedersen_hash([self.commitment, min_age as Field, max_age as Field, actual_age as Field]);  AgeRangeProof { commitment: self.commitment, min_age, max_age, proof_data, is_valid } }
