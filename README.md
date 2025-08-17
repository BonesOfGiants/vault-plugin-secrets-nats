[contributors-shield]: https://img.shields.io/github/contributors/edgefarm/vault-plugin-secrets-nats.svg?style=for-the-badge
[contributors-url]: https://github.com/edgefarm/vault-plugin-secrets-nats/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/edgefarm/vault-plugin-secrets-nats.svg?style=for-the-badge
[forks-url]: https://github.com/edgefarm/vault-plugin-secrets-nats/network/members
[stars-shield]: https://img.shields.io/github/stars/edgefarm/vault-plugin-secrets-nats.svg?style=for-the-badge
[stars-url]: https://github.com/edgefarm/vault-plugin-secrets-nats/stargazers
[issues-shield]: https://img.shields.io/github/issues/edgefarm/vault-plugin-secrets-nats.svg?style=for-the-badge
[issues-url]: https://github.com/edgefarm/vault-plugin-secrets-nats/issues
[license-shield]: https://img.shields.io/github/license/edgefarm/vault-plugin-secrets-nats?style=for-the-badge
[license-url]: https://opensource.org/license/mpl-2-0

[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MPL-2.0 License][license-shield]][license-url]

<!-- PROJECT LOGO -->
<br />
<p align="center">
  <a href="https://github.com/edgefarm/vault-plugin-secrets-nats">
    <img src="https://github.com/edgefarm/edgefarm/raw/beta/.images/EdgefarmLogoWithText.png" alt="Logo" height="112">
  </a>

  <h2 align="center">vault-plugin-secrets-nats (Enhanced Fork)</h2>

  <p align="center">
    Enhanced Hashicorp Vault plugin with dynamic JWT generation and templating for NATS secrets.
    <br />
    <strong>Fork of <a href="https://github.com/edgefarm/vault-plugin-secrets-nats">edgefarm/vault-plugin-secrets-nats</a></strong>
  </p>
  <hr />
</p>

# About This Fork

