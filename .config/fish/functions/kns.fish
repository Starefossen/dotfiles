# Defined in - @ line 1
function kns --description 'Set Kubernetes namespace: kns [namespace]'
	kubectl config set-context (kubectl config current-context) --namespace $argv[1];
end
