import React, { useState } from "react";
import styles from "./myCheckIns.module.scss";

const MyCheckIns = () => {
  return (
    <div className={styles.parentContainer}>
      <div className={styles.headerContainer}>
        <h1>My Check Ins</h1>
      </div>
    </div>
  );
};

export default MyCheckIns;
