#  ERPNext 12.x on Rancher 2.x

##### Goals

* Production build of ERPNext
* Hosted in 1 Workload in Rancher 2.x
* Seperate MariaDB
* Persistance to volume mounts
* Multi-tenanted
* Everything working: PDF, websocket updates, and email

##### Solution

bench new-site erp.yourdomain.com --mariadb-root-password "$DB_ROOT_PASS" --admin-password 123 --verbose --install-app erpnext

cd ~/erpnext-docker-debian && git pull && docker build -t erpnext . && docker tag erpnext registry.yourinfra.com:5000/erpnext/erpnext && docker push registry.yourinfra.com:5000/erpnext/erpnext

# fixed JS error
bench update --build




## Contributing

Pull requests for new features, bug fixes, documentation improvements (and typo fixes) and suggestions are welcome!

## License

MIT
