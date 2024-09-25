import React, { useState } from "react";
import styles from "./header.module.scss";

const routes = [
    {
        id: "Create",
        url: "/",
    },
    {
        id: "My Geos",
        url: "/my-geos",
    }
]

const Header = () => {

    return (
        <div className={styles.parentContainer}>
            <h1>GeoFencing</h1>
            <div className={styles.routeContainer}>
                {routes.map((route) => (
                    <a key={route.id} href={route.url}>
                        {route.id}
                    </a>
                ))}
            </div>
        </div>
    );

}

export default Header;