# $operatingsystem  => Darwin

define download_gemfile(
  $url = '', $cwd = '',
  $creates = '', $require = '',
  # $user = ''
  ) {
  exec { $name:
    command => "wget ${url}/${name}.gem",
    cwd     => $cwd,
    creates => "${cwd}/${name}.gem",
    require => $require,
    path    => ['/usr/bin', '/usr/local/bin'],
    timeout   => 0,
    #user => $user,
  }
}

define create_gemset(
  $ruby = '',
  $user = 'rhomobile',
  ) {
  exec { $name:
    user      => $user,
    logoutput => on_failure,
    command   => "bash -c 'source /Users/${user}/.rvm/scripts/rvm && rvm use ${ruby} && rvm gemset create ${name}'",
    path      => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
  }

}

define install_gem (
  $ruby = '',
  $user = 'rhomobile',
  $gemset = '',
  ) {
  exec { "Install gem ${name}":
    user      => $user,
    logoutput => on_failure,
    cwd       => "/opt/resque/sdk/${gemset}",
    command   => "bash -c 'source /Users/${user}/.rvm/scripts/rvm && rvm use ${ruby} && rvm gemset use ${gemset} && gem install ${name}.gem -N'",
    path      => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
    creates   => "/Users/rhomobile/.rvm/gems/${ruby}@${gemset}/gems/${name}",
    timeout   => 0,
  }
}

define run_bundler_for_gemset(
  $user = 'rhomobile',
  $cwd = '/opt/resque/rhohublib',
  ) {
  exec { "Run bundler for gemset ${name}":
    user      => $user,
    cwd       => $cwd,
    logoutput => on_failure,
    command   => "bash -c 'source /Users/${user}/.rvm/scripts/rvm && rvm gemset use ${name} && gem install bundler && bundle install'",
    path      => '/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin',
  }
}

$system_ruby = 'ruby-1.9.3-p547'

class requirements {
  group { "puppet": ensure => "present", }

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
  # TODO:
  file { '/Users/rhomobile/.gemrc':
    content => "gem: --no-ri --no-rdoc\n",
    # content => "gem: -​-no-document\n", # -N
    owner   => "rhomobile",
    group   => "staff",
  }

}

class create_gemsets {
  create_gemset {
    [ '3.5.1.14', '4.0.9', '4.1.6', '5.0.2' ]:
      ruby => $system_ruby,
  }

}

class install_gems {
  install_gem {
    [ 'rhodes-3.5.1.14', 'rhoelements-2.2.1.13.11' ]:
      ruby   => $system_ruby,
      gemset => '3.5.1.14',
  }
  install_gem {
    [ 'rhodes-4.0.9', 'rhoelements-4.0.9', 'rhoconnect-client-4.0.9' ]:
      ruby => $system_ruby,
      gemset => '4.0.9',
  }
  install_gem {
    [ 'rhodes-4.1.6', 'rhoelements-4.1.6', 'rhoconnect-client-4.1.6' ]:
      ruby => $system_ruby,
      gemset => '4.1.6',
  }
  install_gem {
    [ 'rhodes-5.0.2', 'rhoelements-5.0.2', 'rhoconnect-client-5.0.2', 'rhodes-containers-5.0.2' ]:
      ruby => $system_ruby,
      gemset => '5.0.2',
  }
}

class rhodes_setup {
  file {[
    "/Users/rhomobile/.rvm/gems/${system_ruby}@3.5.1.14/gems/rhodes-3.5.1.14/rhobuild.yml",
    "/Users/rhomobile/.rvm/gems/${system_ruby}@4.0.9/gems/rhodes-4.0.9/rhobuild.yml",
    "/Users/rhomobile/.rvm/gems/${system_ruby}@4.1.6/gems/rhodes-4.1.6/rhobuild.yml",
    "/Users/rhomobile/.rvm/gems/${system_ruby}@5.0.2/gems/rhodes-5.0.2/rhobuild.yml",
    '/opt/resque/rhobuild.yml',
  ]:
    content => template('conf/rhobuild.yml.erb'),
  }

  # Iterate over gemsets and run bundler foreach item
  run_bundler_for_gemset { ['default', '3.5.1.14', '4.0.9', '4.1.6', '5.0.2']: }
}

class resque_service {
  file { '/opt/resque/start.sh':
    content => template('conf/start.sh.erb'),
    owner   => 'rhomobile',
    group   => 'admin',
    mode    => '0755',
  }
  file { '/Library/LaunchDaemons/com.rhomobile.buildslave.plist':
    source => 'puppet:///modules/conf/com.rhomobile.buildslave.plist',
    owner   => 'root',
    group   => 'wheel',
    mode    => '0644',
    require => File['/opt/resque/start.sh'],
    notify  => Service['com.rhomobile.buildslave'],
  }
  service { 'com.rhomobile.buildslave':
    provider => "launchd",
    ensure   => running,
    enable   => true,
    require  => File['/Library/LaunchDaemons/com.rhomobile.buildslave.plist'],
  }
}

notify { 'Starting resque service': }

# Main
node /prodmacslave/ {
  # export JAVA_HOME=`/usr/libexec/java_home`
  $jdk_path         = '/Library/Java/Home'
  $android_sdk_path = '/usr/local/opt/android-sdk'
  $android_ndk_path = '/usr/local/opt/android-ndk'
  $redis_url        = regsubst(file('/tmp/redis_url.txt'), '\n', '')

  # TODO:
  # $redis_url = file('puppet:///modules/conf/redis_url.txt')
  # notify {$redis_url:}

  class { 'requirements':   }         ->
  class { 'create_gemsets': }         ->
  class { 'install_gems': }           ->
  class  { 'rhodes_setup': }          ->
  Notify['Starting resque service']   ->
  class {'resque_service': }

}
