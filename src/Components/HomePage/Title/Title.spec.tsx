import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom/extend-expect';
import Title from './Title';

describe('Title component', () => {
  it('should render the a h1 with the correct text', () => {
    render(<Title title="this is a test" />);
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent(
      'this is a test'
    );
  });
});
