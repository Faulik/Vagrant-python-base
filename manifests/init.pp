Exec { path => "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"}

# Global variables
$user = "vagrant"
$password = "1234"
$project = "project"

class apt {
  exec { "apt-get update" :
    timeout => 0
  }
}

class user {
  exec { "add user":
    command => "sudo useradd -m -G sudo -s /bin/bash ${user}",
    unless => "id -u ${user}"
  }
}
class python {
  package { "curl":
    ensure => latest,
    require => Class["apt"]
  }

  package { "python":
    ensure => latest,
    require => Class["apt"]
  }
  package { "python-dev":
    ensure => latest,
    require => Class["apt"]
  }
}

class software {
  package { "git":
    ensure => latest,
    requre => Class["apt"]
  }
}

include apt
include user
include python
include software