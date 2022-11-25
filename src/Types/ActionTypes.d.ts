import ActionTypesEnum from '../Enums';
import { UsersType } from '.';

export type ActionTypes =
  | { type: ActionTypesEnum.FETCH_USERS; payload: UsersType }
