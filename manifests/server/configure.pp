class mysql::server::configure (
	$root_defaults_path = $mysql::params::root_defaults_path,
	$root_host = $mysql::params::root_defaults_host,
	$root_user = $mysql::params::root_defaults_user,
	$root_password = $mysql::params::root_defaults_password,
	$root_socket = $mysql::params::root_defaults_socket
) inherits mysql::params {

	$username = $root_user
	$hostname = $root_host
	$socket_path = $root_socket

	file { 'generaterootcnf.sh' :
		path => $mysql::params::generate_root_cnf,
		ensure => file,
		owner => root,
		group => root,
		mode => 0755,
		source => 'puppet:///modules/mysql/generaterootcnf.sh',
	}

	exec { 'mysql-generateroot' :
		command => $mysql::params::generate_root_cnf,
		unless => "test -s $mysql::params::root_defaults_path",
		path => ['/usr/bin', '/bin'],
	}

	Class['mysql::server::install'] -> Class['mysql::server::configure']
}

