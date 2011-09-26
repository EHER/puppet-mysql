
class mysql::server {
	include mysql::server::install
	include mysql::server::configure
	include mysql::server::service
}

