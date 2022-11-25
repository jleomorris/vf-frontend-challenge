import React from 'react';
import AppConfig from '../../Configs';
import { ApplicationLayoutType } from './Types.d';

const ApplicationLayout = ({ children }: ApplicationLayoutType) => {
  const {
    global: { applicationName },
  } = AppConfig;

  return (
    <div>
      <h1>{applicationName}</h1>
      <div className="app-content">{children}</div>
    </div>
  );
};

export default ApplicationLayout;
