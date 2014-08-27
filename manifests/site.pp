#
define download_gemfile(
  $url = '', $cwd = '',
  $creates = '', $require = '',
  # $user = ''
  ) {
  exec { $name:
    command => "/usr/bin/wget ${url}/${name}.gem",
    cwd     => $cwd,
    creates => "${cwd}/${name}.gem",
    require => $require,
    timeout   => 0,
    #user => $user,
  }
}

define run_bundler_for_gemset(
  $user = 'ubuntu',
  $cwd = '/opt/resque/rhohublib',
  ) {
  exec { $name:
    user      => $user,
    cwd       => $cwd,
    logoutput => on_failure,
    command   => "bash -c 'source /usr/local/rvm/scripts/rvm && rvm gemset use ${name} && bundle install'",
    path      => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
  }
}

class requirements {
  group { "puppet": ensure => "present", }
  # exec { "apt-update":
  #   command => "/usr/bin/apt-get -y update"
  # }

  package {
    ['zip', 'unzip', 'lib32stdc++6', 'lib32z1', 'openjdk-7-jdk']:
      ensure => installed,
      # ensure => installed, require => Exec['apt-update']
  }

  file { ["/opt/resque", "/opt/resque/sdk",
    "/opt/resque/sdk/3.5.1.14",
    "/opt/resque/sdk/4.0.9",
    "/opt/resque/sdk/4.1.6",
    "/opt/resque/sdk/5.0.2"]:
    ensure => "directory",
    #owner  => "ubuntu",
    #group  => "wheel",
    #mode   => 750,
  }

  download_gemfile {
    [ 'rhodes-3.5.1.14', 'rhoelements-2.2.1.13.11' ]:
    url     => 'https://s3.amazonaws.com/rhohub-gemsets/3.5.1.14',
    cwd     => '/opt/resque/sdk/3.5.1.14',
    require => File['/opt/resque/sdk/3.5.1.14'],
  }
  download_gemfile {
    [ 'rhodes-4.0.9', 'rhoelements-4.0.9', 'rhoconnect-client-4.0.9' ]:
    url     => 'https://s3.amazonaws.com/rhohub-gemsets/4.0.9',
    cwd     => '/opt/resque/sdk/4.0.9',
    require => File['/opt/resque/sdk/4.0.9'],
  }
  download_gemfile {
    [ 'rhodes-4.1.6', 'rhoelements-4.1.6', 'rhoconnect-client-4.1.6' ]:
    url     => 'https://s3.amazonaws.com/rhohub-gemsets/4.1.6',
    cwd     => '/opt/resque/sdk/4.1.6',
    require => File['/opt/resque/sdk/4.1.6'],
  }
  download_gemfile {
    [ 'rhodes-5.0.2', 'rhoelements-5.0.2', 'rhoconnect-client-5.0.2', 'rhodes-containers-5.0.2' ]:
      url     => 'https://s3.amazonaws.com/rhohub-gemsets/5.0.2',
      cwd     => '/opt/resque/sdk/5.0.2',
      require => File['/opt/resque/sdk/5.0.2'],
  }
}

class android_install {
  exec { 'android-sdk-linux':
    user    => 'ubuntu',
    cwd     => '/tmp',
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
    creates => ["/usr/local/android-sdk-linux"],
    command => "wget http://dl.google.com/android/android-sdk_r23-linux.tgz -o /dev/null && \
tar xzf android-sdk_r23-linux.tgz && sudo mv android-sdk-linux /usr/local && \
wget http://dl.google.com/android/ndk/android-ndk-r9d-linux-x86.tar.bz2 -o /dev/null && \
tar xjf android-ndk-r9d-linux-x86.tar.bz2 && sudo mv android-ndk-r9d /usr/local && \
rm *.tar.bz2 && rm *.tgz",
    logoutput => on_failure,
  }

  exec { 'update-android':
    user    => 'root',
    cwd     => '/home/ubuntu',
    path    => ["/bin", "/usr/bin", "/usr/sbin"],
    require => Exec['android-sdk-linux'],
    creates => ["/root/.android"],
    command => "bash -c '( sleep 5 && while [ 1 ]; do sleep 1; echo y; done ) | \
/usr/local/android-sdk-linux/tools/android update sdk -u --filter 1,2,3,android-19,android-17,android-15,android-13,android-12,android-11,android-10,android-4,extra-android-support'",
    logoutput => true,
  }

  file { '/usr/local/android-sdk-linux/tools/zipalign':
    ensure  => link,
    replace => 'no', # do not create link if the file already exists
    target  => '/usr/local/android-sdk-linux/build-tools/20.0.0/zipalign',
    require => Exec['update-android'],
  }
  file { '/home/ubuntu/.android':
    ensure  => directory, # so make this a directory
    recurse => true, # enable recursive directory management
    purge   => true, # purge all unmanaged junk
    force   => true, # also purge subdirs and links etc.
    owner   => "ubuntu",
    group   => "ubuntu",
    mode    => 0644,
    source  => '/root/.android',
    require => Exec['update-android'],
  }
}

$system_ruby = 'ruby-1.9.3-p547'

class rvm_install {
  include rvm
  rvm::system_user { ubuntu: ; }

  rvm_system_ruby { "${system_ruby}":
    ensure      => 'present',
    default_use => true;
  }

