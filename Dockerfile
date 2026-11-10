FROM php:8.3-cli

RUN apt-get update && apt-get install -y --no-install-recommends \
      git unzip libzip-dev libsqlite3-dev libpng-dev libjpeg-dev libfreetype6-dev \
      libonig-dev libxml2-dev libicu-dev \
    && docker-php-ext-configure gd --with-jpeg --with-freetype \
    && docker-php-ext-install pdo_sqlite pdo_mysql zip gd mbstring bcmath intl exif \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-autoloader --prefer-dist --no-interaction

COPY . .
RUN composer dump-autoload --optimize --no-dev

RUN mkdir -p storage/framework/cache storage/framework/sessions storage/framework/views \
      storage/logs bootstrap/cache database \
    && touch database/database.sqlite \
    && chmod -R 777 storage bootstrap/cache database

RUN php artisan storage:link || true

ENV APP_ENV=production \
    APP_DEBUG=false \
    DEMO_SEED=1 \
    PHP_CLI_SERVER_WORKERS=4

EXPOSE 7860

CMD ["sh", "-c", "php artisan migrate:fresh --seed --force && exec php artisan serve --host=0.0.0.0 --port=7860"]