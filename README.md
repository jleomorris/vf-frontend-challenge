## Getting Started:

- Clone the repository
- cd into the directory and run `yarn install`
- To start the application in development mode, from the command line run `yarn run dev`
- To build the application in production mode, run `yarn run prod`

### Commands:

- Start dev env: `yarn run dev`
- Start prod env: ` yarn run prod`
- Linting: `yarn run lint`
- Unit tests: `yarn run test`
- Prettier: `yarn run pretty-quick`

### Linting Rules:

To set a strong base for any rules we want to enforce I have setup with to use the [Airbnb config](https://airbnb.io/javascript/) this config is widely used by a huge list of companies and for many is a standard.

### Hooks:

The following are set up as pre commit hooks:

- Linting
- Prettier
- Running the unit tests
