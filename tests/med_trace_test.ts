import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Participant registration test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const manufacturer = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('med_trace', 'register-participant', 
        [types.ascii("manufacturer")], 
        deployer.address)
    ]);
    
    block.receipts[0].result.expectOk();
    
    let query = chain.mineBlock([
      Tx.contractCall('med_trace', 'get-participant-info',
        [types.principal(deployer.address)],
        deployer.address)
    ]);
    
    query.receipts[0].result.expectOk().expectSome();
  }
});

Clarinet.test({
  name: "Batch creation and transfer test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const manufacturer = accounts.get('wallet_1')!;
    const distributor = accounts.get('wallet_2')!;
    
    // Register participants
    let setup = chain.mineBlock([
      Tx.contractCall('med_trace', 'register-participant',
        [types.ascii("manufacturer")],
        manufacturer.address),
      Tx.contractCall('med_trace', 'register-participant',
        [types.ascii("distributor")],
        distributor.address)
    ]);
    
    // Create batch
    let batch = chain.mineBlock([
      Tx.contractCall('med_trace', 'create-batch',
        [
          types.ascii("Aspirin"),
          types.ascii("BATCH001"),
          types.uint(100000)
        ],
        manufacturer.address)
    ]);
    
    batch.receipts[0].result.expectOk();
    let batchId = batch.receipts[0].result.expectOk();
    
    // Transfer batch
    let transfer = chain.mineBlock([
      Tx.contractCall('med_trace', 'transfer-batch',
        [
          batchId,
          types.principal(distributor.address)
        ],
        manufacturer.address)
    ]);
    
    transfer.receipts[0].result.expectOk();
    
    // Verify transfer
    let verify = chain.mineBlock([
      Tx.contractCall('med_trace', 'get-batch-info',
        [batchId],
        deployer.address)
    ]);
    
    let batchInfo = verify.receipts[0].result.expectOk().expectSome();
    assertEquals(batchInfo['current-owner'], distributor.address);
  }
});

Clarinet.test({
  name: "Batch status update test",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const manufacturer = accounts.get('wallet_1')!;
    
    // Register manufacturer
    let setup = chain.mineBlock([
      Tx.contractCall('med_trace', 'register-participant',
        [types.ascii("manufacturer")],
        manufacturer.address)
    ]);
    
    // Create batch
    let batch = chain.mineBlock([
      Tx.contractCall('med_trace', 'create-batch',
        [
          types.ascii("Aspirin"),
          types.ascii("BATCH001"),
          types.uint(100000)
        ],
        manufacturer.address)
    ]);
    
    let batchId = batch.receipts[0].result.expectOk();
    
    // Update status
    let update = chain.mineBlock([
      Tx.contractCall('med_trace', 'update-batch-status',
        [
          batchId,
          types.ascii("recalled")
        ],
        manufacturer.address)
    ]);
    
    update.receipts[0].result.expectOk();
    
    // Verify status
    let verify = chain.mineBlock([
      Tx.contractCall('med_trace', 'get-batch-info',
        [batchId],
        manufacturer.address)
    ]);
    
    let batchInfo = verify.receipts[0].result.expectOk().expectSome();
    assertEquals(batchInfo['status'], "recalled");
  }
});
