class mysql::params {

	$server_packages = $operatingsystem ? {
		debian => ["mysql-server"]
	}

	$server_services = $operatingsystem ? {
		debian => "mysql"
	}

}
