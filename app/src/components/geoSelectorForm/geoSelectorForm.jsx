import React, { useState } from "react";
import styles from "./geoSelectorForm.module.scss";

const GeoSelectorForm = ({ coordinates, prefillData, setSelectedRadius, editMode }) => {
  console.log(coordinates);
  console.log(prefillData)
  const [startDate, setStartDate] = useState(prefillData?.startDate || "");
  const [endDate, setEndDate] = useState(prefillData?.endDate || "");
  const [radius, setRadius] = useState(prefillData?.radius || "");
  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");
  const [name, setName] = useState(prefillData?.name || "");
  const [unit, setUnit] = useState("miles");

  const handleSubmit = (event) => {
    event.preventDefault();
    const radiusInMiles = unit === "yards" ? radius / 1760 : radius;
    console.log({
      startDate,
      endDate,
      radiusInMiles,
      latitude,
      longitude,
    });
    if (editMode) {
      console.log("Edit Mode")
    }
    else {
      console.log("Create Mode")
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
              />
            </label>
            <label>
              Longitude:
              <input
                value={coordinates.lng.toFixed(6)}
                contentEditable="false"
                onChange={(e) => setLongitude(e.target.value)}
              />
            </label>
          </div>
        )}
        <label>
          Start Date:
          <input
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            required
          />
        </label>
        <label>
          End Date:
          <input
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
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
        <button type="submit">Submit</button>

      </div>
    </form >
  );
};

export default GeoSelectorForm;
