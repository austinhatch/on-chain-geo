import React, { useState, useEffect, useCallback, useRef } from "react";
import {
  GoogleMap,
  useJsApiLoader,
  Marker,
  Autocomplete,
  Circle,
} from "@react-google-maps/api";

const containerStyle = {
  width: "100%",
  height: "400px",
};

const defaultCenter = {
  lat: 51.505,
  lng: -0.09,
};

const MapPicker = ({ onCoordinateSelect, radius }) => {
  const [selectedPosition, setSelectedPosition] = useState(null);
  const [center, setCenter] = useState(defaultCenter);
  const autocompleteRef = useRef(null);

  const { isLoaded } = useJsApiLoader({
    googleMapsApiKey: process.env.REACT_APP_GOOGLE_MAPS_API_KEY, // Replace with your API key
    libraries: ["places"], // Add the places library
  });

  useEffect(() => {
    const fetchLocation = async () => {
      try {
        const response = await fetch("https://ipapi.co/json/");
        const data = await response.json();
        console.log(data);
        setCenter({ lat: data.latitude, lng: data.longitude });
      } catch (error) {
        console.error("Error fetching location:", error);
      }
    };

    fetchLocation();
  }, []);

  const handleMapClick = useCallback(
    (event) => {
      const lat = event.latLng.lat();
      const lng = event.latLng.lng();
      setSelectedPosition({ lat, lng });
      if (onCoordinateSelect) {
        onCoordinateSelect({ lat, lng });
      }
    },
    [onCoordinateSelect]
  );

  const handlePlaceChanged = () => {
    const place = autocompleteRef.current.getPlace();
    if (place.geometry) {
      const lat = place.geometry.location.lat();
      const lng = place.geometry.location.lng();
      setCenter({ lat, lng });
      setSelectedPosition({ lat, lng });
      if (onCoordinateSelect) {
        onCoordinateSelect({ lat, lng });
      }
    }
  };

  if (!isLoaded) {
    return <div>Loading...</div>;
  }

  // Convert radius from miles to meters
  const radiusInMeters = radius * 1609.34;

  return (
    <div>
      <Autocomplete
        onLoad={(autocomplete) => (autocompleteRef.current = autocomplete)}
        onPlaceChanged={handlePlaceChanged}
      >
        <input
          type="text"
          placeholder="Search for a place"
          style={{
            boxSizing: `border-box`,
            border: `1px solid transparent`,
            width: `240px`,
            height: `32px`,
            padding: `0 12px`,
            borderRadius: `3px`,
            boxShadow: `0 2px 6px rgba(0, 0, 0, 0.3)`,
            fontSize: `14px`,
            outline: `none`,
            textOverflow: `ellipses`,
            position: "absolute",
            left: "50%",
            marginLeft: "-120px",
            top: "10px",
          }}
        />
      </Autocomplete>
      <GoogleMap
        mapContainerStyle={containerStyle}
        center={center}
        zoom={10}
        onClick={handleMapClick}
      >
        {selectedPosition && (
          <>
            <Marker position={selectedPosition} />
            <Circle
              center={selectedPosition}
              radius={radiusInMeters}
              options={{
                fillColor: "rgba(173, 216, 230, 0.5)",
                strokeColor: "rgba(0, 0, 255, 0.5)",
                strokeWeight: 1,
              }}
            />
          </>
        )}
      </GoogleMap>
    </div>
  );
};

export default MapPicker;
