# mysql/lib/puppet/type/mysql_user.rb
#
# Manage MySQL user accounts as Puppet resources.
#

Puppet::Type.newtype(:mysql_user) do
  @doc = "Manage a MySQL database user."
  ensurable

  # Name of the user.
  newparam(:name) do
    desc "The name of the MySQL database user in 'username@hostname' form."

    validate do |value|
      # Check that it's in the correct format
      unless value =~ /^(\w+@\w+)|%$/
        raise ArgumentError, "%s is not valid. Please specify 'username@hostname'." % value
      end

      # Check that the user portion isn't too long.
      user, host = value.split('@')
      if user.length > 16
        raise ArgumentError, "%s is too long. MySQL user names are limited to 16 characters." % value
      end
    end
  end


  # Server is mainly for collecting resources on the right server.
  newparam(:server) do
    desc "The MySQL server to create this user on."
    default = :fqdn
  end #newparam(:server)


  # Password for the new user.
  newproperty(:password_hash) do
    desc "The password hash of the user. Use mysql_password() for creating such a hash."

    validate do |value|
      unless value =~ /\*[0-9A-F]{40,40}/
        raise ArgumentError, "%s is not a MySQL password hash."
      end
    end
  end #newproperty(:password_hash)

end
