import React from 'react';
import ReactDOM from 'react-dom';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import ApplicationLayout from './Layout';
import HomePage from './Pages/HomePage';

const appRouting = (
  <Router>
    <ApplicationLayout>
      <Routes>
        <Route path="/" element={<HomePage />} />
      </Routes>
    </ApplicationLayout>
  </Router>
);

ReactDOM.render(appRouting, document.getElementById('root'));
