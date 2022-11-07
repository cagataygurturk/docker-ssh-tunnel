[![](https://images.microbadger.com/badges/image/cagataygurturk/docker-ssh-tunnel.svg)](https://microbadger.com/images/cagataygurturk/docker-ssh-tunnel)

# Docker SSH Tunnel

This Docker creates a simple SSH tunnel to a remote server.

## Usage

### Docker

1. First you should create a config file in your local directory. For simplicity you can create this file in `~/.ssh` in your local machine.

2. Inside `~/.ssh/config` put these lines:

```
    Host mysql-tunnel # You can use any name
            HostName ssh-tunnel.corporate.tld # Tunnel 
            IdentityFile ~/.ssh/id_rsa # Private key location
            User cagatay.guertuerk # Username to connect to SSH service
            ForwardAgent yes
            TCPKeepAlive yes
            ConnectTimeout 5
            ServerAliveCountMax 10
            ServerAliveInterval 15
```

3. Don't forget to put your private key (`id_rsa`) to `~/.ssh` folder.

4. Now in `docker-compose.yml` you can define the tunnel as follows:

```
    version: '2'
    services:
      mysql:
        image: cagataygurturk/docker-ssh-tunnel
        volumes:
          - $HOME/.ssh:/root/ssh:ro
        environment:
	  SSH_DEBUG: "-v"
          TUNNEL_HOST: mysql-tunnel
	  TUNNEL_HOST_PORT: 22
          REMOTE_HOST: tunneled-sql.corporate.internal.tld
          LOCAL_PORT: 3306
          REMOTE_PORT: 3306
```

5. Run `docker-compose up -d`

After you start up docker containers, any container in the same container network will be able to access to tunneled mysql instance using ```tcp://mysql:3306```. Of course you can also expose port 3306 to be able to access to tunneled resource from your host machine.

### Kubernetes 

It is perfectly possible to use this container in Kubernetes and actually the sidecar pattern is very suitable for Kubernetes. If your application requires connecting to a remote resource through a SSH tunnel, you can place this container as a sidecar container to your application and let your application connect to this resource securely.

In the example below, our application (container named "mariadb") is connecting to a remote MariaDB instance through SSH tunnel.

For that, first create the SSH key as a secret:

````
$ kubectl create secret generic ssh-key-secret --from-file=ssh-privatekey=$PATH_TO_SSH_KEY`
````

Later use this Kubernetes manifest:

````yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ssh-config
data:
  config: |
    Host mysql-tunnel # You can use any name
            HostName tunneled-sql.corporate.internal.tld # Tunnel 
            IdentityFile ~/.ssh/id_rsa # Private key location
            User root # Username to connect to SSH service
            ForwardAgent yes
            TCPKeepAlive yes
            ConnectTimeout 5
            ServerAliveCountMax 10
            ServerAliveInterval 15
---
apiVersion: batch/v1
kind: Job
metadata:
  name: mysql-tunnel
spec:
  template:
    spec:
      containers:
        - name: docker-ssh-tunnel
          image: cagataygurturk/docker-ssh-tunnel
          env:
            - name: SSH_DEBUG
              value: "-v"
            - name: TUNNEL_HOST
              value: mysql-tunnel
            - name: REMOTE_HOST
              value: tunneled-sql.corporate.internal.tld
            - name: LOCAL_PORT
              value: "3306"
            - name: REMOTE_PORT
              value: "3306"
          volumeMounts:
            - name: config-volume
              readOnly: true
              mountPath: /root/ssh/config
              subPath: config
            - name: secret-volume
              readOnly: true
              mountPath: /root/ssh/id_rsa
              subPath: ssh-privatekey
        - name: mariadb
          image: mariadb:10.2
          command:
            - mysql
            - -h
            - 127.0.0.1
            - -P
            - "3306"
            - -uUSERNAME
            - -pPASSWORD
            - -e SHOW databases;
      volumes:
        - name: config-volume
          configMap:
            name: ssh-config
        - name: secret-volume
          secret:
            secretName: ssh-key-secret
      restartPolicy: OnFailure
  backoffLimit: 4
````
