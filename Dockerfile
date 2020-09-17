ARG base_nginx_image

ARG base_php_image

FROM 1234567890.dkr.ecr.ap-southeast-1.amazonaws.com/$base_php_image AS php

MAINTAINER Gary Zhao

RUN apt-get update  && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg  \
    && docker-php-ext-install -j$(nproc) gd mysqli pdo_mysql pdo

RUN docker-php-ext-configure opcache --enable-opcache \
    && docker-php-ext-install opcache

RUN mkdir /tmp/content-site -p

RUN mkdir /var/wordpress_plugins -p

ADD ./wordpress /tmp/content-site

ADD ./aws_ecs_deployment/php-docker-script/php.ini /usr/local/etc/php

ADD ./aws_ecs_deployment/php-docker-script/entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT /entrypoint.sh


FROM 1234567890.dkr.ecr.ap-southeast-1.amazonaws.com/$base_nginx_image AS nginx

MAINTAINER Gary Zhao

ENV RUN_USER nginx

ENV RUN_GROUP nginx

RUN mkdir /var/wordpress_plugins -p

RUN mkdir /var/www/html -p

ADD ./aws_ecs_deployment/nginx_config/conf /etc/nginx

ADD ./wordpress /var/www/html/content-site

RUN chmod -R 755 /var/www/html

EXPOSE 80

ADD ./aws_ecs_deployment/nginx-docker-script/entrypoint.sh /

RUN chmod +x /entrypoint.sh

ENTRYPOINT /entrypoint.sh
