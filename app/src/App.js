// App.js
import React, { useState } from "react";
import MapPicker from "./components/mapPicker";
import GeoSelectorForm from "./components/geoSelectorForm";
import styles from "./app.module.scss";

const App = () => {
  const [selectedCoordinates, setSelectedCoordinates] = useState(null);
  const [selectedRadius, setSelectedRadius] = useState(null);

  const handleCoordinateSelect = (coordinates) => {
    setSelectedCoordinates(coordinates);
  };

  const handleRadiusSelect = (radius) => {
    setSelectedRadius(radius);
  };

  return (
    <div className={styles.appContainer}>
      <div className={styles.mapContainer}>
        <div className={styles.mapPicker}>
          <MapPicker
            onCoordinateSelect={handleCoordinateSelect}
            radius={selectedRadius}
          />
        </div>
      </div>
      <div className={styles.formContainer}>
        <GeoSelectorForm
          coordinates={selectedCoordinates}
          setSelectedRadius={handleRadiusSelect}
        />
      </div>
    </div>
  );
};

export default App;
