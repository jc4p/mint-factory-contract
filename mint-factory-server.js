#!/usr/bin/env bun

/**
 * Mint Factory Server
 * API server that deploys NFT contracts based on POST parameters
 * Listens only on localhost and expects environment variables in .env
 */

const PORT = 4000;

// Function to run deploy-and-verify.sh with parameters
async function deployContract(params) {
  try {
    console.log("Deploying contract with parameters:", {
      ...params,
      // Don't log private key if it exists in params
      private_key: params.private_key ? "[REDACTED]" : undefined
    });
    
    // Build command arguments
    const args = [];
    
    // Add all parameters as command line arguments
    if (params.base_uri) args.push("--base-uri", params.base_uri);
    if (params.name) args.push("--name", params.name);
    if (params.symbol) args.push("--symbol", params.symbol);
    if (params.price) args.push("--price", params.price);
    if (params.recipient) args.push("--recipient", params.recipient);
    if (params.max_supply !== undefined) args.push("--max-supply", params.max_supply.toString());
    if (params.chain_id) args.push("--chain-id", params.chain_id);
    
    // Create a process to run deploy-and-verify.sh
    const proc = Bun.spawn(["./deploy-and-verify.sh", ...args], {
      cwd: process.cwd(),
      env: process.env, // Pass through environment variables from .env
      stdout: "pipe",
      stderr: "pipe",
    });

    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();
    
    // Wait for the process to exit
    const exitCode = await proc.exited;
    
    console.log("Deploy script output:", stdout);
    
    if (exitCode !== 0) {
      console.error("Deploy script error:", stderr);
      return {
        success: false,
        error: "Deployment failed",
        output: stdout,
        stderr: stderr
      };
    }
    
    // Extract contract address from the output
    const addressMatch = stdout.match(/Contract deployed at: (0x[a-fA-F0-9]{40})/);
    const contractAddress = addressMatch ? addressMatch[1] : null;
    
    return {
      success: true,
      contractAddress,
      output: stdout
    };
  } catch (error) {
    console.error("Error running deploy script:", error);
    return {
      success: false,
      error: error.message || "Unknown error occurred"
    };
  }
}

// Validate the recipient parameter is present
function validateParams(params) {
  if (!params.recipient) {
    return {
      valid: false,
      error: "Missing required parameter: recipient"
    };
  }
  
  return { valid: true };
}

// Create HTTP server - only listening on localhost
const server = Bun.serve({
  port: PORT,
  hostname: "localhost", // Only bind to localhost interface
  async fetch(req) {
    const url = new URL(req.url);
    const path = url.pathname;
    
    // Health check endpoint
    if (path === "/health" && req.method === "GET") {
      return new Response(JSON.stringify({ status: "ok" }), {
        status: 200,
        headers: { "Content-Type": "application/json" }
      });
    }
    
    // Handle deploy requests
    if (path === "/deploy" && req.method === "POST") {
      try {
        // Parse JSON request body
        const params = await req.json();
        
        // Validate recipient parameter
        const validation = validateParams(params);
        if (!validation.valid) {
          return new Response(JSON.stringify({ 
            success: false, 
            error: validation.error 
          }), {
            status: 400,
            headers: { "Content-Type": "application/json" }
          });
        }
        
        // Deploy contract
        const result = await deployContract(params);
        
        return new Response(JSON.stringify(result), {
          status: result.success ? 200 : 500,
          headers: { "Content-Type": "application/json" }
        });
      } catch (error) {
        console.error("Error in /deploy:", error);
        
        return new Response(JSON.stringify({ 
          success: false, 
          error: error.message || "Internal server error"
        }), {
          status: 500,
          headers: { "Content-Type": "application/json" }
        });
      }
    }
    
    // Route not found
    return new Response(JSON.stringify({ 
      success: false, 
      error: "Not found" 
    }), {
      status: 404,
      headers: { "Content-Type": "application/json" }
    });
  }
});

console.log(`Mint Factory Server running at http://localhost:${PORT}`);
console.log("IMPORTANT: This server only accepts local connections");

// Documentation
console.log(`
API Endpoints:
  GET /health - Health check endpoint
  POST /deploy - Deploy a new NFT contract

Required Parameters for /deploy:
  - recipient: Payment recipient address (required)

Optional Parameters:
  - base_uri: Base URI for NFT metadata (default: https://fc-nfts.kasra.codes/tokens/)
  - name: NFT collection name (default: Generic Farcaster NFT)
  - symbol: NFT symbol (default: GNFT)
  - price: Mint price in ether (default: 0.0025 ether)
  - max_supply: Maximum supply (default: 0, which means unlimited)
  - chain_id: Chain ID (default: 8453 for Base)

Note: RPC_URL, PRIVATE_KEY, and BASESCAN_API_KEY must be set in your .env file

Example curl command:
  curl -X POST http://localhost:${PORT}/deploy \\
    -H "Content-Type: application/json" \\
    -d '{
      "name": "My NFT Collection",
      "symbol": "MYNFT",
      "base_uri": "https://example.com/tokens/",
      "price": "0.05 ether",
      "recipient": "0x1234...5678",
      "max_supply": 1000
    }'
`);

export default server;