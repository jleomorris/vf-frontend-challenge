import React, { useEffect } from 'react';
import { useStateContext } from '../../Providers';
import FetchUsers from '../../Dispatchers';

const HomePage = () => {
  const { dispatch, state } = useStateContext();
  const { users } = state;

  useEffect(() => {
    if (users === null) FetchUsers(dispatch);
  }, [users]);

  return (
    <div>
      <h3>Thank you for taking the time to check out the Visfo code challenge.</h3>
      <sub>To modify this page go to src/Pages/HomePage in your editor.</sub>
    </div>
  )
};

export default HomePage;
