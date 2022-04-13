#!/bin/bash

# Make sure user is created properly
if [ "$(ls /home/)" ]; then
  echo 'user exists'
else exit
fi

if [ -e /etc/puppetlabs/puppet/ssl/certs/ca.pem ] ;then
  /opt/puppetlabs/bin/puppet agent -t
exit
fi

# Change hostname
if [ -e /etc/namechange ] ;then
echo "new hostname has already been set"
sleep 3
else
LoginName=$(ls /home/)
machinename=$(hostname)
serial_number=$(shuf -i 0-10000 -n 1)
cat /etc/hosts
sed -i "s/$machinename/$LoginName-wsl-$serial_number/g" /etc/hosts
cat /etc/hosts
>/tmp/wsl.conf
cat >/tmp/wsl.conf <<EOF
[automount]
options = metadata

[network]
hostname = $LoginName-wsl-$serial_number
generateHosts = false
generateResolvConf = true

[interop]
enabled = true
appendWindowsPath = true
EOF
mv /tmp/wsl.conf /etc/wsl.conf
#echo "In 10 seconds the WSL image will now shutdown. You MUST wait 10 seconds before running WSL again. This will allow enough time for the hostname to change"
touch /etc/namechange
echo "WHEN YOU ARE IN WSL PLEASE RUN"
ECHO "sudo bash /usr/local/bin/enrolment.sh"
echo "TO FINISH INSTALLATION"
#sleep 10
#wsl.exe shutdown
exit
fi

sudo apt install libegl1-mesa libgl1-mesa-glx libxcb-xtest0 -y


# install puppet 
#wget http://apt.puppetlabs.com/puppet7-release-focal.deb -O /tmp/puppet7-release-focal.deb
#apt install /tmp/puppet7-release-focal.deb -y
#apt update
#apt install puppet-agent -y
#sleep 5

# Set hostname and gather facts
serial_number=$(shuf -i 0-10000 -n 1)
virtual=virtual

LoginName=$(ls /home/)
if [ $virtual == "physical" ]; then
  new_hostname="${LoginName}-linxwsl-${serial_number}.i8e.io"
else
  random=$(shuf -i 0-10000 -n 1)
  new_hostname="linxwsl-${LoginName}-${random}.i8e.io"
fi

# Set role and Type
echo "role=engineeringdefence" > '/tmp/role.txt'
mv /tmp/role.txt /opt/puppetlabs/facter/facts.d/role.txt
echo "type=desktop" > '/tmp/type.txt'
mv /tmp/type.txt /opt/puppetlabs/facter/facts.d/type.txt

# Set /etc/puppetlabs/puppet/puppet.conf
>/etc/puppetlabs/puppet/puppet.conf
cat >/etc/puppetlabs/puppet/puppet.conf <<EOF
[agent]
certname = ${new_hostname}
server = puppet.corp.i8e.io
certificate_revocation = false
environment = production
runinterval = 30m
reports = true
preferred_serialization_format = pson
csr_attributes  = \$confdir/csr_attributes.yaml

[main]
cfacter = false
stringify_facts = true
EOF

>/etc/puppetlabs/puppet/csr_attributes.yaml
cat >/etc/puppetlabs/puppet/csr_attributes.yaml <<EOF
---
extension_requests:
 1.3.6.1.4.1.34380.1.2.1.1: ${serial_number}
 1.3.6.1.4.1.34380.1.2.1.2: ${virtual}
EOF

