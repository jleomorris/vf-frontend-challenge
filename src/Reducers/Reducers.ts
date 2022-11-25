import ActionTypesEnum from '../Enums';
import { StateInterface } from '../Interfaces';
import { ActionTypes } from '../Types';

const Reducer = (state: StateInterface, action: ActionTypes) => {
  switch (action.type) {
    case ActionTypesEnum.FETCH_USERS:
      return {
        ...state,
        users: action.payload,
      };
    default:
      return state;
  }
};

export default Reducer;
