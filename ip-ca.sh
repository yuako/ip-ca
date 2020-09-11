#!/bin/bash

dir="keystore"
pwd="changeit"
ou="yuako"
cacerts="$JAVA_HOME"/jre/lib/security/cacerts

read -p ">>> Self-signed IP certificate, please enter the IP address: " ip

function create() {
    if [ ! -d $dir ]; then
      mkdir $dir
    fi
    echo -e ">>> Key file is being generated, default password is： $pwd"
    keytool -genkey -alias "$ip" -keyalg RSA -keysize 1024 -keypass $pwd -storepass $pwd -dname "CN=$ip,OU=$ou,OU=$ou,C=CN" -ext san=ip:"$ip" -validity 3600 -keystore $dir/"$ip".keystore

    keytool -exportcert -alias "$ip" -storepass $pwd -keystore $dir/"$ip".keystore -file $dir/"$ip".cer

    keytool -importkeystore -srckeystore $dir/"$ip".keystore -destkeystore $dir/"$ip".p12 -srcstoretype jks -deststoretype pkcs12
    openssl pkcs12 -nocerts -nodes -in $dir/"$ip".p12 -out $dir/"$ip".key
    echo -e ">>> The certificate file used by nginx is being generated"
    openssl pkcs12 -in $dir/"$ip".p12 -nokeys -clcerts -out $dir/"$ip".ssl.crt
    openssl pkcs12 -in $dir/"$ip".p12 -nokeys -cacerts -out $dir/"$ip".ca.crt
    cat $dir/"$ip".ssl.crt $dir/"$ip".ca.crt > $dir/"$ip".crt
}

function import() {
    echo -e ">>> Import the certificate to cacerts under JAVA_HOME\n"
    keytool -import -keystore $cacerts -file $dir/"$ip".cer -alias "$ip"
}

function all() {
  echo -e ">>> Get a list of all certificates\n"
    keytool -list -keystore $cacerts
}

function delete() {
    echo -e ">>> Delete related certificate files\n"
    rm -rf "$dir/$ip"*
    keytool -delete -alias "$ip" -keystore $cacerts
}

function run() {
    delete
    create
    import
}

if [ $# -eq 0 ]; then
    echo -e "No instructions provided. Default execution [run]\n"
    run
    exit 0
fi

case "$1" in
"create")
    create
    ;;
"delete")
    delete
    ;;
"all")
    all
    ;;
"import")
    import
    ;;
*)
    run
    ;;
esac