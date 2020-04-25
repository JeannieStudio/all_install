#!/bin/bash
echo "1:"
read domainname
echo "2:"
read emailname
echo "$domainname {  
        gzip  
		tls $emailname
        root /var/www/
		redir / https://$domainname/{uri} 301
        proxy / http://127.0.0.1:3999 { 
                header_upstream Host {host}
                header_upstream X-Real-IP {remote}
                header_upstream X-Forwarded-For {remote}
                header_upstream X-Forwarded-Proto {scheme}
        }
}" > /test/Caddyfile