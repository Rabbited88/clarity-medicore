import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

// [Previous tests remain unchanged...]

Clarinet.test({
  name: "Batch validation tests",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const manufacturer = accounts.get('wallet_1')!;
    
    // Register manufacturer
    let setup = chain.mineBlock([
      Tx.contractCall('med_trace', 'register-participant',
        [types.ascii("manufacturer")],
        manufacturer.address)
    ]);
    
    // Test invalid expiry date
    let invalidExpiry = chain.mineBlock([
      Tx.contractCall('med_trace', 'create-batch',
        [
          types.ascii("Aspirin"),
          types.ascii("BATCH001"),
          types.uint(1) // Past expiry
        ],
        manufacturer.address)
    ]);
    
    invalidExpiry.receipts[0].result.expectErr(105);
    
    // Test duplicate batch number
    let batch1 = chain.mineBlock([
      Tx.contractCall('med_trace', 'create-batch',
        [
          types.ascii("Aspirin"),
          types.ascii("BATCH001"),
          types.uint(999999)
        ],
        manufacturer.address)
    ]);
    
    let duplicateBatch = chain.mineBlock([
      Tx.contractCall('med_trace', 'create-batch',
        [
          types.ascii("Paracetamol"),
          types.ascii("BATCH001"),
          types.uint(999999)
        ],
        manufacturer.address)
    ]);
    
    duplicateBatch.receipts[0].result.expectErr(106);
  }
});
