#!/bin/bash

# Update system packages
apt-get update -y

# Install git, python3-pip, and postgresql-client
apt-get install -y git python3-pip python3-venv postgresql-client-12

# Clone the Django application
cd /home/ubuntu
git clone ${git_repo_url} django-app
cd django-app/myproject

# Parse database URL and create environment variables
DB_URL="${database_url}"
DB_HOST=$(echo $DB_URL | sed 's/.*@\([^:]*\):.*/\1/')
DB_NAME=$(echo $DB_URL | sed 's/.*\/\([^?]*\).*/\1/')
DB_USER=$(echo $DB_URL | sed 's/.*:\/\/\([^:]*\):.*/\1/')
DB_PASSWORD=$(echo $DB_URL | sed 's/.*:\/\/[^:]*:\([^@]*\)@.*/\1/')

# Create a .env file with all configuration
cat > .env << EOF
REDIS_URL=${redis_url}
DB_HOST=$DB_HOST
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_PORT=5432
SERVER_ID=${server_id}
EOF

# For Celery worker, add multiple database URLs
if [ "${server_role}" = "celery" ]; then
    echo "DB_URLS=${database_urls}" >> .env
fi

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip3 install -r requirements.txt

# Load environment variables and run Django database migrations
export $(cat .env | xargs)
python3 manage.py migrate

# Role-based logic
if [ "${server_role}" = "web" ]; then
    # Start the web application using gunicorn
    echo "Starting Django web server with gunicorn..."
    nohup bash -c "export \$(cat .env | xargs); gunicorn --bind 0.0.0.0:80 myproject.wsgi:application" > /var/log/gunicorn.log 2>&1 &
elif [ "${server_role}" = "celery" ]; then
    # Start the Celery worker process
    echo "Starting Celery worker..."
    nohup bash -c "export \$(cat .env | xargs); celery -A myproject worker --loglevel=info" > /var/log/celery.log 2>&1 &
fi

# Log the startup completion
echo "Server setup completed for role: ${server_role}" >> /var/log/setup.log