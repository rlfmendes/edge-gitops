#!/bin/sh

####### do not change these values #######
export AKDC_ME=akdc
export AKDC_FQDN="bartr-central.cseretail.com"
export AKDC_DEBUG="false"
export AKDC_DAPR="false"
export AKDC_REPO="retaildevcrews/edge-gitops"
export AKDC_BRANCH="bartr"
export AKDC_CLUSTER="bartr-central"
export AKDC_ARC_ENABLED="false"
export AKDC_RESOURCE_GROUP="bartr-central"
export AKDC_DO="false"
export AKDC_ZONE="cseretail.com"
export AKDC_DNS_RG="tld"
export AKDC_FLEET_BRANCH="main"

###################################

export DEBIAN_FRONTEND=noninteractive
export HOME=/root

### Needed for Digital Ocean
if [ "$AKDC_DO" = "true" ]
then
  useradd -m -s /bin/bash ${AKDC_ME}
  mkdir -p /home/${AKDC_ME}/.ssh
  cp /root/.ssh/authorized_keys /home/${AKDC_ME}/.ssh

  # disable login
  cd /home/${AKDC_ME}/.ssh || exit
  mv authorized_keys ak

  # extract the values to files in .ssh
  #shellcheck disable=2002
  cat ak | grep SP_NAME | cut -f4 -d ' ' | base64 -d > sp_name
  #shellcheck disable=2002
  cat ak | grep SP_KEY | cut -f4 -d ' ' | base64 -d > sp_key
  #shellcheck disable=2002
  cat ak | grep SP_TENANT | cut -f4 -d ' ' | base64 -d > sp_tenant

  # remove the SP_* from authorized keys
#  cat ak | grep -v SP_ > authorized_keys
#  rm -f ak
  mv ak authorized_keys

  # chmod or remove the SP_* files
  chmod 600 ~/.ssh/sp_*

  cd ..
fi

cp /usr/share/zoneinfo/America/Chicago /etc/localtime

cd /home/${AKDC_ME} || exit

echo "$(date +'%Y-%m-%d %H:%M:%S')  starting" >> status

echo "${AKDC_ME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/akdc

touch .sudo_as_admin_successful

# upgrade sshd security
{
  echo ""
  echo "ClientAliveInterval 120"
  echo "Port 2222"
  echo "Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr"
} >> /etc/ssh/sshd_config

# restart sshd
systemctl restart sshd

# make some directories we will need
mkdir -p .ssh
mkdir -p .kube
mkdir -p bin
mkdir -p .local/bin
mkdir -p .k9s
mkdir -p .oh-my-bash/completions
mkdir -p /root/.kube

# configure git CLI
git config --system user.name autogitops
git config --system user.email autogitops@outlook.com
git config --system core.whitespace blank-at-eol,blank-at-eof,space-before-tab
git config --system pull.rebase false
git config --system init.defaultbranch main
git config --system fetch.prune true
git config --system core.pager more

# oh my bash
git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git .oh-my-bash
cp .oh-my-bash/templates/bashrc.osh-template .bashrc

# add to /etc/bash.bashrc
# shellcheck disable=2016
{
  echo ""
  echo "shopt -s expand_aliases"
  echo ""
  echo "alias k='kubectl'"
  echo "alias kga='kubectl get all'"
  echo "alias kgaa='kubectl get all --all-namespaces'"
  echo "alias kaf='kubectl apply -f'"
  echo "alias kdelf='kubectl delete -f'"
  echo "alias kl='kubectl logs'"
  echo "alias kccc='kubectl config current-context'"
  echo "alias kcgc='kubectl config get-contexts'"
  echo "alias kj='kubectl exec -it jumpbox -- bash -l'"
  echo "alias kje='kubectl exec -it jumpbox -- '"

  echo ""
  echo 'export PATH="$PATH:$HOME/bin:$HOME/fleet-vm/bin"'
  echo "export AKDC_CLUSTER=$AKDC_CLUSTER"
  echo "export AKDC_BRANCH=$AKDC_BRANCH"
  echo "export AKDC_REPO=$AKDC_REPO"
  echo "export AKDC_FQDN=$AKDC_FQDN"
  echo "export AKDC_DEBUG=$AKDC_DEBUG"
  echo "export AKDC_ARC_ENABLED=$AKDC_ARC_ENABLED"
  echo "export AKDC_RESOURCE_GROUP=$AKDC_RESOURCE_GROUP"
  echo "export AKDC_ZONE=$AKDC_ZONE"
  echo "export AKDC_DNS_RG=$AKDC_DNS_RG"

  echo ""
  echo "source <(kic completion bash)"
  echo 'complete -F __start_kubectl k'
} >> /etc/bash.bashrc

# source .bashrc for non-interactive logins
sed -i "s/\[ -z \"\$PS1\" ] && return//" /etc/bash.bashrc

chown -R ${AKDC_ME}:${AKDC_ME} /home/${AKDC_ME}

