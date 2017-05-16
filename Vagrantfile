# -*- mode: ruby -*-
# vi: set ft=ruby :

# Require modules
require 'json'
require 'yaml'

VAGRANT_ROOT = File.dirname(File.expand_path(__FILE__))

PORT_OFFSET = 10

# Read environment details from either yml or json file

configuration_file = File.join(VAGRANT_ROOT, 'environments.yml')

if File.file?(configuration_file)
  environments = YAML.load_file(configuration_file)
  # print "'" + configuration_file + "' configuration will be used."
else
  configuration_file = File.join(VAGRANT_ROOT, 'environments.json')
  environments = JSON.parse(configuration_file)
  # print "'" + configuration_file + "' configuration will be used."
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
    node.vm.provision "shell", inline: <<-SCRIPT
        ps aux | grep 'sshd:' | awk '{print $2}' | xargs kill
    SCRIPT

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
      mkdir /etc/docker/certs.d/

      # create also a certificate for the private docker registry
      mkdir /etc/docker/certs.d/jengdocker01.rnd.j.intershop.de:5000

      # download file from a file path
      curl http://pki.intershop.de:81/CertEnroll/ISH-CA01.crt -o /tmp/ISH-CA01.crt

      # convert the downloaded file from DER format to PEM format using Openssl
      openssl x509 -inform der -in /tmp/ISH-CA01.crt -out /etc/docker/certs.d/jengdocker01.rnd.j.intershop.de:5000/ca.crt

      # login to the docker registry with Artifactory API KEY
      docker login -u omsdeploy -p AKCp2WXCQMJb6cGKso9FJfWerMe1V248PVx8DM19BNsTKrRFQ3f3LTRfsAEHZPmX6ZAnd8a4X jengdocker01.rnd.j.intershop.de:5000

    SHELL

    #####################################################

    node.vm.hostname = "iomdev"

    node.vm.network :private_network, ip: "10.0.10.0"

    ### port forwarding

    environments.each.with_index(10) do |environment , index|

      # OMT
      node.vm.network :forwarded_port, guest: "#{8080 + (index * PORT_OFFSET)}", host: "#{8080 + (index * PORT_OFFSET)}"
      # wildfly console
      node.vm.network :forwarded_port, guest: "#{9990 + (index * PORT_OFFSET)}", host: "#{9990 + (index * PORT_OFFSET)}"
      # debug port
      node.vm.network :forwarded_port, guest: "#{8787 + (index * PORT_OFFSET)}", host: "#{8787 + (index * PORT_OFFSET)}"

      # node.vm.network :forwarded_port, guest: ""#{5432 + (index * PORT_OFFSET)}", host: "#{15432 + (index * PORT_OFFSET)}"

    end

    node.vm.provider "virtualbox" do |vb|
      vb.name = "iomdev"
      vb.memory = "4096"

    end

    ### file synchronization

    environments.each.with_index(10) do |environment , index|

      # configure the etc path
      node.vm.synced_folder "#{environment['oms_etc']}", "/tmp/#{environment['id']}/etc"

      # configure the app path
      if environment['oms_app']
        node.vm.synced_folder "#{environment['oms_app']}", "/tmp/#{environment['id']}/app"
      end

      # configure the log path
      node.vm.synced_folder "#{environment['oms_log']}", "/tmp/#{environment['id']}/log"

    end

  end

end
