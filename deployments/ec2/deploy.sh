#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Plane EC2 Deployment Script ===${NC}"

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Please run with sudo${NC}"
    exit 1
fi

# Check required environment variables
if [ -z "$DOMAIN" ]; then
    echo -e "${RED}Error: DOMAIN environment variable is required${NC}"
    echo "Usage: DOMAIN=your-domain.com EMAIL=your@email.com sudo -E ./deploy.sh"
    exit 1
fi

if [ -z "$EMAIL" ]; then
    echo -e "${RED}Error: EMAIL environment variable is required for SSL certificate${NC}"
    echo "Usage: DOMAIN=your-domain.com EMAIL=your@email.com sudo -E ./deploy.sh"
    exit 1
fi

echo -e "${YELLOW}Domain: $DOMAIN${NC}"
echo -e "${YELLOW}Email: $EMAIL${NC}"

# Step 1: Install Docker if not present
install_docker() {
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}Docker already installed${NC}"
    else
        echo -e "${YELLOW}Installing Docker...${NC}"
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
        systemctl enable docker
        systemctl start docker
        echo -e "${GREEN}Docker installed successfully${NC}"
    fi
}

# Step 2: Install Docker Compose if not present
install_docker_compose() {
    if command -v docker compose &> /dev/null; then
        echo -e "${GREEN}Docker Compose already installed${NC}"
    else
        echo -e "${YELLOW}Installing Docker Compose...${NC}"
        apt-get update
        apt-get install -y docker-compose-plugin
        echo -e "${GREEN}Docker Compose installed successfully${NC}"
    fi
}

# Step 3: Setup environment file
setup_env() {
    echo -e "${YELLOW}Setting up environment...${NC}"
    
    if [ ! -f .env ]; then
        cp .env.example .env
    fi
    
    # Update NGINX_HOST in .env
    if grep -q "NGINX_HOST" .env; then
        sed -i "s/NGINX_HOST=.*/NGINX_HOST=$DOMAIN/" .env
    else
        echo "NGINX_HOST=$DOMAIN" >> .env
    fi
    
    echo -e "${GREEN}Environment configured${NC}"
}

# Step 4: Create certbot directories
setup_certbot_dirs() {
    echo -e "${YELLOW}Setting up SSL directories...${NC}"
    mkdir -p certbot/conf certbot/www
    echo -e "${GREEN}SSL directories created${NC}"
}

# Step 5: Get initial SSL certificate
get_ssl_cert() {
    echo -e "${YELLOW}Obtaining SSL certificate...${NC}"
    
    # Check if certificate already exists
    if [ -d "certbot/conf/live/$DOMAIN" ]; then
        echo -e "${GREEN}SSL certificate already exists${NC}"
        return
    fi
    
    # Create temporary nginx config for initial cert
    cat > apps/proxy/nginx-init.conf << EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 200 'Waiting for SSL setup...';
        add_header Content-Type text/plain;
    }
}
EOF

    # Start nginx with init config
    docker run -d --name nginx-init \
        -p 80:80 \
        -v $(pwd)/apps/proxy/nginx-init.conf:/etc/nginx/conf.d/default.conf:ro \
        -v $(pwd)/certbot/www:/var/www/certbot \
        nginx:1.27-alpine
    
    sleep 5
    
    # Get certificate
    docker run --rm \
        -v $(pwd)/certbot/conf:/etc/letsencrypt \
        -v $(pwd)/certbot/www:/var/www/certbot \
        certbot/certbot certonly \
        --webroot \
        --webroot-path=/var/www/certbot \
        --email $EMAIL \
        --agree-tos \
        --no-eff-email \
        -d $DOMAIN
    
    # Stop and remove init nginx
    docker stop nginx-init
    docker rm nginx-init
    rm apps/proxy/nginx-init.conf
    
    echo -e "${GREEN}SSL certificate obtained${NC}"
}

# Step 6: Build and start services
start_services() {
    echo -e "${YELLOW}Building and starting services...${NC}"
    docker compose -f docker-compose.ec2.yml build
    docker compose -f docker-compose.ec2.yml up -d
    echo -e "${GREEN}Services started${NC}"
}

# Step 7: Setup auto-renewal cron
setup_renewal() {
    echo -e "${YELLOW}Setting up SSL auto-renewal...${NC}"
    
    # Add cron job for renewal
    (crontab -l 2>/dev/null | grep -v "certbot renew"; echo "0 0 * * * cd $(pwd) && docker compose -f docker-compose.ec2.yml exec -T certbot certbot renew --quiet && docker compose -f docker-compose.ec2.yml exec -T proxy nginx -s reload") | crontab -
    
    echo -e "${GREEN}Auto-renewal configured${NC}"
}

# Main execution
main() {
    install_docker
    install_docker_compose
    setup_env
    setup_certbot_dirs
    get_ssl_cert
    start_services
    setup_renewal
    
    echo ""
    echo -e "${GREEN}=== Deployment Complete ===${NC}"
    echo -e "Your Plane instance is now available at: ${GREEN}https://$DOMAIN${NC}"
    echo ""
    echo "Useful commands:"
    echo "  View logs:     docker compose -f docker-compose.ec2.yml logs -f"
    echo "  Stop:          docker compose -f docker-compose.ec2.yml down"
    echo "  Restart:       docker compose -f docker-compose.ec2.yml restart"
    echo "  Update:        git pull && docker compose -f docker-compose.ec2.yml up -d --build"
}

main
