# -*- mode: ruby -*-
# vi: set ft=ruby :

# Require modules
require 'json'
require 'yaml'
require 'socket'

VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

PORT_OFFSET = 10


# Read environment details from either yml or json file

configuration_file = File.join(VAGRANT_ROOT, 'environments.yml')

if File.file?(configuration_file)
  environments = YAML.load_file(configuration_file)
  # print "'" + configuration_file + "' configuration will be used."
else
  configuration_file = File.join(VAGRANT_ROOT, 'environments.json')
  environments = JSON.parse(File.read(configuration_file))
  # print "'" + configuration_file + "' configuration will be used."
end

# check required plugins
required_plugins = ['vagrant-vbguest']#'vagrant-docker-compose']

required_plugins.each do |plugin|

  unless Vagrant.has_plugin?(plugin)
    puts "Vagrant plugin '#{plugin}' is required, try installing..."
    system("vagrant plugin install #{plugin}")
    puts "Please run 'vagrant up' again.\n\n"
    exit
  end

end

# check required variables
required_vars = ['id', 'path', 'docker_image', 'oms_src', 'docker_db_image']

required_vars.each do |var|

  environments.each.with_index(1) do |environment , index|

    unless environment[var]
      puts "required variable '#{var}' is missing for environment #{environment['id']} in environment.yml. Please set it and restart. For details please see environment.yml.sample"
      exit
    end
  end

end



Vagrant.configure(2) do |config|

  config.vm.box = "bento/centos-7.3"
  # config.vm.box_version = "=2.2.9"

  # create a docker host

  config.vm.define "iomdev" do |node|

    ################# dockerize the vm ##################

    node.vm.provision "docker"

    # The following line terminates all ssh connections. Therefore
    # Vagrant will be forced to reconnect.
    # That's a workaround to have the docker command in the PATH
    node.vm.provision "shell", inline: <<-SHELL
        ps aux | grep 'sshd:' | awk '{print $2}' | xargs kill
    SHELL

    # provide a private docker registry
    node.vm.network :forwarded_port, guest: 5000, host: 5000

    node.vm.provision :shell, inline: <<-SHELL

      # configure docker daemon
      echo '{"insecure-registries":["10.0.10.0:5000"], "debug":true}' > /etc/docker/daemon.json

      # restart docker daemon
      systemctl restart docker

      # install the Intershop Root Certification Authority for Docker
      # please see: https://confluence.intershop.de/pages/viewpage.action?spaceKey=ATEAMDOC&title=How+to+install+the+Intershop+Root+Certification+Authority+for+Docker

      # create the docker certificate store
      mkdir -p /etc/docker/certs.d/

      # create also a certificate for the private docker registry
      mkdir -p /etc/docker/certs.d/jengdocker01.rnd.j.intershop.de:5000

      # download file from a file path
      curl http://pki.intershop.de:81/CertEnroll/ISH-CA01.crt -o /tmp/ISH-CA01.crt

      # convert the downloaded file from DER format to PEM format using Openssl
      openssl x509 -inform der -in /tmp/ISH-CA01.crt -out /etc/docker/certs.d/jengdocker01.rnd.j.intershop.de:5000/ca.crt

      # login to the docker registry with Artifactory API KEY
      docker login -u omsdeploy -p AKCp2WXCQMJb6cGKso9FJfWerMe1V248PVx8DM19BNsTKrRFQ3f3LTRfsAEHZPmX6ZAnd8a4X jengdocker01.rnd.j.intershop.de:5000

    SHELL

    #####################################################

    node.vm.provision :shell, run: "always", inline: <<-SHELL

      # ensure IPv4 forwarding is enabled
      sysctl -w net.ipv4.ip_forward=1

      # restart docker daemon
      systemctl restart docker

    SHELL

    environments.each.with_index(1) do |environment , index|

      node.vm.provision :shell, run: "always", inline: <<-SHELL

        cd /vagrant/scripts

        ### Static variables
        export ID=#{environment['id']}
        export INDEX=#{index}
        export HOST_IOM=#{Socket.gethostname}
        export PROJECT_PATH=#{VAGRANT_ROOT}

        export PORT_OFFSET=#{PORT_OFFSET}
        export PORT_IOM=8080
        export PORT_DEBUG=8787
        export PORT_DB=5432
        export PORT_WILDFLY=9990

        export OMS_DB_NAME=#{environment['oms_db_name']}
        export OMS_DB_USER=#{environment['oms_db_user']}
        export OMS_DB_PASSWORD=#{environment['oms_db_password']}
        export OMS_DB_DUMP=#{environment['oms_db_dump']}

        # create documentations
        ./template_engine.sh ../templates/index.template > /tmp/#{environment['id']}/index.html

        # create alias scripts
        ./template_engine.sh ../templates/alias.template > /tmp/#{environment['id']}/alias.sh

      SHELL

    end



    node.vm.hostname = "iomdev"

    node.vm.network :private_network, ip: "10.0.10.0"

    ### port forwarding

    environments.each.with_index(1) do |environment , index|

      # OMT
      node.vm.network :forwarded_port, guest: "#{8080 + (index * PORT_OFFSET)}", host: "#{8080 + (index * PORT_OFFSET)}"
      # wildfly console
      node.vm.network :forwarded_port, guest: "#{9990 + (index * PORT_OFFSET)}", host: "#{9990 + (index * PORT_OFFSET)}"
      # debug port
      node.vm.network :forwarded_port, guest: "#{8787 + (index * PORT_OFFSET)}", host: "#{8787 + (index * PORT_OFFSET)}"
      # database port
      node.vm.network :forwarded_port, guest: "#{5432 + (index * PORT_OFFSET)}", host: "#{5432 + (index * PORT_OFFSET)}"

    end

    node.vm.provider "virtualbox" do |vb|
      vb.name = "iomdev"
      vb.memory = "#{environments.length * 3 * 1024}"
      vb.cpus = 2
    end

    ### file synchronization

    environments.each.with_index(1) do |environment , index|

      # configure the project path
      node.vm.synced_folder "#{environment['path']}", "/tmp/#{environment['id']}"

      # configure the etc path
      if environment['oms_etc']
        node.vm.synced_folder "#{environment['oms_etc']}", "/tmp/#{environment['id']}/etc"
      else
        node.vm.synced_folder File.join("#{environment['path']}", "etc"), "/tmp/#{environment['id']}/etc", create: true
      end

      # configure the app path
      if environment['oms_app']
        node.vm.synced_folder "#{environment['oms_app']}", "/tmp/#{environment['id']}/app"
      end

      # configure the log path
      if environment['oms_etc']
        node.vm.synced_folder "#{environment['oms_log']}", "/tmp/#{environment['id']}/log"
      else
        node.vm.synced_folder File.join("#{environment['path']}", "log"), "/tmp/#{environment['id']}/log", create: true
      end

      # configure the log path
      node.vm.synced_folder "#{environment['oms_log']}", "/tmp/#{environment['id']}/log"

      # configure the src path
      if environment['oms_src']
        node.vm.synced_folder "#{environment['oms_src']}", "/tmp/#{environment['id']}/src"
      end

    end

  end

end