# make some system dirs
mkdir -p /etc/docker
mkdir -p /prometheus && chown -R 65534:65534 /prometheus
mkdir -p /grafana
# cp /workspaces/.cnp-labs/cluster-admin/deploy/grafanadata/grafana.db /grafana
chown -R 472:0 /grafana

# create / add to groups
groupadd docker
usermod -aG sudo ${AKDC_ME}
usermod -aG admin ${AKDC_ME}
usermod -aG docker ${AKDC_ME}
gpasswd -a ${AKDC_ME} sudo

echo "$(date +'%Y-%m-%d %H:%M:%S')  flux retries:" >> status

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing base" >> status
apt-get update
apt-get install -y apt-utils dialog apt-transport-https ca-certificates net-tools

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing libs" >> status
apt-get install -y software-properties-common libssl-dev libffi-dev python-dev build-essential lsb-release gnupg-agent

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing utils" >> status
apt-get install -y curl git wget nano jq zip unzip httpie
apt-get install -y dnsutils coreutils gnupg2 make bash-completion gettext iputils-ping

echo "$(date +'%Y-%m-%d %H:%M:%S')  adding package sources" >> status

# add Docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# add kubenetes repo
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" > /etc/apt/sources.list.d/kubernetes.list

# add az cli repo
curl -sL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /etc/apt/trusted.gpg.d/microsoft.gpg
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/azure-cli.list

apt-get update

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing az cli" >> /home/akdc/status
apt-get install -y azure-cli

echo "$(date +'%Y-%m-%d %H:%M:%S')  az login start" >> /home/akdc/status
if [ "$AKDC_DO" = "true" ]
then
  # login to Azure using the SP
  az login --service-principal --username "$(cat .ssh/sp_name)" --tenant "$(cat .ssh/sp_tenant)" --password "$(cat .ssh/sp_key)" -o table
  sudo -HEu akdc az login --service-principal --username "$(cat .ssh/sp_name)" --tenant "$(cat .ssh/sp_tenant)" --password "$(cat .ssh/sp_key)" -o table
else
  az login --identity -o table
  sudo -HEu akdc az login --identity -o table
fi

#shellcheck disable=2181
if [ "$?" != 0 ]
then
    echo "$(date +'%Y-%m-%d %H:%M:%S')  Azure login failed" >> /home/akdc/status
    echo "Azure login failed"
    exit 1
fi

echo "$(date +'%Y-%m-%d %H:%M:%S')  $(az account show -o tsv --query 'user.name')" >> /home/akdc/status

# save secrets
az keyvault secret show --vault-name kv-tld  --query 'value' -o tsv -n akdc-pat > /home/akdc/.ssh/akdc.pat
az keyvault secret show --vault-name kv-tld  --query 'value' -o tsv -n cse-retail-crt > /home/akdc/.ssh/certs.pem
az keyvault secret show --vault-name kv-tld  --query 'value' -o tsv -n cse-retail-key > /home/akdc/.ssh/certs.key
az keyvault secret show --vault-name kv-tld  --query 'value' -o tsv -n red-fluent-bit-secret > /home/akdc/.ssh/fluent-bit.key
az keyvault secret show --vault-name kv-tld  --query 'value' -o tsv -n red-prometheus-secret > /home/akdc/.ssh/prometheus.key

echo "$(date +'%Y-%m-%d %H:%M:%S')  az login complete" >> /home/akdc/status

