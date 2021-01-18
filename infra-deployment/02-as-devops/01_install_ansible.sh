#!/usr/bin/env bash

if [ -z "$1" ]; then
    echo "Please give the version you want in parameters" >&2
    echo "Example:"   >&2
    echo "    $0 2.9" >&2
    exit 1
fi
ansible_version="${1}"

ansible_install_dir="${HOME}/ansible"
ansible_dir="${ansible_install_dir}"/"${ansible_version}"

###############################################

# Check if a ssh key is present. If not, ask if we should create one
t=$(ls -1 "$HOME"/.ssh/id_* 2>/dev/null | wc -l 2>/dev/null)
if [ $t -eq 0 ]; then
    echo -ne "No ssh key found in $HOME/.ssh/. Creating one...\n"
    ssh-keygen -t rsa -b 4096
else
    echo "We found ssh key(s) in $HOME/.ssh/. Skipping creation"
fi

[ ! -d "${ansible_install_dir}" ] && mkdir -p "${ansible_install_dir}"
[ -e "${ansible_dir}" ] && echo "Ansible version ${ansible_version} seems to be already installed in ${ansible_dir}" >&2 && exit 1

echo "Creating venv..."
python3 -m venv "${ansible_dir}"
ret=$?
[ $ret -ne 0 ] && echo "Failed to create venv" >&2 && exit $ret

echo "Upgrading pip..."
"${ansible_dir}"/bin/pip install --upgrade pip

echo "Installing ansible ${ansible_version} and some extra packages..."
"${ansible_dir}"/bin/pip install wheel
"${ansible_dir}"/bin/pip install netaddr
"${ansible_dir}"/bin/pip install jmespath
"${ansible_dir}"/bin/pip install jsondiff
"${ansible_dir}"/bin/pip install ansible=="${ansible_version}"

if ! grep -q "^source ${ansible_dir}/bin/activate" "${HOME}/.bashrc"; then
    echo "source ${ansible_dir}/bin/activate" >> "${HOME}/.bashrc"
fi
echo -e "\nYou will want to activate ansible venv before going further! Run the following:\n"
echo -e "  source ${ansible_dir}/bin/activate\n"
exit 0

