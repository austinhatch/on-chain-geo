import React, { useState } from "react";
import styles from "./geoSelectorForm.module.scss";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { aptos } from "../../configs/aptos";

const GeoSelectorForm = ({
  coordinates,
  prefillData,
  setSelectedRadius,
  editMode,
}) => {
  const [startDate, setStartDate] = useState(prefillData?.startDate || null);
  const [endDate, setEndDate] = useState(prefillData?.endDate || null);
  const [radius, setRadius] = useState(prefillData?.radius || null);
  const [latitude, setLatitude] = useState(null);
  const [longitude, setLongitude] = useState(null);
  const [name, setName] = useState(prefillData?.name || null);
  const [unit, setUnit] = useState("miles");

  const [error, setError] = useState("");

  const { account, wallet, signAndSubmitTransaction } = useWallet();

  const handleSubmit = async (event) => {
    event.preventDefault();

    console.log("Submitting form...");
    console.log("Account: ", account);
    console.log("Wallet: ", wallet);
    const radiusInMiles = unit === "yards" ? radius / 1760 : radius;
    console.log({
      startDate,
      endDate,
      radiusInMiles,
      latitude,
      longitude,
    });
    await createGeo();
    if (editMode) {
      console.log("Edit Mode");
    } else {
      console.log("Create Mode");
    }
  };

  const createGeo = async () => {
    const response = await signAndSubmitTransaction({
      sender: account.address,
      data: {
        function: `${process.env.REACT_GEO_CONTRACT_ADDRESS}::on_chain_geo::create_geofence`,
        functionArguments: [account.address, name],
      },
    });
    // if you want to wait for transaction
    try {
      await aptos.waitForTransaction({ transactionHash: response.hash });
    } catch (error) {
      console.error(error);
    }
  };

  const handleStartDateChange = (e) => {
    const newStartDate = e.target.value;
    setStartDate(newStartDate);
    if (newStartDate >= endDate) {
      setError("End date must be greater than start date.");
    } else {
      setError("");
    }
  };

  const handleEndDateChange = (e) => {
    const newEndDate = e.target.value;
    setEndDate(newEndDate);
    if (newEndDate <= startDate) {
      setError("End date must be greater than start date.");
    } else {
      setError("");
    }
  };

  const handleRadiusChange = (value) => {
    const radiusInMiles = unit === "yards" ? value / 1760 : value;
    setRadius(value);
    setSelectedRadius(radiusInMiles);
  };

  const handleUnitChange = (value) => {
    const radiusInMiles = value === "yards" ? radius / 1760 : radius;
    setUnit(value);
    setSelectedRadius(radiusInMiles);
  };

  return (
    <form onSubmit={handleSubmit}>
      <div className={styles.parentContainer}>
        {coordinates && (
          <div className={styles.coordinatesContainer}>
            <label>
              Latitude:
              <input
                value={coordinates.lat.toFixed(6)}
                contentEditable="false"
                onChange={(e) => setLatitude(e.target.value)}
                required
              />
            </label>
            <label>
              Longitude:
              <input
                value={coordinates.lng.toFixed(6)}
                contentEditable="false"
                onChange={(e) => setLongitude(e.target.value)}
                required
              />
            </label>
          </div>
        )}
        <label>
          Start Date:
          <input
            type="datetime-local"
            value={startDate}
            onChange={handleStartDateChange}
            required
          />
        </label>
        <label>
          End Date:
          <input
            type="datetime-local"
            value={endDate}
            onChange={handleEndDateChange}
            required
          />
        </label>
        <label>
          Radius:
          <input
            type="number"
            value={radius}
            onChange={(e) => handleRadiusChange(e.target.value)}
            required
          />
          <select
            value={unit}
            onChange={(e) => handleUnitChange(e.target.value)}
            required
          >
            <option value="miles">Miles</option>
            <option value="yards">Yards</option>
          </select>
        </label>
        <label>
          Name:
          <input
            value={name}
            onChange={(e) => setName(e.target.value)}
            required
          />
        </label>
        <button type="submit" disabled={!!error}>
          Submit
        </button>
        <p className={styles.errorText}>{error}</p>
      </div>
    </form>
  );
};

export default GeoSelectorForm;
