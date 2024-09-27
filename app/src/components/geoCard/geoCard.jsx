import React, { useEffect, useState } from "react";
import styles from "./geoCard.module.scss";
import MapPicker from "../mapPicker/mapPicker";

const GeoCard = ({ geo }) => {
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
              <button>Delete</button>
            </div>
          </div>
          <div className={styles.mapContainer}>
            <div className={styles.mapPicker}>
              <MapPicker
                coordinates={{
                  lat: geo.latitude,
                  lng: geo.longitude,
                }}
                radius={geo.radius}
                viewOnly={true}
              />
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default GeoCard;
