# Git Runner - Deploy

[![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/JamesBrooks/git-runner-deploy)


Capistrano deploy functionality for [Git Runner](https://github.com/JamesBrooks/git-runner)

Added deployment functionality (using capistrano) to be integrated into Git Runner

## Installation

    $ gem install git-runner-deploy

## Usage
At the top of your deploy file (e.g. config/deploy.rb):

##### To deploy all branches
````
# GitRunner: Deploy
````

##### To only deploy specific branches
````
# GitRunner: Deploy master staging
````

## Multistage
Capistrano multistage configurations are automatically detected. In the case of multistage the branch name is used to determine which stage should be deployed. In the case of the master branch the stage name `production` is used. For every other branch that branches name is used as the deploy stage, e.g:

* `master` -> `cap production deploy`
* `staging` -> `cap staging deploy`

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
