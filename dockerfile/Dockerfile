FROM ruby:2.5.3

# 🧱 Fix repos antiguos de Debian Stretch
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list && \
    sed -i '/security.debian.org/d' /etc/apt/sources.list && \
    sed -i '/stretch-updates/d' /etc/apt/sources.list && \
    echo "Acquire::Check-Valid-Until \"false\";" > /etc/apt/apt.conf.d/99no-check-valid-until && \
    apt-get update -qq && apt-get install -y --allow-unauthenticated \
    build-essential \
    default-libmysqlclient-dev \
    libpq-dev \
    nodejs \
    git \
    libffi-dev \
    libyaml-dev \
    libmagic-dev \
    pkg-config \
    file \
    ghostscript \
    imagemagick

# 📂 Seteo el directorio de trabajo
WORKDIR /app

# 📦 Copio todo el proyecto incluyendo Redmine y los plugins
COPY . /app

# 🧠 Asegurate de que el Gemfile principal tenga:
# Dir.glob File.expand_path("plugins/*/{Gemfile,PluginGemfile}", __dir__) { |file| eval_gemfile file }

# ✅ Actualizo RubyGems por compatibilidad
RUN gem update --system 3.2.3

# 💎 Instalo todas las gemas (Redmine + plugins)
RUN bundle config set without 'development test' && \
    bundle install --jobs=4 --retry=3

# 🔐 Crear secret key dummy para entorno development
RUN mkdir -p tmp && touch tmp/development_secret.txt

# Seteamos entorno de desarrollo
ENV RAILS_ENV=development

# Comando de inicio del servidor
# CMD ["bundle", "exec", "rails", "s", "-b", "0.0.0.0"]
CMD ["bash", "-c", "rm -f /app/tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0"]
