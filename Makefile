build:
	docker-compose build

console:
	docker-compose run --rm app bundle exec rails console

up:
	rm -rf tmp/pids/*
	touch tmp/caching-dev.txt
	docker-compose up

up-mail:
	rm -rf tmp/pids/*
	touch tmp/caching-dev.txt
	docker-compose --profile dev up

stop:
	docker-compose stop

down:
	docker-compose down

install:
	docker-compose run --rm app bundle install
	# docker-compose run --rm app yarn install

lint:
	docker-compose run --rm app bundle exec rubocop
	# docker-compose run --rm app yarn lint
	# docker-compose run --rm app yarn stylelint
	docker-compose run --rm app bundle exec slim-lint app/views/

rspec:
	docker-compose run --rm app bundle exec rspec

test-rails:
	docker-compose run --rm app bundle exec rails test

fix:
	docker-compose run --rm app bundle exec rubocop -a
	# docker-compose run --rm app yarn lint --fix
	# docker-compose run --rm app yarn stylelint --fix

migrate:
	docker-compose run --rm app bundle exec rails db:migrate

reset-db:
	docker-compose run --rm app bundle exec rails db:migrate:reset db:seed

setup:
	docker-compose run --rm app bundle exec rails db:drop db:create db:migrate db:seed

bash:
	docker-compose exec app /bin/bash

test: lint rspec
