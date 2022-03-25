# Avalon Media System

[Avalon Media System](http://www.avalonmediasystem.org) is an open source system for managing large collections of digital audio and video. The project is led by the libraries of [Indiana University](http://www.iu.edu) and [Northwestern University](http://www.northwestern.edu) with funding in part by a three-year National Leadership Grant from the [Institute of Museum and Library Services](http://www.imls.gov).

For more information and regular project updates visit the [Avalon blog](http://www.avalonmediasystem.org/blog).

# Installing Avalon Media System
Installation instructions are available on Avalon's documentation site:
 - https://wiki.dlib.indiana.edu/display/VarVideo/Manual+Installation+Instructions

# Development

## Quickstart development with Docker
Using Docker is the recommended method of setting up an Avalon Media System Development Environment. It can be completed in minutes without installing any dependencies beside Docker itself. It should be noted that the docker-compose.yml provided here is for development only and will be updated continually.
* Install [Docker](https://docs.docker.com/engine/installation/) and [docker-compose](https://docs.docker.com/compose/install/)
* ```git clone https://github.com/uhlibraries-digital/avalon.git```
* ```cd avalon```
* ```cp config/controlled_vocabulary.yml.example config/controlled_vocabulary.yml```
* ```docker-compose pull```
* `docker-compose run --rm app yarn install`
* `docker-compose run --rm app rake db:migrate`
* ```docker-compose up avalon worker```
* Try loading Avalon in your browser: ```localhost:3000```

To run tests, first bring up the test stack then run Rspec as usual:
* ```docker-compose up test```
* ```docker-compose exec test bash -c "bundle exec rspec"```

To run Cypress E2E tests, first bring up the development stack, manually create testing users, and then bring up the cypress container:
* ```docker-compose up avalon```
* Create the two testing users and one testing media object:
  * ```docker-compose exec avalon bash -c "bundle exec rake avalon:user:create avalon_username=administrator@example.com avalon_password=password avalon_groups=administrator"```
  * ```docker-compose exec avalon bash -c "bundle exec rake avalon:user:create avalon_username=user@example.com avalon_password=password"```
  * ```docker-compose exec avalon bash -c "bundle exec rake avalon:test:media_object id=123456789 collection=123456789"```
* ```docker-compose up cypress```

## Javascript style checking and code formatting
### ESLint - Style checking
In order to run eslint on javascript files to check prior to creating a pull request do the following:
1. Install eslint globally, locally on dev machine: `npm install -g eslint`
2. Run `eslint app/assets/javascripts/ --ext .js,.es6`

### Prettier - Code formatting
To maintain a consistent style of .js/.es6 code, the Prettier package should be used to clean up code before submitting a pull request.
1. Install Prettier globally, locally on dev machine: (https://prettier.io/) `yarn global add prettier` or `npm install --global prettier`
2. (optional) To be safe, you may want to commit your code before running through Prettier.
3. Run the `prettier` CLI command from the application root directory, for example: `prettier --write "app/assets/javascripts/media_player_wrapper/*.es6"`
3. Commit your re-formatted, beautiful code.

## Browser Testing
Testing support for Avalon Media System is provided by [BrowserStack](https://www.browserstack.com).
