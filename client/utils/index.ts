import { keccak256 } from "@aztec/foundation/crypto";

export default function getSecretForNoir() {
  const message = "aashim";
  const hashBuffer = keccak256(Buffer.from(message));

  const hashBigInt = BigInt("0x" + hashBuffer.toHex());

  const P =
    BigInt(
      21888242871839275222246405745257275088548364400416034343698204186575808495617
    );
  // it should wrap around the prime number
  const reduced = hashBigInt % P;

  return "0x" + reduced.toString(16);
}

const secret = getSecretForNoir();
console.log("Secret: ", secret);
