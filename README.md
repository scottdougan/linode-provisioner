# Linode Provisioner 

This is a bash script that creates a new Linode and does some basic provisioning.  I basically got sick of creating Linodes using the web interface and doing the same basic setup steps (creating users, uploading ssh keys, disabling root login, etc.) every time I wanted a new server. These aren't hard tasks to do but it takes away time I could be using to do other things. Before I started playing with Ansible I wrote this to automate the process. I tried using StackScripts to do the same kind of thing but ran into a few bugs I couldn't figure out. Plus I wanted something that would also work with Vagrant or other VM providers. 

The script relies on the [Linode CLI](https://github.com/linode/cli) (command-line interface) to create the new Linodes. Once the Linode is created it uploads another bash script located in the "provision" folder and executes it on the new machine.  It Updates the system, adds users with ssh keys, updates IP tables, system time, sshd config, etc. Basically everything I usually do with any new server I create.  The create_linode script does a bit of error checking so other users should be able to figure out whats failing pretty easily. 

## Installation

* Clone this repository
* Install and configure [Linode CLI](https://github.com/linode/cli)

## Usage

The "create_linode.sh" script takes 2 optional parameters: First, the name of the newly created server and second, the domain name associated with it. 
```
./create_linode.sh $server_name $domain_name
```

#### Note
* If only a server name is entered the script will use whatever the `default_domain_name` variable is set to.  
* The provision script will only set the FQDN (fully qualified domain name) in the hosts file if a server name is entered. 
* If no parameters are given the newly created Linode will be called "New_(The current time)" (ex. "New_2015-09-22_17-17-44") 

### Examples
```
./create_linode.sh
./create_linode.sh myNewApp
./create_linode.sh Lucky cats.com
```

**Enjoy!**