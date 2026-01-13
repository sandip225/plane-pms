# EC2 Deployment Guide

## Prerequisites

- EC2 instance (Ubuntu 22.04+ recommended)
- Minimum specs: t3.medium (2 vCPU, 4GB RAM), 30GB storage
- Security group with ports 22, 80, 443 open
- Domain pointing to your EC2 public IP

## Quick Deploy

```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Clone the repository
git clone https://github.com/your-org/plane.git
cd plane

# Configure environment
cp .env.example .env
nano .env  # Edit with your settings

# Also configure API environment
cp apps/api/.env.example apps/api/.env
nano apps/api/.env  # Edit with your settings

# Run deployment
DOMAIN=your-domain.com EMAIL=your@email.com sudo -E bash deployments/ec2/deploy.sh
```

## Environment Variables

Edit `.env` with these required values:

```bash
# Database (change in production!)
POSTGRES_USER=plane
POSTGRES_PASSWORD=<strong-password>
POSTGRES_DB=plane

# RabbitMQ (change in production!)
RABBITMQ_USER=plane
RABBITMQ_PASSWORD=<strong-password>
RABBITMQ_VHOST=plane

# MinIO/S3
AWS_ACCESS_KEY_ID=<your-access-key>
AWS_SECRET_ACCESS_KEY=<your-secret-key>

# Domain
NGINX_HOST=your-domain.com
```

## Manual SSL Setup (if deploy.sh fails)

```bash
# Create directories
mkdir -p certbot/conf certbot/www

# Get certificate manually
docker run -it --rm \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  -p 80:80 \
  certbot/certbot certonly \
  --standalone \
  -d your-domain.com \
  --email your@email.com \
  --agree-tos

# Start services
docker compose -f docker-compose.ec2.yml up -d
```

## Commands

```bash
# View all logs
docker compose -f docker-compose.ec2.yml logs -f

# View specific service logs
docker compose -f docker-compose.ec2.yml logs -f api

# Restart all services
docker compose -f docker-compose.ec2.yml restart

# Stop all services
docker compose -f docker-compose.ec2.yml down

# Rebuild and restart
docker compose -f docker-compose.ec2.yml up -d --build

# Check service status
docker compose -f docker-compose.ec2.yml ps
```

## SSL Certificate Renewal

Certificates auto-renew via the certbot container. To manually renew:

```bash
docker compose -f docker-compose.ec2.yml exec certbot certbot renew
docker compose -f docker-compose.ec2.yml exec proxy nginx -s reload
```

## Troubleshooting

### Services not starting
```bash
# Check logs
docker compose -f docker-compose.ec2.yml logs

# Verify .env files exist
ls -la .env apps/api/.env
```

### SSL certificate issues
```bash
# Check certificate status
docker compose -f docker-compose.ec2.yml exec certbot certbot certificates

# Test renewal
docker compose -f docker-compose.ec2.yml exec certbot certbot renew --dry-run
```

### Database connection issues
```bash
# Check if postgres is running
docker compose -f docker-compose.ec2.yml ps plane-db

# View postgres logs
docker compose -f docker-compose.ec2.yml logs plane-db
```
