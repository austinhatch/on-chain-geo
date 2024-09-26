import React, { useEffect, useState } from "react";
import styles from "./geoCard.module.scss";
import GeoSelectorForm from "../geoSelectorForm/geoSelectorForm";
import MapPicker from "../mapPicker/mapPicker";

const GeoCard = ({ geo }) => {
  const [editMode, setEditMode] = useState(false);

  const [selectedCoordinates, setSelectedCoordinates] = useState(
    geo.latitude && geo.longitude
      ? {
          lat: geo.latitude,
          lng: geo.longitude,
        }
      : null
  );
  const [selectedRadius, setSelectedRadius] = useState(geo.radius || null);

  const handleCoordinateSelect = (coordinates) => {
    setSelectedCoordinates(coordinates);
  };

  const handleRadiusSelect = (radius) => {
    setSelectedRadius(radius);
  };

  const handleEditClick = () => {
    setEditMode(!editMode);
  };

  return (
    <>
      {geo && (
        <div className={styles.parentContainer}>
          <div className={styles.geoContainer}>
            <div className={styles.geoInfoContainer}>
              <h3>{geo.name}</h3>
              {geo.startDate && (
                <p>
                  {geo.startDate.toLocaleDateString()} -
                  {geo.endDate.toLocaleDateString()}
                </p>
              )}
              <p>Radius: {geo.radius} Miles</p>
              <p>
                Coordinates: ({geo.latitude}, {geo.longitude})
              </p>
            </div>
            <div className={styles.checkinsContainer}>
              <h4>Check Ins</h4>
              {/* <p>{geo.checkins}</p> */}
            </div>
            <div className={styles.buttonContainer}>
              <button onClick={handleEditClick}>
                {!editMode ? "Edit" : "Cancel"}
              </button>
            </div>
          </div>
          {editMode && (
            <div className={styles.editContainer}>
              <div className={styles.mapPicker}>
                <MapPicker
                  onCoordinateSelect={handleCoordinateSelect}
                  coordinates={selectedCoordinates}
                  radius={selectedRadius}
                />
              </div>
              <div className={styles.geoSelectorForm}>
                <GeoSelectorForm
                  coordinates={selectedCoordinates}
                  prefillData={geo}
                  setSelectedRadius={handleRadiusSelect}
                  editMode={true}
                />
              </div>
            </div>
          )}
        </div>
      )}
    </>
  );
};

export default GeoCard;
