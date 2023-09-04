# flexi training environment

This repo sets up a training environment using Open OnDemand within the FlexiHPC platform using Terraform and Ansible.

[Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli) and
[Ansible](https://www.ansible.com/) need to be installed on your system to run this.

## Configure terraform

Set some variables via environment variables:

```
export TF_VAR_key_pair="FLEXIHPC_KEYPAIR_NAME"
export TF_VAR_key_file="/path/to/flexi/private_key"
export TF_VAR_vm_user="ubuntu"
```

where

- `FLEXIHPC_KEYPAIR_NAME` is your `Key Pair` name that is setup in FlexiHPC
- `/path/to/flexi/private_key` is the local path to the private key

Set environment variables for authenticating with OpenStack and object store (for the state file), e.g.

```
export OS_USERNAME="FLEXIHPC_USER"
export OS_PASSWORD="FLEXIHPC_PASSWORD"
export AWS_ACCESS_KEY_ID="EC2_User_Access_Token"
export AWS_SECRET_KEY="EC2_User_Secret_Token"
```

where

- `FLEXIHPC_USER` is set to your username for the FlexiHPC Platform
- `FLEXIHPC_PASSWORD` is set to your password for the FlexiHPC Platform
- `EC2_User_Access_Token` is set to your EC2 access token
- `EC2_User_Secret_Token` is set to your EC2 secret token

If you don't have any EC2 credentials then use the following CLI command to generate new ones:

```
openstack ec2 credentials create
```

## Configure ansible

Install dependencies:

```
ansible-galaxy install -r requirements.yml
```

Copy example secrets file and edit:

```
cp vars/secrets.yml.example vars/secrets.yml
```

Copy ondemand config:

```
cp vars/ondemand-config.yml.example vars/ondemand-config.yml
```

and edit, in particular set `oidc_settings.OIDCCryptoPassphrase` with a randomly
generated password, e.g. the output of `openssl rand -hex 40`.

## Note about terraform workspaces

The terraform workspace must have already been created before running the below command.
This will always be the case for the "default" workspace but if you want to create another
workspace you should do it manually by running:

```
cd terraform
terraform init
terraform workspace select -or-create=true <workspace_name>
```

Then continuing with the `ansible-playbook` command below, substituting in the name
of your workspace instead of "default".

## Destroy environment

To destroy a previously created environment run:

```
ansible-playbook setup-infra.yml -e operation=destroy -e terraform_workspace=default
```

## Create the environment

First, create the terraform resources:

```
ansible-playbook setup-infra.yml -e operation=create -e terraform_workspace=default
```

Then configure the environment:

```
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook -i host.ini -u ubuntu --key-file ~/.ssh/flexi-private-key setup-training-environment.yml
```

By default 2 users will be created, `training1` and `training2`. Passwords for these users will be
stored in the *users* sub-directory:

```
$ ls users/
password_training1.txt  password_training2.txt
```

More users can be added by overriding the `num_users_create` variable, e.g.

```
ansible-playbook -i host.ini -u ubuntu --key-file ~/.ssh/flexi-private-key \
    --extra-vars "num_users_create=5" setup-training-environment.yml
```

You will need to modify your hosts file with the IP addresses from *host.ini*, on Linux this file is
*/etc/hosts*, on Windows it is XXXX.

```
# /etc/hosts snippet

# this one should be the IP for webnode from host.ini
1.2.3.4 ood.flexi.nesi

# this one should be the IP for servicesnode from host.ini
5.6.7.8 ood-idp.flexi.nesi
```

Connect via [https://ood.flexi.nesi](https://ood.flexi.nesi).
