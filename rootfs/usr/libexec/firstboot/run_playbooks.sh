source playbooks.env

for playbook in $(ls playbooks)
do
  ansible-playbook ${playbook}
done