# docker-wordpress-nginx

A Dockerfile that installs instances of wordpress based on latest wordpress, nginx, php-apc and php-fpm. Multilanguage wordpress is supported through docker environment variables for Wordpress <4.0 and provided by default by wordpress for version >=4.0

NB: A big thanks to [jbfink](https://github.com/jbfink/docker-wordpress) who did most of the hard work on the wordpress parts, and also [eugeneware](https://github.com/eugeneware) who did a nice wordpress integration.

## Installation

```
$ git clone https://github.com/HouseOfAgile/docker-multi-wordpress.git
$ cd docker-multi-wordpress
$ sudo docker build -t="docker-multi-wordpress" .

```
By default, english language will be picked, but since wordpress 4 release (sept 2014), it is now possible to choose language for any wordpress instance while installing it.


