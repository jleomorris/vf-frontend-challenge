import React from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter as Router, Route, Routes } from 'react-router-dom';
import ApplicationLayout from './Layout';
import { StoreProvider } from './Providers';
import HomePage from './Pages/HomePage';

const container = document.getElementById('root');
const root = createRoot(container);

const application = (
  <Router>
    <StoreProvider>
      <ApplicationLayout>
        <Routes>
          <Route path="/" element={<HomePage />} />
        </Routes>
      </ApplicationLayout>
    </StoreProvider>
  </Router>
);

root.render(application);
