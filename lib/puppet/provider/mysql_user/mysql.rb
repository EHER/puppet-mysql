# mysql/lib/puppet/provider/mysql_user/mysql.rb
#
# Implement MySQL user operations for MySQL.
#

require 'puppet/provider/package'

Puppet::Type.type(:mysql_user).provide(:mysql, :parent => Puppet::Provider::Package) do

  desc "Use mysql as database."
  commands :mysql => '/usr/bin/mysql'
  commands :mysqladmin => '/usr/bin/mysqladmin'

  # retrieve the current set of mysql users
  def self.instances
    users = []

    cmd = "#{command(:mysql)} --defaults-file=/etc/mysql/debian.cnf mysql -NBe 'select concat(user, \"@\", host), password from user'"
    execpipe(cmd) do |process|
      process.each do |line|
        users << new( query_line_to_hash(line) )
      end
    end
    return users
  end

  def self.query_line_to_hash(line)
    fields = line.chomp.split(/\t/)
    {
      :name => fields[0],
      :password_hash => fields[1],
      :ensure => :present
    }
  end

  def mysql_flush
    mysqladmin "--defaults-file=/etc/mysql/debian.cnf", "flush-privileges"
  end

  def query
    result = {}

    cmd = "#{command(:mysql)} --defaults-file=/etc/mysql/debian.cnf mysql -NBe 'select concat(user, \"@\", host), password from user where concat(user, \"@\", host) = \"%s\"'" % @resource[:name]
    execpipe(cmd) do |process|
      process.each do |line|
        unless result.empty?
          raise Puppet::Error,
          "Got multiple results for user '%s'" % @resource[:name]
        end
        result = query_line_to_hash(line)
      end
    end
    result
  end

  def create
    mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "create user '%s' identified by PASSWORD '%s'" % [ @resource[:name].sub("@", "'@'"), @resource.should(:password_hash) ]
    mysql_flush
  end

  def destroy
    mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "drop user '%s'" % @resource[:name].sub("@", "'@'")
    mysql_flush
  end

  def exists?
    not mysql("--defaults-file=/etc/mysql/debian.cnf", "mysql", "-NBe", "select '1' from user where CONCAT(user, '@', host) = '%s'" % @resource[:name]).empty?
  end

  def password_hash
    @property_hash[:password_hash]
  end

  def password_hash=(string)
    mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "SET PASSWORD FOR '%s' = '%s'" % [ @resource[:name].sub("@", "'@'"), string ]
    mysql_flush
  end
end

