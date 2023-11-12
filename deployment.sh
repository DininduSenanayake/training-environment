#!/bin/bash -e

case $1 in
"destroy")
    # ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i host.ini destroy-k8s-cluster.yml \
    #     -u ${TF_VAR_vm_user} --key-file '${TF_VAR_key_file}' -e operation=destroy -e terraform_workspace=${2:-default} || true
    ansible-playbook configure-route53.yml -e operation=destroy -e terraform_workspace=${2:-default}
    ansible-playbook setup-infra.yml -e operation=destroy -e terraform_workspace=${2:-default}
    ;;
"create")
    ansible-playbook setup-infra.yml -e operation=create -e terraform_workspace=${2:-default}
    ansible-playbook -i host.ini configure-route53.yml -e operation=create -e terraform_workspace=${2:-default}
    ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i host.ini setup-training-environment.yml \
        -u ${TF_VAR_vm_user} --key-file '${TF_VAR_key_file}' -e terraform_workspace=${2:-default} \
        -e "num_users_create=${NUM_USERS:-2}"
    ;;
esac
