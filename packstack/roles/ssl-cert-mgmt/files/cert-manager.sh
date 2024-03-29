#!/bin/bash

#ssl_dir="$PWD/openstack-ssl-certs"
ca_key="ca-key.pem"
ca_cert="ca-cert.pem"
ca_cert_input="{{ca_cert_input}}"

server_key="server-key.pem"
server_csr="server-csr.pem"
server_cert="server-cert.pem"
server_csr_input="{{server_csr_input}}"

combined_cert="openstack.pem"
# https://access.redhat.com/documentation/en-us/red_hat_openstack_platform/16.1/html/director_installation_and_usage/configuring-custom-ssl-tls-certificates

[ ! -f openssl.cnf ] && echo "Error! openssl.cnf not found in $PWD" && exit 1

[ ! -d /etc/pki/CA/newcerts ] && mkdir -p /etc/pki/CA/newcerts

[ -f /etc/pki/CA/newcerts/1000.pem ] && rm -rf /etc/pki/CA/newcerts/1000.pem

echo
echo "Setting up host to sign a certificate"
touch /etc/pki/CA/index.txt
echo '1000' | tee /etc/pki/CA/serial

ca_certs(){

	if [ ! -f $ca_key ];then
		echo
		echo "Create CA Key"
		openssl genrsa -out $ca_key 4096
	fi

	if [ ! -f $ca_cert ];then
		echo
		echo "Create CA cert"
		openssl req  -key $ca_key -new -x509 -days 7300 -extensions v3_ca -out $ca_cert -subj $ca_cert_input
	fi

#	echo
#	echo "Read out CA cert"
#	openssl x509 -in $ca_cert -noout -text

}

server_certs(){

	[ ! -f openssl.cnf ] && echo "Error! openssl.cnf not found" && exit 1

	if [ ! -f $server_key ];then
		echo
		echo "Creating Certificate Key"
		openssl genrsa -out $server_key 2048
		[ $? != 0 ] && echo "Failed to create $server_key" && rm -rf $server_key && exit 1
	fi

	if [ ! -f $server_csr ];then
		echo
		echo "Creating CSR"
		openssl req -config openssl.cnf -key $server_key -new -out $server_csr
		[ $? != 0 ] && echo "Failed to create $server_csr" && exit 1
	fi

	if [ ! -f $server_cert ];then
		echo
		echo "Creating Certificate"
		openssl ca -config openssl.cnf -extensions v3_req -days 3650 -in $server_csr \
			-out $server_cert -cert $ca_cert -keyfile $ca_key
		[ $? != 0 ] && echo "Failed to create cert" && exit 1
	fi

	echo
	echo "Verfy Server certs with CA"
	openssl verify -CAfile $ca_cert $server_cert

	cp $ca_cert /etc/pki/ca-trust/source/anchors/
	update-ca-trust extract

	echo
	echo "Remove passpharse from ssl key"
	openssl rsa -in $server_key -out nopassphrase.key

	echo "Combine server certificate and key"
	cat $server_cert nopassphrase.key > $combined_cert
	rm -rf nopassphrase.key

}

ca_certs

server_certs
