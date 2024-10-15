import React, { useEffect, useState } from "react";
import styles from "./checkInCard.module.scss";

const CheckInCard = ({ tokenData }) => {
  const [metadata, setMetadata] = useState(null);
  const [geoData, setGeoData] = useState(null);
  console.log(tokenData);

  useEffect(() => {
    const getGeoData = async () => {
      // fetch metadata
      // const metadata = await getMetadata(tokenData.tokenId);
      // setMetadata(metadata);
      // fetch geo data
      // const geoData = await getGeoDataFromCollection(tokenData.tokenId);
      // setGeoData(geoData);
    };
    getGeoData();
  }, []);

  return (
    <>
      {tokenData && (
        <div className={styles.parentContainer}>
          <div className={styles.checkInContainer}>
            <div className={styles.checkinInfoContainer}>
              <h3>{geo.name}</h3>
              {geo.startDate && (
                <p>
                  {geo.startDate} - {geo.endDate}
                </p>
              )}
              <p>Radius: {geo.radius} Miles</p>
              <p>
                Coordinates: ({geo.lat.toFixed(6)}, {geo.long.toFixed(6)})
              </p>
            </div>
            <div className={styles.checkinsContainer}>
              <h4>Check Ins</h4>
              <p>{geo.checkins}</p>
            </div>
            <div className={styles.buttonContainer}>
              <button onClick={handleEditClick}>
                {!editMode ? "Edit" : "Cancel"}
              </button>
              <button>Delete</button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};

export default CheckInCard;
