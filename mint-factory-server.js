#!/usr/bin/env bun

/**
 * Mint Factory Server
 * API server that deploys NFT contracts based on POST parameters
 * Listens only on localhost and expects environment variables in .env
 */

import { Elysia } from 'elysia';

const PORT = 7890;

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
    
    // Add new Forge 1.0 compatible options
    if (params.manual_verify === true) args.push("--manual-verify");
    
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
    // Updated to match the new output format from Forge 1.0
    const addressMatch = stdout.match(/Deployed GenericFarcasterNFT at: (0x[a-fA-F0-9]{40})/);
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

// Create Elysia server - only listening on localhost
const app = new Elysia()
  // Health check endpoint
  .get('/health', () => ({
    status: 'ok'
  }))
  // Deploy endpoint
  .post('/deploy', async ({ body }) => {
    try {
      // Validate recipient parameter
      const validation = validateParams(body);
      if (!validation.valid) {
        return {
          success: false,
          error: validation.error
        };
      }

      // Deploy contract
      const result = await deployContract(body);
      return result;
    } catch (error) {
      console.error("Error in /deploy:", error);
      return {
        success: false,
        error: error.message || "Internal server error"
      };
    }
  })
  // Handle 404
  .onError(({ code }) => {
    if (code === 'NOT_FOUND') {
      return {
        success: false,
        error: 'Not found'
      };
    }
  })
  .listen({
    port: PORT,
    hostname: 'localhost'
  });

// Store the actual server instance to get the actual port
const server = app.server;
const actualPort = server?.port || PORT;
console.log(`Mint Factory Server running at http://localhost:${actualPort}`);
console.log("IMPORTANT: This server only accepts local connections");
