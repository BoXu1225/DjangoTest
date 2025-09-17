#!/bin/bash

# Update system packages
apt-get update -y

# Install git and python3-pip
apt-get install -y git python3-pip python3-venv

# Clone the Django application
cd /home/ubuntu
git clone ${git_repo_url} django-app
cd django-app/myproject

# Create a .env file with Redis URL
echo "REDIS_URL=${redis_url}" > .env

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install Python dependencies
pip3 install -r requirements.txt

# Run Django database migrations
python3 manage.py migrate

# Role-based logic
if [ "${server_role}" = "web" ]; then
    # Start the web application using gunicorn
    echo "Starting Django web server with gunicorn..."
    nohup gunicorn --bind 0.0.0.0:80 myproject.wsgi:application > /var/log/gunicorn.log 2>&1 &
elif [ "${server_role}" = "celery" ]; then
    # Start the Celery worker process
    echo "Starting Celery worker..."
    nohup celery -A myproject worker --loglevel=info > /var/log/celery.log 2>&1 &
fi

# Log the startup completion
echo "Server setup completed for role: ${server_role}" >> /var/log/setup.log