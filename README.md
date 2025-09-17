# Django Celery AWS Infrastructure

This project deploys a scalable Django application with Celery task processing on AWS using Terraform.

## Architecture

- **2 Web Servers**: Running Django with Gunicorn, serving HTTP requests
- **1 Processing Server**: Running Celery workers for background task processing
- **Redis Cluster**: Managed ElastiCache for message brokering
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
- Web form for entering two numbers
- Celery task that adds the numbers (with 10-second delay to simulate processing)
- Redis as message broker between web servers and processing server

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
- **Processing server**: SSH access from your IP only
- **Redis**: Only accessible from web and processing servers (no public access)
- **VPC**: Isolated network environment

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
- Uses `cache.t2.micro` for Redis (minimal cost)
- All resources are in a single availability zone to minimize data transfer costs