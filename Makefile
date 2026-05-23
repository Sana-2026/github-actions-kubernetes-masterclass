CLUSTER        ?= skillpulse
NAMESPACE      ?= skillpulse
BACKEND_IMAGE  ?= trainwithshubham/skillpulse-backend:latest
FRONTEND_IMAGE ?= trainwithshubham/skillpulse-frontend:latest

.PHONY: up down build load push apply status logs mysql restart help

up: ## One-shot: build images, create cluster (if needed), load images, apply manifests
	$(MAKE) build
	@if kind get clusters 2>/dev/null | grep -q "^$(CLUSTER)$$"; then \
		echo "Cluster '$(CLUSTER)' already exists — skipping create."; \
	else \
		kind create cluster --config k8s/kind-config.yaml --name $(CLUSTER); \
	fi
	$(MAKE) load
	$(MAKE) apply
	@echo
	@echo "  SkillPulse is live at http://localhost:8888"
	@echo

build: ## Build backend + frontend images for the host's architecture
	docker build -t $(BACKEND_IMAGE)  ./backend
	docker build -t $(FRONTEND_IMAGE) ./frontend

load: ## Push built images into the kind node (local cluster only)
	kind load docker-image $(BACKEND_IMAGE)  --name $(CLUSTER)
	kind load docker-image $(FRONTEND_IMAGE) --name $(CLUSTER)

push: ## Push images to Docker Hub (requires docker login)
	docker push $(BACKEND_IMAGE)
	docker push $(FRONTEND_IMAGE)

apply: ## Apply all manifests and wait for rollouts
	kubectl apply -f k8s/00-namespace.yaml \
	              -f k8s/10-mysql.yaml \
	              -f k8s/20-backend.yaml \
	              -f k8s/30-frontend.yaml
	kubectl rollout status statefulset/mysql    -n $(NAMESPACE) --timeout=180s
	kubectl rollout status deployment/backend   -n $(NAMESPACE) --timeout=120s
	kubectl rollout status deployment/frontend  -n $(NAMESPACE) --timeout=60s

down: ## Delete the kind cluster
	kind delete cluster --name $(CLUSTER)

status: ## Quick health snapshot of all resources
	@kubectl get pods,svc,endpoints -n $(NAMESPACE)

logs: ## Tail all three workloads at once
	@kubectl logs -n $(NAMESPACE) -l 'app in (mysql,backend,frontend)' \
		--all-containers --tail=50 -f --max-log-requests=10

mysql: ## Open a mysql shell into the StatefulSet pod
	kubectl exec -it -n $(NAMESPACE) mysql-0 -- \
		mysql -uskillpulse -pskillpulse123 skillpulse

restart: ## Rebuild + reload images, roll backend + frontend
	$(MAKE) build
	$(MAKE) load
	kubectl rollout restart deployment/backend deployment/frontend -n $(NAMESPACE)
	kubectl rollout status  deployment/backend  -n $(NAMESPACE) --timeout=120s
	kubectl rollout status  deployment/frontend -n $(NAMESPACE) --timeout=60s

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
