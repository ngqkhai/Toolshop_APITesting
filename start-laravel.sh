#!/bin/bash

echo "🚀 Starting Laravel API setup..."

# Wait for database to be ready
echo "⏳ Waiting for database connection..."
until php artisan migrate:status &> /dev/null; do
    echo "Database not ready, waiting 5 seconds..."
    sleep 5
done

echo "✅ Database is ready!"

# Run migrations
echo "🔄 Running database migrations..."
php artisan migrate --force

# Run seeders
echo "🌱 Seeding database..."
php artisan db:seed --force

# Clear caches
echo "🧹 Clearing caches..."
php artisan cache:clear
php artisan config:clear
php artisan route:clear

echo "✅ Laravel API is ready!"

# Start PHP-FPM
exec "$@"
