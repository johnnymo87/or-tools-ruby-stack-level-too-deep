# or-tools-ruby-stack-level-too-deep
This app demos a problem I'm currently having when running code using [the `or-tools` gem](https://github.com/ankane/or-tools-ruby) in a web server on my local machine (a MacBook Air with an M1). The problem I'm having is that it errors out with `stack level too deep` when it runs the `solver.solve` gem code. The stack trace only contains information about what code called this code, not anything about what happens inside `solver.solve`.

```console
$ ruby run_in_web_server.rb

... server starts ...
... I visit localhost:4567 ...

2022-02-07 12:26:26 - SystemStackError - stack level too deep:
        /Users/jonathan.mohrbacher/Code/stack-overflow/lib/demo/solver.rb:142:in `solve'
        /Users/jonathan.mohrbacher/Code/stack-overflow/lib/demo/solver.rb:142:in `run_solver'
        /Users/jonathan.mohrbacher/Code/stack-overflow/lib/demo/solver.rb:43:in `solve'
        /Users/jonathan.mohrbacher/Code/stack-overflow/lib/demo/solver.rb:23:in `solve'
        /Users/jonathan.mohrbacher/Code/stack-overflow/lib/demo.rb:18:in `run'
        run_in_web_server.rb:10:in `block in <main>'
        ... sinatra-specific stack trace ...
```

However, when I run this code in the terminal, I don't have this problem. And when I run this code in docker, I don't have this problem. So my hunch is that on Macs with M1 chips, there's something wrong with either the `or-tools` gem or the underlying `or-tools` binary.

## Install it locally on a Mac
To install this app locally on a mac, you first need [Homebrew](https://brew.sh/) and [`rbenv`](https://github.com/rbenv/rbenv) setup on your machine.

* Install ruby 3.1.0 (you may already have it installed).
  ```console
  rbenv install -s $(cat .ruby-version)
  gem update --system
  gem install bundler
  rbenv rehash
  ```
* Install `or-tools`.
  ```console
  brew install or-tools
  ```
* Tell `bundle` where to find your installation of `or-tools`.
  ```console
  bundle config build.or-tools --with-or-tools-dir=/opt/homebrew
  ```
* Install the gems.
  ```console
  bundle
  ```

## Run it locally on a Mac
* Run the app one time in the terminal and exit.
  ```console
  ruby run_in_terminal.rb
  ```
* Run the web server.
  ```console
  ruby run_in_web_server.rb
  ```
  * View it at http://localhost:4567
  * On my machine, this is where I hit the `stack level too deep` error!

## Install it with docker
* Build the image.
  ```console
  docker-compose build
  ```

## Run it with docker
* Run the app one time in the terminal and exit.
  ```console
  docker-compose run --rm app ruby run_in_terminal.rb
  ```
* Run the web server.
  ```console
  docker-compose run --rm --service-ports app ruby run_in_web_server.rb
  ```
  * View it at http://localhost:4567
* Drop into the container.
  ```console
  docker-compose run --rm --service-ports app bash
  ```

## Debug
* Documentation for `debug.gem` is [here](https://github.com/ruby/debug).
* Set a breakpoint with `require 'debug'; binding.break`.
* Show where you are with `list` and `list -`.
* Continue with `continue`.
* Quit and kill the program with `kill!`.
* More control flow options are documented [here](https://github.com/ruby/debug#control-flow).
