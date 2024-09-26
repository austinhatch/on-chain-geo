// App.jsx
import React, { useState } from "react";
import styles from "./app.module.scss";
import CheckIn from "./pages/checkIn/checkIn";
import MyCheckIns from "./pages/myCheckins/myCheckIns";
import Header from "./components/header/header";

const App = () => {
  const [page, setPage] = useState("/");
  return (
    <>
      <div className={styles.header}>
        <Header setPage={setPage} />
      </div>
      <div className={styles.appContainer}>
        {page === "/my-checkins" ? <MyCheckIns /> : <CheckIn />}
      </div>
    </>
  );
};

export default App;
