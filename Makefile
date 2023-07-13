stage = demo

export TF_WORKSPACE=$(stage)

init:
	terraform init -var-file=var-$(stage).tfvars

plan:
	terraform plan -var-file=var-$(stage).tfvars

apply:
	terraform apply -var-file=var-$(stage).tfvars

refresh:
	terraform refresh -var-file=var-$(stage).tfvars

output:
	terraform output --json

destroy:
	terraform destroy -var-file=var-$(stage).tfvars

format:
	terraform fmt

validate:
	terraform validate
