import React, { useEffect, useState } from "react";
import styles from "./checkIn.module.scss";
import {
  GoogleMap,
  useJsApiLoader,
  Marker,
  Circle,
} from "@react-google-maps/api";
import { useWallet } from "@aptos-labs/wallet-adapter-react";
import { getGeoFence } from "../../utils/aptos/getGeos";
import { getDistance } from "geolib"; // Import the getDistance function from geolib

const containerStyle = {
  width: "100%",
  height: "100%",
};

// Define custom marker icons
const customIcon1 = "https://maps.google.com/mapfiles/ms/icons/red-dot.png";
const customIcon2 = "https://maps.google.com/mapfiles/ms/icons/blue-dot.png";

const CheckIn = () => {
  const { wallet, account, signAndSubmitTransaction } = useWallet();

  // location of user
  const [location, setLocation] = useState(null);

  // location of geo fence
  const [geoLocation, setGeoLocation] = useState(null);

  //radius of geo fence
  const [radius, setRadius] = useState(null);

  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [checkInAddress, setCheckInAddress] = useState("");

  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: process.env.REACT_APP_GOOGLE_MAPS_API_KEY,
  });

  const handleCheckLocation = (e) => {
    e.preventDefault();
    //Get user's current location
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

    //Get geo fence location
    const geo = getGeoFence(checkInAddress);
    if (geo) {
      setGeoLocation(geo.coordinates);
      const distance = getDistance(location, geo.coordinates);
      console.log("distance", distance);
      if (distance <= geo.radius) {
        console.log("Check In Successful");
      } else {
        setError("You are not within the check in radius");
      }
    } else {
      setError("Invalid Check In Address");
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
          Enter the unique Check In address and Click on Check In below to see a
          list of available check in rewards for your current location!
        </p>
      </div>
      <form onSubmit={handleCheckLocation} className={styles.formContainer}>
        <div className={styles.inputContainer}>
          <input
            className={styles.input}
            type="text"
            placeholder="Enter Check In Address"
            value={checkInAddress}
            onChange={(e) => setCheckInAddress(e.target.value)}
            style={{
              width:
                "100%" /* Make the input take the full width of its container */,
              height: "50px" /* Increase the height */,
              padding: "10px" /* Add padding for better spacing */,
              fontSize: "16px" /* Increase the font size */,
              boxSizing:
                "border-box" /* Ensure padding and border are included in the width and height */,
            }}
            required
          />
        </div>
        <div className={styles.buttonContainer}>
          <button className={styles.checkInButton} type="submit">
            CHECK IN
          </button>
        </div>
      </form>
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
                  <Marker position={location} icon={customIcon1} />
                </>
              )}
              {geoLocation && (
                <>
                  <Marker position={geoLocation} icon={customIcon2} />
                  <Circle
                    center={{
                      lat: geoLocation.latitude,
                      lng: geoLocation.longitude,
                    }}
                    radius={radius} // Radius in meters
                    options={{
                      fillColor: "rgba(0, 0, 255, 0.2)",
                      strokeColor: "rgba(0, 0, 255, 0.5)",
                      strokeWeight: 2,
                    }}
                  />
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