# Add machine certificates
mkdir -p /etc/puppetlabs/puppet/ssl/certs/
>/etc/puppetlabs/puppet/ssl/certs/ca.pem
cat >/etc/puppetlabs/puppet/ssl/certs/ca.pem <<EOF
-----BEGIN CERTIFICATE-----
MIIEyDCCA7CgAwIBAgIBCTANBgkqhkiG9w0BAQ0FADCBnTEfMB0GA1UECgwWSW1w
cm9iYWJsZSBXb3JsZHMgTHRkLjEbMBkGA1UECQwSMjAgRmFycmluZ2RvbiBSb2Fk
MRIwEAYDVQQHDAlJc2xpbmd0b24xETAPBgNVBBEMCEVDMU0gM0hFMQswCQYDVQQG
EwJVSzEMMAoGA1UECwwDSU5GMRswGQYDVQQDDBJJbXByb2JhYmxlIFJvb3QgQ0Ew
HhcNMTYxMDA1MTUwOTQwWhcNMjYwMTAxMDAwMDAwWjCBpjEfMB0GA1UECgwWSW1w
cm9iYWJsZSBXb3JsZHMgTHRkLjEbMBkGA1UECQwSMjAgRmFycmluZ2RvbiBSb2Fk
MRIwEAYDVQQHDAlJc2xpbmd0b24xETAPBgNVBBEMCEVDMU0gM0hFMQswCQYDVQQG
EwJVSzEMMAoGA1UECwwDSU5GMSQwIgYDVQQDDBtJbXByb2JhYmxlIFB1cHBldCBD
bGllbnQgQ0EwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCwAHdtTBs0
cQF8uF3x+cWaBgdA43ph3C1Rk7sIRr3jMNJ2unRoNegeZuXMfg3G43lp7ce6omAA
Kur2+AgPZApRtiMzwxY3pjdxJ+Moqu4UST5+t2SPq8mJvs/xg4DpWJT1iUEBksIS
YCSZ7DNawgvWQjMRsgaDqSCSvAEAKR1VMjZQhxOQT45fxZjMu8rcjUph+vX1udOQ
sIHtWhuJX71zuZBUkcJzelYowRhpOBzeFyaB80BhNeqyTg5mRB8oNZUzmo4k9hn1
wrlABz7jnZS8m6WhE42alrvfH0LSr8nGRZs2j8/3IbkHf1wIb3YzX76qK9bqrm/C
hqlS1qXaKkwzAgMBAAGjggEGMIIBAjAOBgNVHQ8BAf8EBAMCAQYwEgYDVR0TAQH/
BAgwBgEB/wIBADAdBgNVHQ4EFgQUChSUxB6/NZP8JOOcUKZoOX0RX88wHwYDVR0j
BBgwFoAUcCHx0PEms/XtUd5EJmacw+a/Ne4wQAYIKwYBBQUHAQEENDAyMDAGCCsG
AQUFBzAChiRodHRwOi8vcGtpLmltcHJvYmFibGUuaW8vcm9vdC1jYS5jZXIwNQYD
VR0fBC4wLDAqoCigJoYkaHR0cDovL3BraS5pbXByb2JhYmxlLmlvL3Jvb3QtY2Eu
Y3JsMCMGA1UdIAQcMBowCwYJKwYBBAEAAQcIMAsGCSsGAQQBAAEHCTANBgkqhkiG
9w0BAQ0FAAOCAQEAELeagOpLYXxJuFkrwaiXBQF7B8EGczKz/sY6kVcDrTNBtUvs
LbUKja48mwd4KaVUITTKIDLgd2LfHxjrjXAzlMxNnp5eOrNB8yRuRdV5YQlsCKj0
lEpf5kOmR7FRzW/2ixf4VYas8TPnl1uwGfEAy+UGQqqB9etjTXzY1pX+yqXFUqIe
B/83J5/jhlHjrWfTs9r20Rv1k6QJha5TRaqfgHgbPYlxQ/Tx6ELX7otF8GYjzvIC
lNNmbD59bhpX7n3zA4TvPWR2FITbw4UmEk2T7fY2Ib9iJB1J7vVghfLnawGIBdNt
Ikp9JKeXj6YHcLx+fyO5jULLPd1hfnTUiKlTjg==
-----END CERTIFICATE-----
-----BEGIN CERTIFICATE-----
MIIEGjCCAwKgAwIBAgIBATANBgkqhkiG9w0BAQ0FADCBnTEfMB0GA1UECgwWSW1w
cm9iYWJsZSBXb3JsZHMgTHRkLjEbMBkGA1UECQwSMjAgRmFycmluZ2RvbiBSb2Fk
MRIwEAYDVQQHDAlJc2xpbmd0b24xETAPBgNVBBEMCEVDMU0gM0hFMQswCQYDVQQG
EwJVSzEMMAoGA1UECwwDSU5GMRswGQYDVQQDDBJJbXByb2JhYmxlIFJvb3QgQ0Ew
HhcNMTYwNjI0MTEwOTQ2WhcNMjYwMTAxMDAwMDAwWjCBnTEfMB0GA1UECgwWSW1w
cm9iYWJsZSBXb3JsZHMgTHRkLjEbMBkGA1UECQwSMjAgRmFycmluZ2RvbiBSb2Fk
MRIwEAYDVQQHDAlJc2xpbmd0b24xETAPBgNVBBEMCEVDMU0gM0hFMQswCQYDVQQG
EwJVSzEMMAoGA1UECwwDSU5GMRswGQYDVQQDDBJJbXByb2JhYmxlIFJvb3QgQ0Ew
ggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDcJyflv8UOSZquM13hJ4OL
U/PifAU7Cxrfb3hbaFZb+0xb0SgIrBFCsIddWHnWnUq9TJSriMM+GDcEH6W+5O4j
bz6bpSwQU6xdtRH+0CKpXozkqp8oKBYbXxU8/fjY7aztnXZ8KdTfoytCfIfcYe0K
2y+dAtZLQ5HKueJY9UvG7rYfvJ7jc+nF22YDWiiVFVvs0V/mU1nm6EYoRcvuExCA
wAP8+16IhwoPNE/4S3UavaEkKzpc8ZL83xE2eIrjLUzSjVHDAqVJZme6LiJtduu/
OM22nAnqcNTPXYwHmWLLoT/GaeKEsWOzRANqu8p4NyVg9oiOWM7gPcyA1YSucgvh
AgMBAAGjYzBhMA4GA1UdDwEB/wQEAwIBBjAPBgNVHRMBAf8EBTADAQH/MB0GA1Ud
DgQWBBRwIfHQ8Saz9e1R3kQmZpzD5r817jAfBgNVHSMEGDAWgBRwIfHQ8Saz9e1R
3kQmZpzD5r817jANBgkqhkiG9w0BAQ0FAAOCAQEAOVeKWcpvE4N0YRssIlK+AFx9
UArVZduD8dupk91AizAvkWbvlAD03q5Rh570+biWPAjOGfEbtxvL4tVPmXiGTwBo
3zQP4JxRbqRBL381O1IrTqcJYg3wmn1h3YFoSPgzS26eYrUifMtaiIojA/3m5P+n
b3OH93abN++nVmzUDzoG/vKlYG6ShNnMqhgYZ1FwUA/hT4tWH7OL+kNtZCYfpp8P
jY6owd+kUol3vDTWz3Y2P6h9z9i3Dt8ezAsL2Fx/gv/FTXVl/2Ul+LxPDQPUjEsy
KwHGDhVqRfDf5+wB2BxWZnxZe+dZm/vShJB0AXk7kvtBtwUojQJSawihxwFe5Q==
-----END CERTIFICATE-----
EOF


# Install google SDK
# bash /usr/local/bin/google-cloud-sdk/install.sh --rc-path /home/${LoginName}/.bashrc -q

# Install flatpak
# flatpak install flathub com.jetbrains.CLion -y 

# Add puppet to the $PATH
echo 'PATH="'$PATH':/opt/puppetlabs/bin:/usr/local/bin:/sbin:/usr/sbin"' >/etc/environment
export PATH=$PATH:/opt/puppetlabs/bin:/usr/local/bin:/sbin:/usr/sbin

# Run puppet for the first time and show output
/opt/puppetlabs/bin/puppet agent -t --waitforcert=120

#Running second time to ensure is all set...
opt/puppetlabs/bin/puppet agent -t

# Start puppet agent service
/opt/puppetlabs/bin/puppet resource service puppet ensure=running enable=true

# Finish
echo -e "\033[0;32mThe Script is finished\n"
