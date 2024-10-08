import React, { useEffect, useState } from "react";
import styles from "./checkIn.module.scss";
import { GoogleMap, useJsApiLoader, Marker } from "@react-google-maps/api";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { getGeoFences } from "../../utils/aptos/getGeos";

const containerStyle = {
  width: "100%",
  height: "100%",
};

const CheckIn = () => {
  const { wallet, account, signAndSubmitTransaction } = useWallet();

  const [location, setLocation] = useState(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
  });

  useEffect(() => {
    const getGeos = async () => {
      const geos = await getGeoFences();
      console.log("geos", geos);
    };
    getGeos();
  }, []);

  const handleGetLocation = () => {
    console.log("account", account);
    if (!account) {
      setError("Please connect your wallet to check in");
      return;
    }
    if (navigator.geolocation) {
      setLoading(true);
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const coordinates = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          };
          console.log("coordinates", coordinates);
          setLocation(coordinates);
          setError("");
        },
        (error) => {
          setError("Unable to retrieve your location");
        }
      );
    } else {
      setError("Geolocation is not supported by this browser");
    }
    setLoading(false);
  };

  if (!isLoaded) {
    return <div>Loading...</div>;
  }

  return (
    <div className={styles.parentContainer}>
      <div className={styles.headerContainer}>
        <p className={styles.instructionsText}>
          Click on Check In below to see a list of available check in rewards
          for your current location!
        </p>
      </div>
      <button className={styles.checkInButton} onClick={handleGetLocation}>
        CHECK IN
      </button>
      {loading && <p>Loading...</p>}
      {location && (
        <div className={styles.myLocationContainer}>
          <h3>Your Location</h3>
          <div className={styles.mapContainer}>
            <GoogleMap
              mapContainerStyle={containerStyle}
              center={location}
              zoom={10}
            >
              {location && (
                <>
                  <Marker position={location} />
                </>
              )}
            </GoogleMap>
          </div>
        </div>
      )}
      {error && <p className={styles.error}>{error}</p>}
    </div>
  );
};

export default CheckIn;
