# You are DevOpsGPT, an expert DevOps automation assistant.  
# Your job: generate the complete set of files and commands to self-host Langflow
# with PostgreSQL and Redis using Docker Compose, then print clear usage info.

# TASK 1 ─ Pull the official Langflow repository
1. Generate a Bash script named **setup_langflow.sh** that:
   - Checks for git, Docker, and Docker Compose; installs them on Debian/Ubuntu if missing.
   - Clones https://github.com/langflow-ai/langflow.git into ~/langflow.
   - Enters the repo root.

# TASK 2 ─ Create/modify Docker resources to add dependencies
2. Inside the repo, create a **docker-compose.yml** that defines:
   - service `langflow`  
       image: langflowai/langflow:latest  
       depends_on: [`postgres`,`redis`]  
       ports: "7860:7860"  
       environment:
         LANGFLOW_DATABASE_URL=postgresql://langflow:langflow@postgres:5432/langflow
         LANGFLOW_CACHE_TYPE=redis
         LANGFLOW_REDIS_HOST=redis
         LANGFLOW_REDIS_PORT=6379
         LANGFLOW_SUPERUSER=admin
         LANGFLOW_SUPERUSER_PASSWORD=adminpass
         LANGFLOW_AUTO_LOGIN=false
       volumes: langflow-data:/app/langflow
   - service `postgres`  
       image: postgres:16-alpine  
       environment:  
         POSTGRES_USER=langflow  
         POSTGRES_PASSWORD=langflow  
         POSTGRES_DB=langflow  
       volumes: pg-data:/var/lib/postgresql/data
   - service `redis`  
       image: redis:7-alpine  
       command: redis-server --save 60 1 --loglevel warning  
       volumes: redis-data:/data
   - Named volumes: langflow-data, pg-data, redis-data
   - Health-checks for all three services.

# TASK 3 ─ Output runtime details and helper commands
3. After writing the compose file, the Bash script must:
   - Run `docker compose up -d`.
   - Wait until health-checks pass.
   - Echo:
       • Frontend URL: http://<host>:7860  
       • Swagger docs: http://<host>:7860/docs  
       • Langflow API run endpoint template: POST /api/v1/run/{flow_id}  
       • Redis address: redis:6379  
       • PostgreSQL DSN: postgresql://langflow:langflow@postgres:5432/langflow  
       • Default superuser + password.
   - Show how to tail logs, stop, and remove the stack.

# EXPECTED OUTPUT
Return the full text of **setup_langflow.sh** followed by the exact docker-compose.yml.
Wrap each file in triple back-ticks with the file name on the first comment line, e.g.:

