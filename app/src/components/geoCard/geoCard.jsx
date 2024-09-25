import React, { useEffect, useState } from "react";
import styles from "./geoCard.module.scss";
import GeoSelectorForm from "../geoSelectorForm/geoSelectorForm";
import MapPicker from "../mapPicker/mapPicker";

const GeoCard = ({ geo }) => {
    const [editMode, setEditMode] = useState(false);

    const [selectedCoordinates, setSelectedCoordinates] = useState(null);
    const [selectedRadius, setSelectedRadius] = useState(geo.radius || null);

    useEffect(() => {
        setSelectedCoordinates({
            lat: geo.lat,
            lng: geo.long,
        });
    }, [geo]);

    const handleCoordinateSelect = (coordinates) => {
        console.log(coordinates)
        setSelectedCoordinates(coordinates);
    };

    const handleRadiusSelect = (radius) => {
        setSelectedRadius(radius);
    };

    const handleEditClick = () => {
        setEditMode(!editMode);
    }

    return (
        <>
            {geo && (
                <div className={styles.parentContainer}>
                    <div className={styles.geoContainer}>
                        <h3>{geo.name}</h3>
                        {
                            geo.startDate && (
                                <p>{geo.startDate} - {geo.endDate}</p>
                            )
                        }
                        <p>Radius: {geo.radius}</p>
                        <p>Coordinates: ({geo.lat.toFixed(6)}, {geo.long.toFixed(6)})</p>
                    </div>
                    <div className={styles.checkinsContainer}>
                        <h4>Check-ins</h4>
                        <p>{geo.checkins}</p>
                    </div>
                    <div className={styles.buttonContainer}>
                        <button onClick={handleEditClick}>{!editMode ? 'Edit' : 'Cancel'}</button>
                        <button>Delete</button>
                    </div>
                    {
                        editMode && (
                            <div className={styles.editContainer}>
                                <div className={styles.mapContainer}>
                                    <div className={styles.mapPicker}>
                                        <MapPicker onCoordinateSelect={handleCoordinateSelect} coordinates={selectedCoordinates} radius={selectedRadius} />
                                    </div>
                                    <GeoSelectorForm
                                        coordinates={selectedCoordinates}
                                        prefillData={geo}
                                        setSelectedRadius={handleRadiusSelect}
                                        editMode={true}
                                    />
                                </div>
                            </div>
                        )
                    }
                </div>
            )}
        </>
    );

}

export default GeoCard;