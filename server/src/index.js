const express = require("express");
require("dotenv").config();
import { aptos } from "./configs/aptos";

const app = express();
const port = process.env.PORT || 3002; // Your server will run on localhost:3001

app.use(express.json());

// Handle POST request
app.post("/api/verify-location", async (req, res) => {
  const { geo_address, lat, lat_is_neg, lng, lng_is_neg, user_address } = req.body;

  try {
    // Create the transaction payload
    const func = `${process.env.REACT_APP_GEO_CONTRACT_ADDRESS}::on_chain_geo::is_within_geo`;

    // Get the account from the config
    const account = aptos.config.account;

    //Generate a random token_id
    const token_id = Math.floor(10000000 + Math.random() * 90000000).toString();

    const transaction = await aptos.transaction.build.simple({
      sender: account.accountAddress,
      data: {
        function: func,
        typeArguments: [],
        functionArguments: [
          geo_address,
          lng,
          lng_is_neg,
          lat,
          lat_is_neg,
          token_id,
          user_address
        ],
      },
    });

    // submit transaction
    const committedTransaction = await aptos.signAndSubmitTransaction({
      signer: account,
      transaction: transaction,
    });
    const waitForTransaction = await aptos.waitForTransaction({
      transactionHash: committedTransaction.hash,
    });

    if (waitForTransaction.success) {
      return {
        status: "success",
        message: "Token Created Successfully",
      };
    }
  } catch {
    return { status: "error", message: "Error Minting Token" };
  }
});

// Start the server
app.listen(port, () => {
  console.log(`Server is running on ${port}`);
});
