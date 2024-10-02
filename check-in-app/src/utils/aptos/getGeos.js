import { aptos } from "../../configs/aptos";

//Function to get all Geo Fences created by the contract
export const getGeoFences = async () => {
  const event_type = `${process.env.REACT_APP_GEO_CONTRACT_ADDRESS}::0x1::transaction_fee::FeeStatement`;
  console.log(event_type);

  const objects = await aptos.getAccountOwnedObjects({
    accountAddress: process.env.REACT_APP_GEO_CONTRACT_ADDRESS,
  });
  console.log(objects);

  for (const object of objects) {
    console.log(object.object_address);
    const tx = await aptos.getAccountTransactions({
      accountAddress: object.object_address,
    });
    console.log(tx);
  }

  const events = await aptos.getModuleEventsByEventType({
    eventType: event_type,
  });
  console.log(events);
};
