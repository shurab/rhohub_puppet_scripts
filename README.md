rho-puppet-scripts
==================

Collection of puppet scripts to make a newly provisioned Ubuntu Linux or Mac OS X machine that includes all needed
components to build rhodes android apps.

Before using scripts for Linux box, you should create a new Amazon EC2 instance based on image `ami-10e12578`. It's a vanilla
Ubuntu 14.04 64 bit image located in US East with SSH keys to access Rhomobile GitHub repositories.
For connection to this instance private key `rhomobilekey.pem` is used. Make sure that you have it in your ~/.ssh folder.
As soon as instance started, get the pubic instance address from AWS control panel; it'll be something like:

```
ec2-54-193-247-225.us-west-1.compute.amazonaws.com
```

## Bootstrap rake task

```
$ rake CLIENT=ec2-54-193-247-225.us-west-1.compute.amazonaws.com ubuntu:bootstrap
```

This task will install on client `ec2-54-193-247-225.us-west-1.compute.amazonaws.com` with hostname `rho_builder` the following packages:

* extra 32 bit libtaries required to run rhodes app on 64 bit machine
* openjdk-7-jdk
* Android SDK with tools, build tools, platform tools, and SDK Platforms (into /usr/local)
* Android NDK
* Puppet package with modules to use RVM

After task is over, you can login to instance and verify that puppet properly installed:

```
$ puppet --version
3.4.3
```

<pre>
$ sudo puppet module list
...
/etc/puppet/modules
├── maestrodev-rvm (v1.5.5)
└── puppetlabs-stdlib (v4.1.0)
/usr/share/puppet/modules (no modules installed)
</pre>

## Apply rake task
For this task you also need to provide two extra parameteres:

* RHOGLUSTERKEY parameter to copy RSA private key to target server.
* REDIS_URL parameter is a valid URL to Redis server (username:password@host:9658)

```
$ rake CLIENT=ec2-54-193-247-225.us-west-1.compute.amazonaws.com \
  RHOGLUSTERKEY=path-to/rhogluster.pem \
  REDIS_URL=79c82cb2de60532da5f0d49ad10dd62c@spadefish.redistogo.com:9658 ubuntu:apply
```

This task will clone this repository and run puppet scripts. In result, instance will have RVM with
ruby-1.9.3 and fully configured ruby gemsets for rhodes 3.5, 4.0, and 4.1 versions. Also, `rhogluster.pem` file
will be copied to provisioned Linux machine. And finally, puppet will start `/etc/init.d/resque` script.


## Putting it all together

Install RhoHub build tools and and provision Ubuntu Linux machine.

```
$ export CLIENT=your-amazon-instance-public-DNS
$ export RHOGLUSTERKEY=path-to-your/rhogluster.pem
$ export REDIS_URL=username:password@host:9658

$ rake ubuntu:bootstrap
$ rake ubuntu:apply
```

Install RhoHub build tools and provision Mac OS X machine.

```
$ export CLIENT=ip-address-of-mac
$ export RHOGLUSTERKEY=path-to-your/rhogluster.pem
$ export REDIS_URL=username:password@host:9658

$ rake osx:bootstrap
$ rake osx:apply
```
