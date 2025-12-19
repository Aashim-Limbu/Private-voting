import { Barretenberg } from "@aztec/bb.js";
import { Fr } from "@aztec/foundation/fields";
import getSecretForNoir from "./index";
async function generateHash() {
  const bb = await Barretenberg.new();
  const param1 = new Fr(BigInt(20021029));
  const secret = Fr.fromHexString(getSecretForNoir());
  // Generate poseidon hash with the two inputs, converting Fr to Buffer
  const { hash } = await bb.poseidon2Hash({
    inputs: [param1.toBuffer(), secret.toBuffer()],
  });
  return hash;
}
generateHash().then((data) => {
  console.log("Raw Uint8Array:", data);

  // Convert Uint8Array to hex string for Noir Field
  const hexString = "0x" + Buffer.from(data).toString("hex");
  console.log("Hex (for Noir Field):", hexString);

  // Convert to decimal string (alternative format)
  const fieldValue = Fr.fromBuffer(Buffer.from(data)).toString();
  console.log("Decimal (for Noir Field):", fieldValue);
});
