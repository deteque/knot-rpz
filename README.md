# knot-rpz
This docker image is designed to pull various Response Policy Zones (RPZ) from commercial feeds then redistribute them to your local RPZ enabled recursive servers.  The configuration script is geared towards Deteque's RPZ feeds, however, it will support any third party feeds with minor modifications.

# Installation
Your base server should have at least 4 CPU cores and 6GB of RAM.  All of the files that Knot creates will be placed in a bind mounted volume under /etc/knot.  Becuase the docker image will contain its own users and groups, we need to create that directory with liberal permissions.

On your server, execute the following commands:
<pre>
	mkdir -p /etc/knot
	mkdir -p /etc/knot/timers
	mkdir -p /etc/knot/journal
	mkdir -p /etc/knot/zonefiles
	chmod -R 1777 /etc/knot/
</pre>

Your customized version of the knot configuration file (knot.conf) will need to be placed in /etc/knot.  As a go-by, the image has a template of knot.conf in the /tmp directory of the docker image.  You can also simply download that file from Docker Hub and modify it accordingly.

# Running the Knot image
You should start the docker image using this syntax:

	docker run --name knot-rpz --rm --detach -v /etc/knot:/etc/knot -p 53:53/udp -p 53:53/tcp knot-rpz

A breakdown of the command:
	--name will name the docker process
	--rm will cause the image to be deleted when it stops
	--detach  detaches the image from the terminal while it is running
	-v this is the bind mount that presents the /etc/knot directory into the docker image
	-p the ports that you are exposing from the server to the docker image
	knot-rpz the name of the docker image

If your server sits behind a firewall, be sure to open up *BOTH* udp and tcp port 53.  If you don't do thiat, the AXFR transfers will fail because they almost always require TCP.

In accordance with the way Docker wishes each image to work, all logs created from Knot are sent out to STDOUT.  You can access the logs of a running instance by:
	docker logs knot-rpz

If you wish to watch the logs in realtime, add the "-f" (follow option); this will work much like "tailing" a file:
	docker logs -f knot-rpz

# Knot Configuration File
The knot.conf file requires a small amount of customization.  Once edited, you should place this file on your server at /etc/knot/knot.conf.  The /etc/knot directory will be bind mounted when you run the knot-rpz image, so any changes you make to that directory will persist.  You can edit that file from within a running docker instance or simply from the host without docker running.

You'll find the knot.conf.EXAMPLE file in the docker image located at /tmp/knot.conf.EXAMPLE.

The first change you need to make is in the section labeled "remote:".  There are three dummy entries called rpzMaster_[123].  The name isn't important, but you must set the ip address of the server you pull your rpz zones from.  Deteque customers will find that information in the customer portal.  If you only pull from one server, delete the _2 and _3 entries and edit the _1 entry as needed.

The second change that needs to be made is in the "acl:" section.  You should delete the "address: " lines under "private-distribution" and add the actual IP addresses of *your* recursive rpz nameservers.   This restricts which nameservers can pull the rpz zones from your distribution server.

Finally, in the "template:" section, there is a line looks like this:
	master: [ rpzMaster_1, rpzMaster_2, rpzMaster_3 ]
That line needs to be edited to include the actual names of the servers you pull the zones from, exactly as they appear in the id: portion in the "remote: " section.

