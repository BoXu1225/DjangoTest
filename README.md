# Django Celery AWS Infrastructure

This project deploys a scalable Django application with Celery task processing on AWS using Terraform.

## Architecture

- **2 Web Servers**: Each running Django with Gunicorn, each with its own dedicated PostgreSQL database
- **1 Processing Server**: Running Celery workers that can access all databases
- **2 PostgreSQL Databases**: Each web server has its own managed RDS database
- **Redis Cluster**: Managed ElastiCache for message brokering with server identification
- **Secure Network**: VPC with proper security groups

## Project Structure

```
├── myproject/                 # Django application
│   ├── myproject/            # Django project settings
│   ├── myapp/               # Django app with web forms and tasks
│   └── requirements.txt     # Python dependencies
├── main.tf                  # Terraform infrastructure definition
├── variables.tf             # Terraform input variables
├── user_data.sh            # Server startup script
└── terraform.tfvars.example # Template for Terraform variables
```

## Django Application

The Django app provides:
- Web form for entering two numbers (shows which server you're connected to)
- Celery task that adds the numbers with server identification (10-second delay to simulate processing)
- Multiple PostgreSQL databases (each web server has its own database)
- Redis as message broker that includes server ID to route tasks to correct database
- Database routing logic to ensure Celery workers update the correct server's database

## Deployment Instructions

### Prerequisites

1. AWS CLI configured with appropriate credentials
2. Terraform installed
3. An existing EC2 key pair in your target AWS region

### Step 1: Configure Variables

1. Copy the template file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` with your specific values:
   ```hcl
   aws_region = "us-west-2"
   key_pair_name = "your-existing-key-pair"
   my_ip = "your.ip.address.here"  # Optional, for SSH access
   ```

### Step 2: Deploy Infrastructure

1. Initialize Terraform:
   ```bash
   terraform init
   ```

2. Review the deployment plan:
   ```bash
   terraform plan
   ```

3. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

4. Note the output IP addresses for the web servers.

### Step 3: Verification

1. **Test Web Interface**:
   - Open a browser and navigate to any web server IP
   - Fill out the form with two numbers and submit
   - You should see a confirmation message

2. **Check Processing**:
   - SSH into the processing server:
     ```bash
     ssh -i your-key.pem ubuntu@PROCESSING_SERVER_IP
     ```
   - View Celery logs:
     ```bash
     sudo tail -f /var/log/celery.log
     ```
   - Look for "Processing task..." and "Task complete" messages

## Security Features

- **Web servers**: Accept HTTP (port 80) from anywhere, SSH from your IP only
- **Processing server**: SSH access from your IP only, can access all databases
- **PostgreSQL Databases**: Each database only accessible from servers (no public access)
- **Redis**: Only accessible from web and processing servers (no public access)
- **VPC**: Isolated network environment

## Multi-Database Architecture

- **Web Server 1**: Uses `django-postgres-1` database, sends tasks with `server_id=1`
- **Web Server 2**: Uses `django-postgres-2` database, sends tasks with `server_id=2`
- **Celery Worker**: Receives tasks with server ID and routes to correct database
- **Message Flow**: Web Server → Redis (with server_id) → Celery → Correct Database

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

## Customization

- Modify instance types in `main.tf` for different performance requirements
- Update the Django application in the `myproject/` directory
- Adjust security group rules for different access patterns
- Scale web servers by changing the `count` parameter

## Cost Optimization

- Uses `t2.micro` instances (free tier eligible)
- Uses `db.t3.micro` for PostgreSQL (minimal cost)
- Uses `cache.t2.micro` for Redis (minimal cost)
- All resources are in a single availability zone to minimize data transfer costs