class mysql::server::configure () inherits mysql::params {


	Class['mysql::server::install'] -> Class['mysql::server::configure']
}

