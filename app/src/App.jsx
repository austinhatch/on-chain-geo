// App.jsx
import React, { useState } from "react";
import { Router, Route } from "wouter";
import styles from "./app.module.scss";
import CreateGeos from "./pages/createGeos/createGeos";
import MyGeos from "./pages/myGeos/myGeos";
import Header from "./components/header/header";

const App = () => {
  return (
    <Router>
      <div className={styles.header}>
        <Header />
      </div>
      <div className={styles.appContainer}>
        <Route path="/" component={CreateGeos} />
        <Route path="/my-geos" component={MyGeos} />
      </div>
    </Router>
  );
};

export default App;