FROM ubuntu:trusty
MAINTAINER Mark Cooper <mark.cooper@lyrasis.org>

ENV DJANGO_SETTINGS_MODULE chronam.settings

RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
  apache2 \
  ca-certificates \
  gcc \
  git \
  graphicsmagick \
  libapache2-mod-wsgi \
  libmysqlclient-dev \
  libxml2-dev \
  libxslt-dev \
  libjpeg-dev \
  mysql-client \
  python-dev \
  python-virtualenv \
  supervisor

RUN git clone https://github.com/LibraryOfCongress/chronam.git /opt/chronam

RUN rm /bin/sh && ln -s /bin/bash /bin/sh
WORKDIR /opt/chronam
RUN mkdir -p data/batches && mkdir -p data/cache && mkdir -p data/bib
RUN virtualenv ENV && \
  source /opt/chronam/ENV/bin/activate && \
  cp conf/chronam.pth ENV/lib/python2.7/site-packages/chronam.pth && \
  pip install -U distribute && \
  pip install -r requirements.pip --allow-unverified PIL --allow-all-external
ADD settings.py /opt/chronam/settings.py

RUN a2enmod cache expires rewrite
ADD apache/chronam.conf /etc/apache2/sites-available/chronam.conf
RUN a2dissite 000-default.conf
RUN a2ensite chronam
RUN install -d /opt/chronam/static && install -d /opt/chronam/.python-eggs

ADD load_batch.sh /load_batch.sh
ADD startup.sh /startup.sh
ADD test.sh /test.sh

RUN chmod u+x /load_batch.sh && chmod u+x /startup.sh && chmod u+x /test.sh

EXPOSE 80
CMD ["/startup.sh"]