This is an enhanced fork of the [edgefarm/vault-plugin-secrets-nats](https://github.com/edgefarm/vault-plugin-secrets-nats) project that adds powerful new features for dynamic JWT generation and templating:

## 🚀 New Features

### 1. Dynamic JWT Generation with Expiration Control

Instead of generating JWTs at issue creation time, this fork introduces **on-demand JWT generation** with configurable expiration:

- **Configurable Expiration**: Set `expirationS` in seconds when creating user issues
- **Fresh JWTs**: Each credential request generates a new JWT with current timestamp
- **Flexible Expiry**: Set to 0 or omit for infinite expiration (default behavior)

### 2. JWT Claims Templating

Create **parameterized JWT templates** with placeholder variables that get substituted at credential generation time:

- **Template Variables**: Use `{{variable_name}}` syntax in claims
- **Runtime Substitution**: Provide parameters when reading credentials
- **Fine-grained Scoping**: Generate tokens scoped to specific users, regions, or any custom context

## 🆕 Enhanced Workflow

### Traditional Approach (Original)
```bash
# Create user issue → JWT generated immediately and stored
vault write nats-secrets/issue/operator/myop/account/myaccount/user/myuser claims='{...}'

# Read credentials → Return pre-generated JWT
vault read nats-secrets/creds/operator/myop/account/myaccount/user/myuser
```

### New Dynamic Approach
```bash
# Create user template with expiration and variables
vault write nats-secrets/issue/operator/myop/account/myaccount/user/myuser \
  expirationS=3600 \
  claimsTemplate='{
    "aud": "{{user_id}}",
    "nats": {
      "pub": {"allow": ["{{region}}.{{user_id}}.>"]},
      "sub": {"allow": ["{{region}}.{{user_id}}.*"]}
    }
  }'

# Generate fresh, scoped credentials on-demand
vault read nats-secrets/creds/operator/myop/account/myaccount/user/myuser \
  parameters='{"user_id": "user123", "region": "us-east-1"}'
```

# 📋 Quick Start Examples

## Basic Dynamic JWT with Expiration

```bash
# Create a user template with 1-hour expiration
vault write nats-secrets/issue/operator/myop/account/myaccount/user/shortlived \
  expirationS=3600 \
  claimsTemplate='{
    "nats": {
      "pub": {"allow": ["app.>"]},
      "sub": {"allow": ["app.>"]}
    }
  }'

# Generate fresh credentials (valid for 1 hour from now)
vault read nats-secrets/creds/operator/myop/account/myaccount/user/shortlived
```

## Advanced Templating with Parameters

```bash
# Create a parameterized template for multi-tenant application
vault write nats-secrets/issue/operator/myop/account/myaccount/user/appclient \
  expirationS=1800 \
  claimsTemplate='{
    "aud": "{{tenant_id}}",
    "nats": {
      "pub": {
        "allow": ["tenant.{{tenant_id}}.{{service}}.out.>"],
        "deny": ["tenant.{{tenant_id}}.admin.>"]
      },
      "sub": {
        "allow": ["tenant.{{tenant_id}}.{{service}}.in.>"]
      }
    }
  }'

# Generate credentials for specific tenant and service
vault read nats-secrets/creds/operator/myop/account/myaccount/user/appclient \
  parameters='{"tenant_id": "acme-corp", "service": "api"}'

# Generate credentials for different context
vault read nats-secrets/creds/operator/myop/account/myaccount/user/appclient \
  parameters='{"tenant_id": "widgets-inc", "service": "worker"}'
```

## Parameter Formats

You can provide parameters in two formats:

### JSON Format
```bash
vault read nats-secrets/creds/operator/op/account/acc/user/user \
  parameters='{"user_id": "12345", "region": "us-west-2"}'
```

### Key-Value Format
```bash
vault read nats-secrets/creds/operator/op/account/acc/user/user \
  parameters="user_id=12345,region=us-west-2"
```

---

# About The Original Project

The original `vault-plugin-secrets-nats` is a Hashicorp Vault plugin that extends Vault with a secrets engine for [NATS](https://nats.io) for Nkey/JWT auth. It is capable of generating NATS credentials for operators, accounts and users, with the ability to push generated credentials to a NATS account server.

## Features

- **Dynamic JWT Generation**: Generate fresh JWTs on-demand with configurable expiration
- **Claims Templating**: Parameterize JWT claims for fine-grained access control
- Manage NATS nkey and jwt for operators, accounts and users
- Give access to user creds files
- Push generated credentials to a NATS account server

# Getting Started

The `nats` secrets engine generates NATS credentials dynamically. The plugin supports several resources, including: operators, accounts, users, NKeys, and creds, as well as signing keys for operators and accounts.

Please read the official [NATS documentation](https://docs.nats.io/running-a-nats-service/configuration/securing_nats/auth_intro/jwt) to understand the concepts of operators, accounts and users as well as the authentication process.

## Resource Overview

The resource of type `issue` represent entities that result in generation of nkey and JWT templates.

| Entity path                                                   | Description                                                                        | Operations          |
| ------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------- |
| issue/operator                                                | List operator issues                                                               | list                |
| issue/operator/\<operator\>/account                           | List account issues                                                                | list                |
| issue/operator/\<operator\>/account/\<account\>/user          | List user issues within an account                                                 | list                |
| issue/operator/\<operator\>                                   | Manage operator issues. See the `operator` section for more information.           | write, read, delete |
| issue/operator/\<operator\>/account/\<account\>               | Manage account issues. See the `account` section for more information.             | write, read, delete |
| issue/operator/\<operator\>/account/\<account\>/user/\<name\> | Manage user templates within an account. See the `user` section for more information. | write, read, delete |

The resources of type `creds` represent user credentials that are generated on-demand from templates.

| Entity path                                                 | Description              | Operations          |
| ----------------------------------------------------------- | ------------------------ | ------------------- |
| creds/operator/\<operator>account/\<account\>/user          | List user cred templates | List                |
| creds/operator/\<operator>account/\<account\>/user/\<user\> | Generate fresh user creds | read               |

Resources of type `nkey` are either generated by `issue`s or imported and referenced by `issue`s during their creation.

| Entity path                                                  | Description                    | Operations          |
| ------------------------------------------------------------ | ------------------------------ | ------------------- |
| nkey/operator                                                | List operator nkeys            | list                |
| nkey/operator/\<operator>/signing                            | List operators' signing nkeys  | list                |
| nkey/operator/\<operator>/account                            | List account nkeys             | list                |
| nkey/operator/\<operator>/account/\<account\>/signing        | List accounts' signing nkeys   | list                |
| nkey/operator/\<operator>/account/\<account\>/user           | List user nkeys                | list                |
| nkey/operator/\<operator>                                    | Manage operator nkey           | write, read, delete |
| nkey/operator/\<operator>/signing/\<key\>                    | Manage operator signing nkeys  | write, read, delete |
| nkey/operator/\<operator>account/\<account\>                 | Manage accounts' nkey          | write, read, delete |
| nkey/operator/\<operator>account/\<account\>/signing/\<key\> | Manage accounts' signing nkeys | write, read, delete |
| nkey/operator/\<operator>account/\<account\>/user/\<user\>   | Manage user nkey               | write, read, delete |

## ⚙️ Configuration

### User Issues (Enhanced)

| Key             | Type        | Required | Default | Description                                                                                                              |
| --------------- | ----------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| useSigningKey   | string      | false    | ""      | Account signing key's name, e.g. "opsk1"                                                                                |
| claimsTemplate  | json object | false    | {}      | JWT claims template with optional `{{variables}}`. See [pkg/claims/user/v1alpha1/api.go](pkg/claims/user/v1alpha1/api.go) |
| expirationS     | int64       | false    | 0       | JWT expiration time in seconds from generation time. 0 = infinite expiration                                            |

### User Credentials (Enhanced)

| Key        | Type   | Required | Default | Description                                                 |
| ---------- | ------ | -------- | ------- | ----------------------------------------------------------- |
| parameters | string | false    | ""      | Template parameters for variable substitution (JSON or key=value format) |

#### **Operator**

| Key               | Type        | Required | Default | Description                                                                                                              |
| ----------------- | ----------- | -------- | ------- | ------------------------------------------------------------------------------------------------------------------------ |
| syncAccountServer | bool        | false    | false   | If set to true, the plugin will push the generated credentials to the configured account server.                         |
| claims            | json string | false    | {}      | Claims to be added to the operator's JWT. See [pkg/claims/operator/v1alpha1/api.go](pkg/claims/operator/v1alpha1/api.go) |

#### **Account**

| Key           | Type        | Required | Default | Description                                                                                                           |
| ------------- | ----------- | -------- | ------- | --------------------------------------------------------------------------------------------------------------------- |
| useSigningKey | string      | false    | ""      | Operator signing key's name, e.g. "opsk1"                                                                             |
| claims        | json string | false    | {}      | Claims to be added to the account's JWT. See [pkg/claims/account/v1alpha1/api.go](pkg/claims/account/v1alpha1/api.go) |

### Nkey

| Key  | Type   | Required | Default | Description                                           |
| ---- | ------ | -------- | ------- | ----------------------------------------------------- |
| seed | string | false    | ""      | Seed to import. If not set, then a new one is created |

### 📤 System account specific configuration

This section describes the configuration options that are specific to the system account.

The default name of the system account is `sys`. If you want to use a different name, you can set the `systemAccount` configuration option in the `operator`. 
Within the `sys` account the only user that is capable of pushing credentials to the account server is the `default-push` user. 

See the `example/sysaccount` directory for an example configuration of both `sys` account and `default-push` user.

## 🎯 Installation and Setup

### Development Environment

This project includes a Nix flake for easy development setup:

```bash
# Enter development shell
nix develop

# Or use direnv for automatic activation
echo "use flake" > .envrc
direnv allow
```

**Available tools in dev environment:**
- Go (latest)
- Vault
- Docker
- Make
- Just (task runner)

### Using Just for Development

This project uses [Just](https://github.com/casey/just) as a task runner. See available commands:

```bash
just --list
```

**Quick development workflow:**
```bash
# Start Vault in dev mode with plugin
just start

# Or step by step:
just clean              # Clean build artifacts
just build              # Build the plugin
just start-vault        # Start Vault in dev mode
just enable-plugin      # Register and enable plugin
just create-demo        # Create demo operator, account, and user
```

### Install from release

Download the latest stable release from the [release](https://github.com/edgefarm/vault-plugin-secrets-nats/releases) page and put it into the `plugins_directory` of your vault server.

To use a vault plugin you need the plugin's sha256 sum. You can download the file `vault-plugin-secrets-nats.sha256` file from the release, obtain it with `sha256sum vault-plugin-secrets-nats` or look within the OCI image at `/etc/vault/vault_plugins_checksums/vault-plugin-secrets-nats.sha256`.

Example how to register the plugin:

```bash
SHA256SUM=$(sha256sum vault-plugin-secrets-nats | cut -d' ' -f1)
vault plugin register -sha256 ${SHA256SUM} secret vault-plugin-secrets-nats
vault secrets enable -path=nats-secrets vault-plugin-secrets-nats
```

**Note: you might use the `-tls-skip-verify` flag if you are using a self-signed certificate.**

### Install from OCI image using bank-vaults in Kubernetes

This project provides a custom built `vault` OCI image that includes the `vault-plugin-secrets-nats` plugin. See [here]() for available versions.
The `plugins_directory` must be set to `/etc/vault/vault_plugins` in the `vault` configuration.

This describes the steps to install the plugin using the `bank-vaults` operator. See [here](https://banzaicloud.com/docs/bank-vaults/operator/) for more information.
Define the custom `vault` image in the `Vault` custom resource and configure 

```yaml
apiVersion: "vault.banzaicloud.com/v1alpha1"
kind: "Vault"
metadata:
  name: "myVault"
spec:
  size: 1
  # Use the custom vault image containing the NATS secrets plugin
  image: ghcr.io/edgefarm/vault-plugin-secrets-nats/vault-with-nats-secrets:1.7.1
  config:
    disable_mlock: true
    plugin_directory: "/etc/vault/vault_plugins"
    listener:
      tcp:
        address: "0.0.0.0:8200"
    api_addr: "https://0.0.0.0:8200"
  externalConfig:
    plugins:
    - plugin_name: vault-plugin-secrets-nats
      command: vault-plugin-secrets-nats --tls-skip-verify --ca-cert=/vault/tls/ca.crt
      sha256: cc4c3da9302d08d1a1e3cb63df49059a9ad29bb5285e176b8f2aa3071f5df624
      type: secret
    secrets:
    - path: nats-secrets
      type: plugin
      plugin_name: vault-plugin-secrets-nats
      description: NATS secrets backend
  # ...
```

See the full [dev/manifests/vault/vault.yaml](dev/manifests/vault/vault.yaml) for a full example of a `Vault` custom resource that can be used by the `vault-operator`.

## 🧪 Testing

To test the plugin in a production like environment you can spin up a local kind cluster that runs a production `vault` server with the plugin enabled and a NATS server the plugin writes account information to.

**Note: you need to have `kind` and `devspace` installed.**

The first step is to spin up the cluster with everything installed.

```console
# Create the cluster
$ devspace run create-kind-cluster

# Deploy initial stuff like ingress and cert-manager
$ devspace run-pipeline init 

# Deploy the vault-operator and vault instance
$ devspace run-pipeline deploy-vault

# Wait for the vault pods get ready
$ kubectl get pods -n vault 

# Check if the plugin is successfully loaded
$ kubectl port-forward -n vault svc/vault 8200:8200 &
$ PID=$!
$ export VAULT_ADDR=https://127.0.0.1:8200
$ VAULT_TOKEN=$(kubectl get secrets bank-vaults -n vault -o jsonpath='{.data.vault-root}' | base64 -d)
$ echo $VAULT_TOKEN | vault login -
$ vault secrets list
Handling connection for 8200
Path             Type                         Accessor                              Description
----             ----                         --------                              -----------
cubbyhole/       cubbyhole                    cubbyhole_ec217496                    per-token private secret storage
identity/        identity                     identity_9123b895                     identity store
nats-secrets/    vault-plugin-secrets-nats    vault-plugin-secrets-nats_d8584dcc    NATS secrets backend
sys/             system                       system_5bd0e10f                       system endpoints used for control, policy and debugging
$ pkill $PID

# Deploy the NATS server
$ devspace run-pipeline deploy-nats

# Wait for the NATS server to be ready
$ kubectl get pods -n nats
```

Once this is working create a account and a user and act as a third party that uses the creds outside the cluster.

```console
# Create the account and user and get the creds for the user
$ devspace run-pipeline create-custom-nats-account
$ kubectl port-forward -n nats svc/nats 4222:4222 &
$ PID=$!

# Publish and subscribe using the creds previously fetched
$ docker run -it -d --rm --name nats-subscribe --network host -v $(pwd)/.devspace/creds/creds:/creds natsio/nats-box:0.13.4 nats sub -s nats://localhost:4222 --creds /creds foo 
$ docker run --rm -d -it --name nats-publish --network host -v $(pwd)/.devspace/creds/creds:/creds natsio/nats-box:0.13.4 nats pub -s nats://localhost:4222 --creds /creds foo --count 3 "Message {{Count}} @ {{Time}}"

# Log output shows that authenticating with the creds file works for pub and sub
$ docker logs nats-subscribe
14:49:35 Subscribing on foo 
[#1] Received on "foo"
Message 1 @ 2:49PM

[#2] Received on "foo"
Message 2 @ 2:49PM

[#3] Received on "foo"
Message 3 @ 2:49PM

# Cleanup
$ docker kill nats-subscribe
$ pkill $PID
```

# 💡 Example

Read this section to learn how to use `vault-plugin-secrets-nats` by trying out the example. 
See the `example` directory for a full example. The example runs a locally running Vault server and a NATS server.

An operator and a sys account is created. Both are using signing keys. A sys account user called `default-push` is created 
that is used to push the credentials to the NATS account server.
The NATS server is configured to use the generated credentials.
After the NATS server is up and running a new "normal" account and a user is created and pushed to the NATS server.
The user is then able to connect to the NATS server.

Note: please make sure that you have `docker` installed as the example starts a local NATS server using docker.

## 🛠️ Setup

To use the plugin, you must first enable it with Vault. This example mounts the plugin at the path `nats-secrets`:

First run the development setup:

```console
$ just start
```

Then, enable the plugin (if not already done):

```console
$ export VAULT_ADDR='http://127.0.0.1:8200'
$ vault secrets enable -path=nats-secrets vault-plugin-secrets-nats
Success! Enabled the vault-plugin-secrets-nats secrets engine at: nats-secrets/
```

## 🏁 Enhanced Example with Dynamic JWTs

```console
$ cd examples
$ ./config.sh
> Creating NATS resources (operator and sysaccount)
Success! Data written to: nats-secrets/issue/operator/myop
Success! Data written to: nats-secrets/issue/operator/myop/account/sys
Success! Data written to: nats-secrets/issue/operator/myop/account/sys/user/default-push
> Generate NATS server config with preloaded operator and sys account settings
> Starting up NATS server
9402e7608bfe8bc391c862eb01f4dbac19e16210a431fb9d84384e009f013a3d
a5bd1e08562382aaf6b40f35203afd479bfa847fddf72a617dbd083446863071

> Creating templated user with dynamic expiration
vault write nats-secrets/issue/operator/myop/account/myaccount/user/dynamic-user \
  expirationS=3600 \
  claimsTemplate='{
    "aud": "{{client_id}}",
    "nats": {
      "pub": {"allow": ["{{tenant}}.{{service}}.out.>"]},
      "sub": {"allow": ["{{tenant}}.{{service}}.in.>"]}
    }
  }'

> Generating scoped credentials for tenant "acme" service "api"
vault read nats-secrets/creds/operator/myop/account/myaccount/user/dynamic-user \
  parameters='{"client_id": "app123", "tenant": "acme", "service": "api"}'

> Publishing using dynamic scoped creds
12:57:09 Published 3 bytes to "acme.api.out.test"
> Cleaning up...
nats
nats
> done.
```

# 🐞 Debugging

The recommended way to debug this plugin is to use write unit tests and debug them as standard go tests.
If you like to debug the plugin in a running Vault instance you can use the following steps:
  1. `just start`, this will create a vault, install the plugin and add some demo data
  2. `just read-demo-user` will then read credentials for the demo user
  3. Or you can use vault CLI to interact with the plugin
  4. Debug the plugin

  Don't forget to do `just stop` after you are done to stop the vault

# 🤝🏽 Contributing

Code contributions are very much **welcome**.

1. Fork the Project
2. Create your Branch (`git checkout -b AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature"`)
4. Push to the Branch (`git push origin AmazingFeature`)
5. Open a Pull Request targetting the `main` branch.

# 🫶 Acknowledgements

Thanks to the original [edgefarm](https://github.com/edgefarm) team for creating the foundational vault-plugin-secrets-nats.

Thanks to the NATS developers for providing a really great way of solving many problems with communication.

Also, thanks to the Vault developers for providing a great way of managing secrets and a great plugin system.