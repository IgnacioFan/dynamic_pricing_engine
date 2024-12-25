APP_CNAME=api

bash:
	docker exec -it $(APP_CNAME) bash

console:
	docker exec -it $(APP_CNAME) rails console

test:
	docker exec -e "RAILS_ENV=test" $(APP_CNAME) bundle exec rspec $(path)
