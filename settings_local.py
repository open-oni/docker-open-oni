DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'HOST': '!DB_HOST!',
        'PORT': '3306',
        'NAME': 'openoni',
        'USER': 'openoni',
        'PASSWORD': 'openoni',
        }
    }

# Make this unique, and don't share it with anybody.
SECRET_KEY = '!SECRETKEY!'
SOLR = "http://!SOLR_HOST!:8983/solr"
