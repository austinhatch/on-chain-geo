import React, { useState } from "react";
import styles from "./header.module.scss";
import namelessLogo from "../../assets/nameless-logo-dark.png";

const routes = [
  {
    id: "Create",
    url: "/",
  },
  {
    id: "My Geos",
    url: "/my-geos",
  },
];

const Header = () => {
  return (
    <div className={styles.parentContainer}>
      <img src={namelessLogo} className={styles.logo} alt="Nameless Logo" />
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
};

export default Header;
