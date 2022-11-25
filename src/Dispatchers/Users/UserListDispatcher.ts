import axios from 'axios';
import AppConfig from '../../Configs'
import ActionTypesEnum from '../../Enums';

const FetchUsers = (dispatch: any) => {
  console.log(dispatch)
	const { global: { apiUrl } } = AppConfig

	axios.get(`${apiUrl}/users`)
	.then((res) => dispatch({ 
    type: ActionTypesEnum.FETCH_USERS, 
    payload: res.data 
  }))
	// eslint-disable-next-line no-console
	.catch((error) => console.error('An error occurred: ', error));
}

export default FetchUsers
