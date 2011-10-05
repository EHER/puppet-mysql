Puppet::Type.type(:mysql_user).provide(:mysql) do

  desc "manage users for a mysql database."

  defaultfor :kernel => 'Linux'

  commands :mysql => 'mysql'
  commands :mysqladmin => 'mysqladmin'

  def create
    mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "CREATE USER '%s' identified by PASSWORD '%s'" % [ @resource[:name].sub("@", "'@'"), @resource.value(:password_hash) ]
    mysql_flush
  end
 
  def destroy
    mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "DROP USER '%s'" % @resource.value(:name).sub("@", "'@'")
    mysql_flush
  end
 
  def exists?
    not mysql("--defaults-file=/etc/mysql/debian.cnf", "mysql", "-NBe", "SELECT '1' FROM user WHERE CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).empty?
  end
 
  def password_hash
    mysql("--defaults-file=/etc/mysql/debian.cnf", "mysql", "-NBe", "SELECT password FROM user WHERE CONCAT(user, '@', host) = '%s'" % @resource.value(:name)).chomp
  end
 
  def password_hash=(string)
    mysql "--defaults-file=/etc/mysql/debian.cnf", "mysql", "-e", "SET PASSWORD FOR '%s' = '%s'" % [ @resource[:name].sub("@", "'@'"), string ]
    mysql_flush
  end

  private

  def mysql_flush
    mysqladmin "--defaults-file=/etc/mysql/debian.cnf", "flush-privileges"
  end
end
