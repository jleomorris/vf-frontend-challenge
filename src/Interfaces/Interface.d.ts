import React, { Dispatch } from 'react';
import { AppConfigType } from '../Configs/AppConfig/AppConfigType.d';
import { UserType } from '../Types';

export interface StateInterface {
  appConfig: AppConfigType;
  users: UserType[] | null;
}

export interface StoreInterface {
  // eslint-disable-next-line no-undef
  dispatch: Dispatch<Action>;
  state: StateInterface;
}

export interface ProviderInterface {
  children: React.ReactNode;
}
