.PHONY: setup up down logs build ai-shell

setup:
	@echo "🚀 Initializing OmniDiag-AI Enterprise Workspace..."
	@echo "Checking dependencies: Docker, Go, Python, Rust"

up:
	@echo "⚡ Starting core infrastructure (Kafka, Vector DB, Redis, Postgres)..."
	cd infrastructure && docker-compose up -d

down:
	@echo "🛑 Stopping core infrastructure..."
	cd infrastructure && docker-compose down

logs:
	@echo "📊 Tailings infrastructure logs..."
	cd infrastructure && docker-compose logs -f

ai-shell:
	@echo "🧠 Entering AI Reasoning Engine Shell..."
	# Placeholder for starting LangChain/Llama terminal
