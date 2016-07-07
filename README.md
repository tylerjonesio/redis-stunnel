# redis-stunnel

Docker image for providing a TLS endpoint for accessing Redis.

## Usage

The easiest setup is to have this running in parallel with a Redis container on a host machine. The basic gist is as follows:

* Start `redis` container (no need to expose the port)
* Create a CA and server certificate (see below)
* Start `redis-stunnel` container with a link to the `redis` container and exposing the TLS port

Details are below.

### Redis Container

Pretty straight forward:

```bash
docker run -d --name redis redis:2.8
```

### CA and Certificate

This is a little more involved. These are roughly the steps:

```bash
# Generate a CA key - will ask for a passphrase
openssl genrsa -aes256 -out ca-key.pem 4096 
# Generate the CA - will ask for various details, defaults all fine
openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem
# Generate a key for the server certificate
openssl genrsa -out server-key.pem 4096
# Generate a certificate signing request
HOST=localhost openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr
# Generate a server certificate w/ appropriate options - will ask for passphrase
echo subjectAltName = IP:127.0.0.1 > extfile.cnf
openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
  -CAcreateserial -out server-cert.pem -extfile extfile.cnf
# Combine key and certificate for stunnel server
cat server-key.pem server-cert.pem > rediscert.pem 
```

### stunnel Container

Start the new container with the certificate, link, and exposed ports:

```bash
docker run -d \
  --link redis:redis \
  -v `pwd`/rediscert.pem:/stunnel/private.pem:ro \
  -p 6380:6380 \
  runnable/redis-stunnel
```

## Testing the Setup

To test the `stunnel` setup, run the following NodeJS script. It should print out `[]` (an empty list) if it is a clean Redis server, but would otherwise print out all the keys on the server.

Before being able to run this script, `ioredis` needs to be installed with `npm`.

```js
var fs = require('fs')
var Redis = require('ioredis')

var redis = new Redis({
  host: '127.0.0.1',
  port: 6380,
  tls: {
    ca: fs.readFileSync('ca.pem')
  }
})

redis.keys('*', (err, keys) => {
  if (err) { throw err }
  console.log(keys)
  redis.disconnect()
})
```
