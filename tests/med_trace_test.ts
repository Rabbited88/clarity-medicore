import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

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
    
    // Test invalid batch number format
    let invalidFormat = chain.mineBlock([
      Tx.contractCall('med_trace', 'create-batch',
        [
          types.ascii("Aspirin"),
          types.ascii("INVALID"),
          types.uint(999999)
        ],
        manufacturer.address)
    ]);
    
    invalidFormat.receipts[0].result.expectErr(107);
    
    // Test valid batch creation
    let validBatch = chain.mineBlock([
      Tx.contractCall('med_trace', 'create-batch',
        [
          types.ascii("Aspirin"),
          types.ascii("BATCH001"),
          types.uint(999999)
        ],
        manufacturer.address)
    ]);
    
    validBatch.receipts[0].result.expectOk();
    
    // [Previous tests remain unchanged...]
  }
});
