Exec { path => "/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"}

# Global variables
$user = $::default_user
$password = "1234"
$project = $::project_name
$python_project_dir = "/home/${user}/${project}"
$node_project_dir = "/home/${user}/${project}"

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
  exec { "set password":
    command => "echo \'${user}:${password}\' | sudo chpasswd",
    require => Exec["add user"]
  }
  file { ["/home/${user}/venvs",
          "/home/${user}/${project}"]:
    ensure => directory,
    owner => "${user}",
    group => "${user}",
    require => Exec['add user']
  }
}

class python {
  package { "curl":
    ensure => latest,
    require => Class["apt"]
  }

  package { "python3":
    ensure => latest,
    require => Class["apt"]
  }
  package { "python3-dev":
    ensure => latest,
    require => Class["apt"]
  }
  package { "python3-pip":
    ensure => latest,
    require => Class["apt"]
  }
}

class virtualenv {
  exec { "pip3 install virtualenv":
    command => "pip3 install virtualenv",
    require => Class["python"]
  }
  exec { 'create virtualenv':
    command  => 'virtualenv -p /usr/bin/python3.4 env',
    cwd => "/home/${user}/venvs",
    user => $user,
    creates => "/home/${user}/venvs/env",
    require => Exec["pip3 install virtualenv"]
  }
  exec { "pip3 install deps":
    command  => "pip3 install -r requirements.txt",
    onlyif => "/usr/bin/test -f /home/${user}/${project}/requirements.txt",
    cwd => "/home/${user}/${project}",
    user => $user,
    path => "/home/${user}/venvs/env/bin",
    require => Exec["create virtualenv"]
  }
}

class django {
  exec { "django migrate":
    command  => "python manage.py migrate",
    cwd => "/home/${user}/${project}",
    user => $user,
    path => "/home/${user}/venvs/env/bin",
    require => Class["virtualenv"]
  }
}
class nodejs{
  package { "nodejs":
    ensure => latest,
    require => Class["apt"]
  }
  package { 'nodejs-legacy':
    ensure => latest,
    require => Class["apt"]
  }
  package { "npm":
    ensure => latest,
    require => Class["apt"]
  }
}

class bower {
  exec { "bower":
    command => "npm install -g bower",
    require => Class["nodejs"]
  }
  exec { "npm install deps":
    command  => "npm install",
    onlyif => "/usr/bin/test -f /home/${user}/${project}/package.json",
    cwd => "/home/${user}/${project}",
    user => $user,
    require => Exec["bower"]
  }
  exec { 'npm postinstall':
    command => "/home/${user}/${project}/scripts/postInstall.sh | sh",
    onlyif => "/usr/bin/test -f /home/${user}/${project}/scripts/postInstall.sh",
    cwd => "/home/${user}/${project}",
    user => $user,
    require => Exec["npm install deps"]
  }
  exec { "bower install deps":
    command => "bower install",
    onlyif => "/usr/bin/test -f /home/${user}/${project}/bower.json",
    cwd => "/home/${user}/${project}",
    user => $user,
    require => Exec["npm postinstall"]
  }
}

class software {
  package { "git":
    ensure => latest,
    require => Class["apt"]
  }
}

include user
include apt
include python
include virtualenv
include django
include nodejs
include bower
include software
