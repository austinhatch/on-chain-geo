import { Aptos, AptosConfig, Network, AptosAccount } from "@aptos-labs/ts-sdk";
require("dotenv").config();

// Replace with your actual private key
const privateKey = process.env.PRIVATE_KEY;

// Create an account with the private key
const account = new AptosAccount(privateKey);

// Create the Aptos configuration with the network and account
const aptosConfig = new AptosConfig({
  network: Network.TESTNET,
  account: account,
});

export const aptos = new Aptos(aptosConfig);