# Contents of the sample knot.conf file
```
server:
  listen: [ 0.0.0.0@53, ::@53 ]
  user: knot:knot
  pidfile: /etc/knot/knot.pid
  rundir: /etc/knot
  max-tcp-clients: 500
  identity:
  version:
  nsid:

mod-stats:
  - id: default
    request-protocol: on
    server-operation: on
    request-bytes: off
    response-bytes: off
    edns-presence: on
    flag-presence: off
    response-code: on
    reply-nodata: on
    query-type: on
    query-size: on
    reply-size: on

log:

  - target: stdout
    any: info

remote:

  - id: rpzMaster_1
    address: 192.168.1.1

  - id: rpzMaster_2
    address: 192.168.2.2

  - id: rpzMaster_3
    address: 192.168.3.3

#------------------------------------------------------------------------------
# The ACL section is used to restrict who can pull the RPZ zones from this 
# server.  Under no circumstances should you open the permissions to the
# world.  The default settings allow any servers using RFC-1918 space to
# connect.  This is really just a sample config.  
#
# You should remove the three "address:" lines in the acl section and
# replace them with the actual IP addresses for each individual 
# nameserver that should be permitted to pull the rpz zones.
# 
# If your Knot server is in front of your NAT'ed firewall, and all 
# recursives are behind your firewall, you should implement TSIG
# authentication to prevent every single address in your private
# network from being able to access your distribution server.
#------------------------------------------------------------------------------

acl:

  - id: private-distribution
    address: 10.0.0.0/8
    address: 172.16.0.0/12
    address: 192.168.0.0/16
    action: transfer

  - id: deny_all
    address: 0.0.0.0/0
    address: ::/0
    deny: on

template:

  - id: default
    storage: /etc/knot/zonefiles/
    timer-db: /etc/knot/timers/
    journal-db: /etc/knot/journal/
    journal-content: changes
    journal-db-mode: robust
    zonefile-load: difference
    semantic-checks: off
    disable-any: on
    master: [ rpz02-iad, rpz03-iad, rpz01-iad ]
    file: /etc/knot/zonefiles/%s
    acl: [ private-distribution, deny_all ]

#------------------------------------------------------------------------------
# PLEASE READ THIS
#
# Deteque offers a wide variety of RPZ zones which permits DNS administrators
# to create a security policy suited to their unique needs.  An additional
# advantage of offering threats broken down by zone is that rpz rewrite logs
# become far more descriptive.
#
# You will notice that some zones have "edit" and "hacked" as additional
# descriptors.  Those zones marked as "edit" contain entries whose bad
# reputation score meets a higher threshold than the non-edit counterpart.
# They basically are a subset of the non-edit version of the zone.
#
# Those zones marked as "hacked" represent otherwise legitimate zones that
# have become compromised and have been detected sending out spam, malware,
# acting as a botnet controller or hosting/serving malicious content.
#
# Impementing "hacked" RPZ zones may generate user complaints like, "Why 
# can't I access this site that I've been going to for 5 years?".
# If you are adverse to dealing with such complaints, you probably don't
# want to use them.  However, if you don't use them, you're going to be
# potentially exposing your customers to some very bad stuff that could
# and should be blocked.
#
# Below you'll see each category of RPZ zones that Deteque offers.  Please
# comment out any zones that you don't intend to use.  Also note that the
# knot.conf file is in yaml format; any entries that begin with 
# - domain: should have two spaces to the left of the dash ("-").  If
# you're not familair with yaml rest assured that a yaml config is
# much better and easier to work with than an xml config.
#
# The "#" character is used to comment out a line.  Place a "#" at the
# beginning of the line for any domain that you do not need.
#------------------------------------------------------------------------------

zone:

#------------------------------------------------------------------------------
# Deteque Abused Legit RPZ Zones
#------------------------------------------------------------------------------
  - domain: badrep.hacked.host.dtq
  - domain: botnetcc.hacked.host.dtq
  - domain: botnetcc.hacked.ip.dtq
  - domain: malware.hacked.host.dtq
  - domain: phish.hacked.host.dtq

#------------------------------------------------------------------------------
# Deteque Botnet RPZ Zones
#------------------------------------------------------------------------------
  - domain: botnetcc.edit.host.dtq
  - domain: botnetcc.host.dtq
  - domain: botnetcc.ip.dtq
  - domain: botnet.edit.host.dtq
  - domain: botnet.host.dtq
  - domain: dga.host.dtq

#------------------------------------------------------------------------------
# Deteque Malware RPZ Zones
#------------------------------------------------------------------------------
  - domain: malware.edit.host.dtq
  - domain: malware.host.dtq

#------------------------------------------------------------------------------
# Deteque Bad Reputation RPZ Zones
#------------------------------------------------------------------------------
  - domain: adware.edit.host.dtq
  - domain: adware.host.dtq
  - domain: bad-nameservers.host.dtq
  - domain: bad-nameservers.ip.dtq
  - domain: badrep.edit.host.dtq
  - domain: badrep.host.dtq
  - domain: bogons.ip.dtq
  - domain: drop.ip.dtq

#------------------------------------------------------------------------------
# Deteque Phishing RPZ Zones
#------------------------------------------------------------------------------
  - domain: phish.edit.host.dtq
  - domain: phish.host.dtq

#------------------------------------------------------------------------------
# Deteque Third Party RPZ Zones
#------------------------------------------------------------------------------
  - domain: coinblocker.srv
  - domain: porn.host.srv
  - domain: torblock.srv

#------------------------------------------------------------------------------
# Deteque Restricted RPZ Zones (require special permissions to access)
#------------------------------------------------------------------------------

# - domain: zrd.host.dtq
```



