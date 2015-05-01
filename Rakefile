SSH     = "ssh -A -i ~/.ssh/rhomobilekey.pem"
SCP     = "scp -i ~/.ssh/rhomobilekey.pem"

REPO    = 'git@github.com:rhomobile/rho-puppet-scripts.git'
RHOHUBLIB_REPO = 'git@github.com:rhomobile/rhohublib.git'

HOSTNAME = 'rho-builder'

# Redis URL: staging build environment
# REDIS_URL = 'redistogo:79c82cb2de60532da5f0d49ad10dd62c@spadefish.redistogo.com:9658'
# Redis URL: test build environment
REDIS_URL = "redistogo:809c443d8a5c08cca4806b30555d27e7@greeneye.redistogo.com:10791"

namespace 'ubuntu' do
  desc "Bootstrap Puppet on ubuntu ENV['CLIENT'] with hostname '#{HOSTNAME}'"
  task :bootstrap do
    client    = ENV['CLIENT']
    user      = 'ubuntu'
    hostname  = HOSTNAME || client
    ip_hostname = "127.0.0.1 #{hostname}"

    #
    # Install puppet with rvm module
    commands = <<'BOOTSTRAP'
export TERM=xterm-256color; wget https://apt.puppetlabs.com/puppetlabs-release-trusty.deb -o /dev/null && \
sudo dpkg -i puppetlabs-release-trusty.deb && \
sudo apt-get update && sudo apt-get -y install git puppet && \
sudo puppet module install puppetlabs-stdlib && \
sudo puppet module install maestrodev-rvm && \
cd /etc/puppet/modules/rvm/lib/puppet/provider/rvm_gem && \
sudo sed -i '/^        command << source$/c\        command << \"-N\" << source' gem.rb
BOOTSTRAP
    puts "\nInstalling Puppet with modules ..."
    log = %x( #{SSH} #{user}@#{client} "#{commands}" )
    puts log

    #
    # Setup hostname
    commands = <<BOOTSTRAP
sudo su -c 'echo #{ip_hostname} >> /etc/hosts' && \
sudo hostname #{hostname} && sudo su -c 'echo #{hostname} > /etc/hostname'
BOOTSTRAP
    puts "\nSetup server hostname to #{hostname} ..."
    %x( #{SSH} #{user}@#{client} "#{commands}" )

    commands = <<'BOOTSTRAP'
echo -e \"Host github.com\n\tStrictHostKeyChecking no\n\" >> ~/.ssh/config
BOOTSTRAP
    #puts "\nDisable SSH StrictHostKeyChecking option"
    %x( #{SSH} #{user}@#{client} "#{commands}" )

    exit $?.exitstatus
  end

  desc "Run Puppet scripts on ubuntu ENV['CLIENT']"
  task :apply do
    client        = ENV['CLIENT']
    user          = 'ubuntu'
    redis_url     = ENV['REDIS_URL'] || REDIS_URL

    commands = <<BOOTSTRAP
sudo chown ubuntu:ubuntu -R /opt && mkdir -p /opt/resque && rm -rf /opt/resque/rhohublib && \
git clone #{RHOHUBLIB_REPO} /opt/resque/rhohublib && \
rm -rf puppet && git clone #{REPO} puppet && \
echo #{redis_url} > /tmp/redis_url.txt && \
sudo puppet apply ~/puppet/manifests/site.pp --modulepath=/etc/puppet/modules:~/puppet/modules
BOOTSTRAP

    puts "\nRunning Puppet scripts ..."
    log = %x( #{SSH} #{user}@#{client} "#{commands}" )
    puts log

    # 'RHOGLUSTERKEY' installation is optional
    rhoglusterkey = ENV['RHOGLUSTERKEY']
    if rhoglusterkey
      unless File.exist?(rhoglusterkey)
        puts "File '#{rhoglusterkey}' not found"
        exit(-1)
      end
      unless File.basename(rhoglusterkey, '.pem') == 'rhoglusterkey'
        puts "Invalid rhoglusterkey file name. 'rhoglusterkey.pem' file is expected."
        exit(-1)
      end
      commands = <<BOOTSTRAP
#{SCP} #{rhoglusterkey} ubuntu@#{client}:/opt/resque && #{SSH} #{user}@#{client} "sudo chmod 0400 /opt/resque/#{File.basename(rhoglusterkey)}"
BOOTSTRAP

      puts "Copy #{File.basename(rhoglusterkey)} file to #{user}@#{client}:/opt/resque directory."
      #puts commands
      %x( #{commands} )
    end
    exit $?.exitstatus
  end
end

namespace 'osx' do
  desc "Bootstrap Puppet on Mac OSX ENV['CLIENT'] with hostname '#{HOSTNAME}'"
  task :bootstrap do
    client = ENV['CLIENT']
    user   = 'rhomobile'

    # Install puppet
    commands = <<BOOTSTRAP
cd ~/Downloads && \
curl -O http://downloads.puppetlabs.com/mac/facter-2.1.0.dmg >/dev/null 2>&1 && \
curl -O http://downloads.puppetlabs.com/mac/hiera-1.3.4.dmg >/dev/null 2>&1 && \
curl -O http://downloads.puppetlabs.com/mac/puppet-3.6.2.dmg >/dev/null 2>&1
hdiutil mount facter-2.1.0.dmg && \
sudo installer -package /Volumes/facter-2.1.0/facter-2.1.0.pkg/ -target '/Volumes/Server HD' && \
hdiutil unmount /Volumes/facter-2.1.0 && \
hdiutil mount hiera-1.3.4.dmg && \
sudo installer -package /Volumes/hiera-1.3.4/hiera-1.3.4.pkg/ -target '/Volumes/Server HD' && \
hdiutil unmount /Volumes/hiera-1.3.4 && \
hdiutil mount puppet-3.6.2.dmg && \
sudo installer -package /Volumes/puppet-3.6.2/puppet-3.6.2.pkg/ -target '/Volumes/Server HD' && \
hdiutil unmount /Volumes/puppet-3.6.2 && \
sudo puppet --version && sudo facter | grep 'operatingsystem '
BOOTSTRAP
    puts "\nInstalling Puppet ..."
    puts %x( #{SSH} #{user}@#{client} "#{commands}" )

    exit $?.exitstatus
  end

  desc "Run Puppet scripts on Mac OSX ENV['CLIENT']"
  task :apply do
    client        = ENV['CLIENT']
    user          = 'rhomobile'
    redis_url     = ENV['REDIS_URL'] || REDIS_URL

    unless rhoglusterkey && File.exist?(rhoglusterkey)
      rhoglusterkey = 'rhoglusterkey.pem' if rhoglusterkey.nil? || rhoglusterkey.empty?
      puts "File '#{rhoglusterkey}' not found"
      exit(-1)
    end
    unless File.basename(rhoglusterkey, '.pem') == 'rhoglusterkey'
      puts "Invalid rhoglusterkey file name. 'rhoglusterkey.pem' file is expected."
      exit(-1)
    end

    commands = <<BOOTSTRAP
sudo chown -R rhomobile:admin /opt && mkdir -p /opt/resque && rm -rf /opt/resque/rhohublib && \
git clone #{RHOHUBLIB_REPO} /opt/resque/rhohublib && \
rm -rf puppet && git clone #{REPO} puppet && \
echo #{redis_url} > /tmp/redis_url.txt && \
sudo puppet apply ~/puppet/manifests/site_osx.pp --modulepath=~/puppet/modules
BOOTSTRAP
    puts "\nRunning Puppet scripts ..."
    puts commands # FIXME
    log = %x( #{SSH} #{user}@#{client} "#{commands}" )
    puts log

    # 'RHOGLUSTERKEY' installation is optional
    rhoglusterkey = ENV['RHOGLUSTERKEY']
    if rhoglusterkey
      unless File.exist?(rhoglusterkey)
        puts "File '#{rhoglusterkey}' not found"
        exit(-1)
      end
      unless File.basename(rhoglusterkey, '.pem') == 'rhoglusterkey'
        puts "Invalid rhoglusterkey file name. 'rhoglusterkey.pem' file is expected."
        exit(-1)
      end
      commands = <<BOOTSTRAP
#{SCP} #{rhoglusterkey} ubuntu@#{client}:/opt/resque && #{SSH} #{user}@#{client} "sudo chmod 0400 /opt/resque/#{File.basename(rhoglusterkey)}"
BOOTSTRAP

      puts "Copy #{File.basename(rhoglusterkey)} file to #{user}@#{client}:/opt/resque directory."
      #puts commands
      %x( #{commands} )
    end
    exit $?.exitstatus
  end

end
