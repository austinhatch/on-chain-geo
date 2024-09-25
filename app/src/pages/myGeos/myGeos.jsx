// App.jsx
import React, { useState, useEffect } from "react";
import GeoCard from "../../components/geoCard/geoCard";
import styles from "./myGeos.module.scss";

const MyGeos = () => {
  const [ownedGeos, setOwnedGeos] = useState([]);

  useEffect(() => {
    const getOwnedGeos = async () => {
      /**
       * TODO: Fetch owned geos from Aptos
       */
      setOwnedGeos([
        {
          id: 1,
          name: "Home",
          description: "My House",
          radius: 0.001,
          lat: 25.7479868,
          long: -80.319509,
          checkins: 10,
        },
      ]);
    };
    getOwnedGeos();
  }, []);

  return (
    <div className={styles.parentContainer}>
      <div className={styles.headerContainer}>
        <h1>My Geos</h1>
      </div>
      {ownedGeos && ownedGeos.length > 0 && (
        <div className={styles.geosContainer}>
          {ownedGeos.map((geo) => (
            <GeoCard key={geo.id} geo={geo} className={styles.geoCard} />
          ))}
        </div>
      )}
    </div>
  );
};

export default MyGeos;
