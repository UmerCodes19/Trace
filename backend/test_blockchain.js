const BlockchainService = require('./services/blockchain_service');

async function testBlockchain() {
  console.log('--- Trace Blockchain Integrity Test ---');
  
  try {
    // 1. Record a mock claim
    console.log('Recording mock claim...');
    const claimId = 'test-claim-' + Date.now();
    const claimData = {
      action: 'TEST_ACTION',
      itemTitle: 'Test Item',
      claimerId: 'user-123',
      ownerId: 'owner-456'
    };
    
    const entry = await BlockchainService.recordClaim(claimId, claimData);
    console.log('✓ Entry recorded with hash:', entry.current_hash);

    // 2. Validate chain
    console.log('\nValidating chain integrity...');
    const result = await BlockchainService.validateChain();
    
    if (result.valid) {
      console.log('✓ CHAIN IS VALID. Records checked:', result.count);
    } else {
      console.error('✗ CHAIN COMPROMISED:', result.error);
      console.error('Details:', result);
    }

  } catch (error) {
    console.error('Test failed:', error.message);
  }
}

testBlockchain();
