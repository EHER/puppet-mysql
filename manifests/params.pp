class mysql::params {

	$server_packages = $operatingsystem ? {
		debian => ["mysql-server"],
		ubuntu => ["mysql-server"],
		freebsd => ["mysql51-server"],
	}

	$server_services = $operatingsystem ? {
		debian => "mysql",
		ubuntu => "mysql",
		freebsd => "mysql-server",
	}

	$root_defaults_path = $operatingsystem ? {
		debian => "/etc/mysql/root.cnf",
		ubuntu => "/etc/mysql/root.cnf",
		freebsd => "/usr/local/etc/mysql/root.cnf",
	}


	$generate_root_cnf = "/usr/local/bin/generaterootcnf.sh"
	$root_default_host = "localhost"
	$root_default_socket   = "/var/run/mysqld/mysqld.sock"
	$root_default_password = undef
	$root_default_user = "root"
	$root_default_group = $operatingsystem ? {
		debian => "root",
		ubuntu => "root",
		freebsd => "wheel",
	}

}
