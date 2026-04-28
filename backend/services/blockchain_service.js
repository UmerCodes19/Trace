const crypto = require('crypto');
const supabase = require('../utils/supabase');

class BlockchainService {
  /**
   * Generates a SHA256 hash for a claim record
   */
  static generateHash(prevHash, data, timestamp) {
    const content = prevHash + JSON.stringify(data) + timestamp.toString();
    return crypto.createHash('sha256').update(content).digest('hex');
  }

  /**
   * Records a new claim in the immutable log
   */
  static async recordClaim(claimId, claimData) {
    const timestamp = Date.now();
    
    // 1. Get the last record to find the previous hash
    const { data: lastRecord, error: fetchError } = await supabase
      .from('claim_logs')
      .select('current_hash')
      .order('timestamp', { ascending: false })
      .limit(1)
      .single();

    let prevHash = 'GENESIS';
    if (fetchError && fetchError.code !== 'PGRST116') {
      throw new Error(`Failed to fetch last log: ${fetchError.message}`);
    }

    if (lastRecord) {
      prevHash = lastRecord.current_hash;
    }

    // 2. Generate new hash
    const currentHash = this.generateHash(prevHash, claimData, timestamp);

    // 3. Insert record
    const { data, error } = await supabase
      .from('claim_logs')
      .insert({
        claim_id: claimId,
        prev_hash: prevHash,
        current_hash: currentHash,
        data: claimData,
        timestamp: timestamp
      })
      .select();

    if (error) throw error;
    return data[0];
  }

  /**
   * Validates the integrity of the entire chain
   */
  static async validateChain() {
    const { data: logs, error } = await supabase
      .from('claim_logs')
      .select('*')
      .order('timestamp', { ascending: true });

    if (error) throw error;
    if (logs.length === 0) return { valid: true, message: 'Chain is empty' };

    for (let i = 0; i < logs.length; i++) {
      const current = logs[i];
      const prevHash = i === 0 ? 'GENESIS' : logs[i - 1].current_hash;

      // Check if previous hash matches
      if (current.prev_hash !== prevHash) {
        return { 
          valid: false, 
          index: i, 
          error: 'Hash link broken', 
          expected: prevHash, 
          actual: current.prev_hash 
        };
      }

      // Check if current hash is valid
      const recalculatedHash = this.generateHash(current.prev_hash, current.data, current.timestamp);
      if (current.current_hash !== recalculatedHash) {
        return { 
          valid: false, 
          index: i, 
          error: 'Content tampered', 
          expected: recalculatedHash, 
          actual: current.current_hash 
        };
      }
    }

    return { valid: true, count: logs.length };
  }
}

module.exports = BlockchainService;
