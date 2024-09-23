import React, { useState } from "react";

const GeoSelectorForm = ({ coordinates, setSelectedRadius }) => {
  console.log(coordinates);
  const [startDate, setStartDate] = useState("");
  const [endDate, setEndDate] = useState("");
  const [radius, setRadius] = useState("");
  const [latitude, setLatitude] = useState("");
  const [longitude, setLongitude] = useState("");
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
      <div>
        {coordinates && (
          <div>
            <label>
              Latitude:
              <input
                value={coordinates.lat}
                contentEditable="false"
                onChange={(e) => setLatitude(e.target.value)}
              />
            </label>
            <label>
              Longitude:
              <input
                value={coordinates.lng}
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
          />
        </label>
      </div>
      <div>
        <label>
          End Date:
          <input
            type="date"
            value={endDate}
            onChange={(e) => setEndDate(e.target.value)}
          />
        </label>
      </div>
      <div>
        <label>
          Radius:
          <input
            type="number"
            value={radius}
            onChange={(e) => handleRadiusChange(e.target.value)}
          />
          <select
            value={unit}
            onChange={(e) => handleUnitChange(e.target.value)}
          >
            <option value="miles">Miles</option>
            <option value="yards">Yards</option>
          </select>
        </label>
      </div>
      <button type="submit">Submit</button>
    </form>
  );
};

export default GeoSelectorForm;