if [ ! -f .ssh/akdc.pat ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  akdc.pat not found" >> status
  echo "akdc.pat not found"
  exit 1
fi

# change ownership
chown -R ${AKDC_ME}:${AKDC_ME} /home/${AKDC_ME}

echo "$(date +'%Y-%m-%d %H:%M:%S')  cloning GitHub repos" >> status
# run as akdc user
sudo -HEu akdc git clone "https://$(cat .ssh/akdc.pat)@github.com/$AKDC_REPO" gitops
sudo -HEu akdc git clone "https://$(cat .ssh/akdc.pat)@github.com/retaildevcrews/fleet-vm"
sudo -HEu akdc git -C fleet-vm checkout $AKDC_FLEET_BRANCH

# checkout the branch
if [ "$AKDC_BRANCH" != "main" ]
then
  git -C gitops checkout $AKDC_BRANCH
fi

# change ownership
chown -R ${AKDC_ME}:${AKDC_ME} /home/${AKDC_ME}

if [ ! -d fleet-vm/setup ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  git clone failed" >> status
  echo "git clone failed"
  exit 1
fi

echo "$(date +'%Y-%m-%d %H:%M:%S')  creating DNS entry" >> status

if [ "$AKDC_DO" = "true" ]
then
  # get the public IP
  pip="$(ip -4 a show eth0 | grep inet | sed "s/inet//g" | sed "s/ //g" | cut -d / -f 1 | grep -v '10\.')"
else
  # get the public IP
  pip=$(az network public-ip show -g "$AKDC_RESOURCE_GROUP" -n "${AKDC_CLUSTER}publicip" --query ipAddress -o tsv)
fi
echo "$(date +'%Y-%m-%d %H:%M:%S')  Public IP: $pip" >> status
echo "Public IP: $pip"

# get the old IP
old_ip=$(az network dns record-set a list \
--query "[?name=='$AKDC_CLUSTER'].{IP:aRecords}" \
--resource-group $AKDC_DNS_RG \
--zone-name "$AKDC_ZONE" \
-o json | jq -r '.[].IP[].ipv4Address' | tail -n1)

# delete old DNS entry if exists
if [ "$old_ip" != "" ] && [ "$old_ip" != "$pip" ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  deleting old DNS entry old: $old_ip pip: $pip" >> status

  # delete the old DNS entry
  az network dns record-set a remove-record \
  -g $AKDC_DNS_RG \
  -z "$AKDC_ZONE" \
  -n $AKDC_CLUSTER \
  -a "$old_ip" -o table
fi

# create DNS record
az network dns record-set a add-record \
-g "$AKDC_DNS_RG" \
-z "$AKDC_ZONE" \
-n "$AKDC_CLUSTER" \
-a "$pip" \
--ttl 10 -o table

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing docker" >> status
apt-get install -y docker-ce docker-ce-cli

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing kubectl" >> status
apt-get install -y kubectl

# kubectl auto complete
kubectl completion bash > /etc/bash_completion.d/kubectl

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing k3d" >> status
wget -q -O - https://raw.githubusercontent.com/rancher/k3d/main/install.sh | TAG=v4.4.8 bash

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing flux" >> status
curl -s https://fluxcd.io/install.sh | bash
flux completion bash > /etc/bash_completion.d/flux

echo "$(date +'%Y-%m-%d %H:%M:%S')  installing k9s" >> status
VERSION=$(curl -i https://github.com/derailed/k9s/releases/latest | grep "location: https://github.com/" | rev | cut -f 1 -d / | rev | sed 's/\r//')
wget "https://github.com/derailed/k9s/releases/download/${VERSION}/k9s_Linux_x86_64.tar.gz"
tar -zxvf k9s_Linux_x86_64.tar.gz -C /usr/local/bin
rm -f k9s_Linux_x86_64.tar.gz

# upgrade Ubuntu
echo "$(date +'%Y-%m-%d %H:%M:%S')  upgrading" >> status
apt-get update

# skip the upgrade if debugging
if [ "$AKDC_DEBUG" != "true" ]
then
  apt-get upgrade -y
  apt-get autoremove -y
fi

echo "$(date +'%Y-%m-%d %H:%M:%S')  creating registry" >> status
# create local registry
chown -R ${AKDC_ME}:${AKDC_ME} /home/${AKDC_ME}
docker network create k3d
k3d registry create registry.localhost --port 5500
docker network connect k3d k3d-registry.localhost

# can't continue without k3d-setup.sh
if [ ! -f ./fleet-vm/setup/k3d-setup.sh ]
then
  echo "$(date +'%Y-%m-%d %H:%M:%S')  k3d-setup.sh not found" >> status
  echo "k3d-setup.sh not found"
  exit 1
fi

echo "$(date +'%Y-%m-%d %H:%M:%S')  running scripts" >> status

# run akdc-pre-k3d.sh
if [ -f ./fleet-vm/setup/akdc-pre-k3d.sh ]
then
  # run as AKDC_ME
  sudo -HEu akdc ./fleet-vm/setup/akdc-pre-k3d.sh || exit 1
fi

# run k3d-setup
if [ -f ./fleet-vm/setup/k3d-setup.sh ]
then
  sudo -HEu akdc ./fleet-vm/setup/k3d-setup.sh || exit 1
fi

# run akdc-pre-flux.sh
if [ -f ./fleet-vm/setup/akdc-pre-flux.sh ]
then
  sudo -HEu akdc ./fleet-vm/setup/akdc-pre-flux.sh || exit 1
fi

# setup flux
if [ -f ./fleet-vm/setup/flux-setup.sh ]
then
  sudo -HEu akdc ./fleet-vm/setup/flux-setup.sh || exit 1
fi

# run akdc-pre-arc.sh
if [ -f ./fleet-vm/setup/akdc-pre-arc.sh ]
then
  sudo -HEu akdc ./fleet-vm/setup/akdc-pre-arc.sh || exit 1
fi

# configure azure arc
if [ -f ./fleet-vm/setup/arc-setup.sh ]
then
  sudo -HEu akdc ./fleet-vm/setup/arc-setup.sh || exit 1
fi

# run akdc-post.sh
if [ -f ./fleet-vm/setup/akdc-post.sh ]
then
  sudo -HEu akdc ./fleet-vm/setup/akdc-post.sh || exit 1
fi

echo "$(date +'%Y-%m-%d %H:%M:%S')  complete" >> status
echo "complete" >> status
