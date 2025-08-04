#!/bin/bash

# GitHub Actions Workflow Validation Script
# Run this script to validate your workflow before pushing to GitHub

echo "🔍 Starting GitHub Actions Workflow Validation..."
echo "=================================================="

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ $2${NC}"
    else
        echo -e "${RED}❌ $2${NC}"
        exit 1
    fi
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Step 1: Check required files
echo "📁 Checking required files..."
test -f "docker-compose.yml" && print_status 0 "docker-compose.yml exists" || print_status 1 "docker-compose.yml missing"
test -f "API/.env.example" && print_status 0 "API/.env.example exists" || print_status 1 "API/.env.example missing"
test -f "Toolshop_APITesting.postman_collection.json" && print_status 0 "Postman collection exists" || print_status 1 "Postman collection missing"
test -d "_docker" && print_status 0 "_docker directory exists" || print_status 1 "_docker directory missing"
test -f ".github/workflows/api-tests.yml" && print_status 0 "GitHub workflow file exists" || print_status 1 "GitHub workflow file missing"

echo ""

# Step 2: Validate Docker Compose
echo "🐳 Validating Docker Compose configuration..."
if docker compose config > /dev/null 2>&1; then
    print_status 0 "Docker Compose configuration is valid"
else
    print_status 1 "Docker Compose configuration is invalid"
fi

echo ""

# Step 3: Check Docker build files
echo "🏗️  Checking Docker build files..."
test -f "_docker/api.docker" && print_status 0 "API Dockerfile exists" || print_status 1 "API Dockerfile missing"
test -f "_docker/ui.docker" && print_status 0 "UI Dockerfile exists" || print_status 1 "UI Dockerfile missing"
test -f "_docker/web.docker" && print_status 0 "Web Dockerfile exists" || print_status 1 "Web Dockerfile missing"

echo ""

# Step 4: Validate Postman Collection
echo "📮 Validating Postman Collection..."
if command -v jq > /dev/null 2>&1; then
    if jq empty Toolshop_APITesting.postman_collection.json > /dev/null 2>&1; then
        print_status 0 "Postman collection JSON is valid"
        
        # Check for required folders
        FOLDERS=$(jq -r '.item[].name' Toolshop_APITesting.postman_collection.json 2>/dev/null)
        echo "📂 Found test folders:"
        echo "$FOLDERS" | while read folder; do
            echo "   - $folder"
        done
    else
        print_status 1 "Postman collection JSON is invalid"
    fi
else
    print_warning "jq not found, skipping JSON validation"
fi

echo ""

# Step 5: Check if ports are available
echo "🔌 Checking port availability..."
if command -v netstat > /dev/null 2>&1; then
    if netstat -lan | grep -q ":8091"; then
        print_warning "Port 8091 is already in use"
    else
        print_status 0 "Port 8091 is available"
    fi
    
    if netstat -lan | grep -q ":3306"; then
        print_warning "Port 3306 is already in use"
    else
        print_status 0 "Port 3306 is available"
    fi
else
    print_warning "netstat not found, skipping port check"
fi

echo ""

# Step 6: Test Docker Compose (optional)
echo "🧪 Testing Docker Compose (optional)..."
read -p "Do you want to test Docker Compose locally? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting Docker services..."
    docker compose up -d --build
    
    if [ $? -eq 0 ]; then
        print_status 0 "Docker services started successfully"
        
        echo "⏳ Waiting for services to be ready..."
        sleep 30
        
        # Test database connection
        if docker compose exec -T laravel-api php artisan migrate:status > /dev/null 2>&1; then
            print_status 0 "Database connection successful"
        else
            print_warning "Database connection failed (may need more time)"
        fi
        
        # Test API endpoint
        if curl -f http://localhost:8091/products > /dev/null 2>&1; then
            print_status 0 "API endpoint responding"
        else
            print_warning "API endpoint not responding (may need more time)"
        fi
        
        echo "🧹 Cleaning up..."
        docker compose down -v
        print_status 0 "Docker services stopped"
    else
        print_status 1 "Failed to start Docker services"
    fi
fi

echo ""
echo "=================================================="
echo -e "${GREEN}🎉 Workflow validation completed!${NC}"
echo ""
echo "📋 Next steps:"
echo "1. Review any warnings above"
echo "2. Commit and push your changes"
echo "3. Monitor the GitHub Actions workflow run"
echo "4. Check the Actions tab in your GitHub repository"
echo ""
echo "🔗 Useful links:"
echo "   - GitHub Actions: https://github.com/<owner>/<repo>/actions"
echo "   - Workflow file: .github/workflows/api-tests.yml"
echo "   - Validation checklist: WORKFLOW_VALIDATION_CHECKLIST.md"
