class mysql::params {

	$server_packages = $operatingsystem ? {
		debian => ["mysql-server-5.1"]
	}

	$server_services = $operatingsystem ? {
		debian => "mysql"
	}

}
