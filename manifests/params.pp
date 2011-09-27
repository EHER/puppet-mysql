class mysql::params {

	$server_packages = $operatingsystem ? {
		debian => ["mysql-server"]
	}

	$server_services = $operatingsystem ? {
		debian => "mysql"
	}

	$root_defaults_path = $operatingsystem ? {
		debian => "/etc/mysql/root.cnf",
	}

	$generate_root_cnf = "/usr/local/bin/generaterootcnf.sh"
	$root_default_host = "localhost"
	$root_default_user = "root"
	$root_default_password = undef
	$root_default_socket   = "/var/run/mysqld/mysqld.sock"

}