  file { '/etc/gemrc':
    # content => "gem: --no-ri --no-rdoc",
    content => "gem: -​-no-document", # -N
    owner   => "root",
    #group   => "rvm",
    require => Rvm_system_ruby["${system_ruby}"],
  }
}

class rhodes_setup {
  file {[
    "/usr/local/rvm/gems/${system_ruby}@3.5.1.14/gems/rhodes-3.5.1.14/rhobuild.yml",
    "/usr/local/rvm/gems/${system_ruby}@4.0.9/gems/rhodes-4.0.9/rhobuild.yml",
    "/usr/local/rvm/gems/${system_ruby}@4.1.6/gems/rhodes-4.1.6/rhobuild.yml",
    "/usr/local/rvm/gems/${system_ruby}@5.0.2/gems/rhodes-5.0.2/rhobuild.yml",
    '/opt/resque/rhobuild.yml',
  ]:
    content => template('conf/rhobuild.yml.erb'),
  }
  # Iterate over gemsets and run bundler foreach itme
  run_bundler_for_gemset { ['default', '3.5.1.14', '4.0.9', '4.1.6', '5.0.2']: }
}

class resque_service {
  file { '/etc/init.d/resque':
    content => template('conf/resque.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    notify  => Service['resque'],
  }
  service { 'resque':
    ensure  => running,
    enable  => true,
    require => File['/etc/init.d/resque'],
  }
}

notify { 'Starting resque service.': }

# Main
node 'rho-builder' {
  $jdk_path         = '/usr/lib/jvm/java-7-openjdk-amd64'
  $android_sdk_path = '/usr/local/android-sdk-linux'
  $android_ndk_path = '/usr/local/android-ndk-r9d'
  $redis_url = regsubst(file('/tmp/redis_url.txt'), '\n', '')
  # TODO:
  # $redis_url = file('puppet:///modules/conf/redis_url.txt')
  # notify {$redis_url:}

  class { 'requirements': } -> class { 'rvm_install':  }

  rvm_gemset {
    "${system_ruby}@3.5.1.14":
    ensure  => present,
    require => Rvm_system_ruby["${system_ruby}"];

    "${system_ruby}@4.0.9":
    ensure => present,
    require => Rvm_system_ruby["${system_ruby}"];

    "${system_ruby}@4.1.6":
    ensure => present,
    require => Rvm_system_ruby["${system_ruby}"];

    "${system_ruby}@5.0.2":
    ensure => present,
    require => Rvm_system_ruby["${system_ruby}"];
  }

  rvm_gem {
    # 3.5.1.14
    "${system_ruby}@3.5.1.14/rhodes":
    source => '/opt/resque/sdk/3.5.1.14/rhodes-3.5.1.14.gem',
    require => Rvm_gemset["${system_ruby}@3.5.1.14"];
    "${system_ruby}@3.5.1.14/rhoelements":
    source => '/opt/resque/sdk/3.5.1.14/rhoelements-2.2.1.13.11.gem',
    require => Rvm_gemset["${system_ruby}@3.5.1.14"];

    # 4.0.9
    "${system_ruby}@4.0.9/rhodes":
    source => '/opt/resque/sdk/4.0.9/rhodes-4.0.9.gem',
    require => Rvm_gemset["${system_ruby}@4.0.9"];
    "${system_ruby}@4.0.9/rhoelements":
    source => '/opt/resque/sdk/4.0.9/rhoelements-4.0.9.gem',
    require => Rvm_gemset["${system_ruby}@4.0.9"];
    "${system_ruby}@4.0.9/rhoconnect-client":
    source => '/opt/resque/sdk/4.0.9/rhoconnect-client-4.0.9.gem',
    require => Rvm_gemset["${system_ruby}@4.0.9"];

    # 4.1.6
    "${system_ruby}@4.1.6/rhodes":
    source => '/opt/resque/sdk/4.1.6/rhodes-4.1.6.gem',
    require => Rvm_gemset["${system_ruby}@4.1.6"];
    "${system_ruby}@4.1.6/rhoelements":
    source => '/opt/resque/sdk/4.1.6/rhoelements-4.1.6.gem',
    require => Rvm_gemset["${system_ruby}@4.1.6"];
    "${system_ruby}@4.1.6/rhoconnect-client":
    source => '/opt/resque/sdk/4.1.6/rhoconnect-client-4.1.6.gem',
    require => Rvm_gemset["${system_ruby}@4.1.6"];

    # 5.0.2
    "${system_ruby}@5.0.2/rhodes":
    source => '/opt/resque/sdk/5.0.2/rhodes-5.0.2.gem',
    require => Rvm_gemset["${system_ruby}@5.0.2"];
    "${system_ruby}@5.0.2/rhoelements":
    source => '/opt/resque/sdk/5.0.2/rhoelements-5.0.2.gem',
    require => Rvm_gemset["${system_ruby}@5.0.2"];
    "${system_ruby}@5.0.2/rhoconnect-client":
    source => '/opt/resque/sdk/5.0.2/rhoconnect-client-5.0.2.gem',
    require => Rvm_gemset["${system_ruby}@5.0.2"];
    "${system_ruby}@5.0.2/rhodes-containers":
    source => '/opt/resque/sdk/5.0.2/rhodes-containers-5.0.2.gem',
    require => Rvm_gemset["${system_ruby}@5.0.2"];
  } ->

  class { 'android_install': }       ->
  class  { 'rhodes_setup': }         ->
  Notify['Starting resque service.'] ->
  class {'resque_service': }

}

