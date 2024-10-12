import { aptos } from "../../configs/aptos";

//Function to get all Geo Fences created by the contract

export const getGeoFence = async (address) => {
  const object = await aptos.getObjectDataByObjectAddress({
    objectAddress: address,
  });
  console.log(object);
  const details = await getGeoFenceObjectDetails(object.object_address);
  console.log(details);
  return object;
};

export async function getGeoFenceObjectDetails(objectAddr) {
  const resourceType = `${process.env.REACT_APP_GEO_CONTRACT_ADDRESS}::on_chain_geo_v1::GeoFence`;
  try {
    const resource = await aptos.getAccountResource({
      accountAddress: objectAddr,
      resourceType: resourceType,
    });
    return resource;
  } catch (e) {}
}
