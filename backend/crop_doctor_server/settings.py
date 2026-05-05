
from datetime import timedelta
import environ
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

env = environ.Env()
_dotenv_base = BASE_DIR / ".env"
_dotenv_local = BASE_DIR / "crop_doctor_server" / ".env"
if _dotenv_base.exists():
    environ.Env.read_env(_dotenv_base)
elif _dotenv_local.exists():
    environ.Env.read_env(_dotenv_local)
else:
    environ.Env.read_env(".env")

GEMINI_API_KEY = env("GEMINI_API_KEY", default="")
GEMINI_MODEL = env("GEMINI_MODEL", default="gemini-1.5-flash-latest")
GEMINI_DEBUG = env.bool("GEMINI_DEBUG", default=False)
GEMINI_LIST_MODELS = env.bool("GEMINI_LIST_MODELS", default=False)

LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "handlers": {
        "console": {"class": "logging.StreamHandler"},
    },
    "loggers": {
        "scan": {
            "handlers": ["console"],
            "level": "DEBUG" if GEMINI_DEBUG else "INFO",
            "propagate": False,
        },
    },
}

# Quick-start development settings - unsuitable for production
# See https://docs.djangoproject.com/en/6.0/howto/deployment/checklist/

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = 'django-insecure-*+0ak+_eulmzwvfnu0+%zmk@^%!b*u@yw^%q@5!(j-+)ogb$9)'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True

ALLOWED_HOSTS = ["*"]


BACKEND_HOST = env("BACKEND_HOST", default="https://cropdoctor.mrshakil.site")

# Application definition

INSTALLED_APPS = [
    "jazzmin",
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # third party apps
    "rest_framework",
    "rest_framework.authtoken",
    "corsheaders",
    "django_filters",


    'users',
    'scan',
    'subscriptions',
    'forums',
]

MIDDLEWARE = [
    "corsheaders.middleware.CorsMiddleware",
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

AUTH_USER_MODEL = "users.User"

ROOT_URLCONF = 'crop_doctor_server.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'crop_doctor_server.wsgi.application'


REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "rest_framework.authentication.TokenAuthentication",
    ],
}


CORS_ALLOW_ALL_ORIGINS = True
CORS_ALLOW_CREDENTIALS = True

# ── Password validation ────────────────────────────────────────────────────────
AUTH_PASSWORD_VALIDATORS = [
    {"NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator"},
    {"NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
     "OPTIONS": {"min_length": 8}},
    {"NAME": "django.contrib.auth.password_validation.CommonPasswordValidator"},
    {"NAME": "django.contrib.auth.password_validation.NumericPasswordValidator"},
]

# Database
# https://docs.djangoproject.com/en/6.0/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}


# Password validation
# https://docs.djangoproject.com/en/6.0/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# Internationalization
# https://docs.djangoproject.com/en/6.0/topics/i18n/

LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/6.0/howto/static-files/

STATIC_URL = "/static/"
STATIC_ROOT = BASE_DIR / "staticfiles"

MEDIA_URL = "/media/"
MEDIA_ROOT = BASE_DIR / "media"

SSLCOMMERZ_STORE_ID = env("SSLCOMMERZ_STORE_ID", default="")
SSLCOMMERZ_STORE_PASSWORD = env("SSLCOMMERZ_STORE_PASSWORD", default="")
SSLCOMMERZ_BASE_URL = env("SSLCOMMERZ_BASE_URL", default="")

# Jazzmin Admin Configuration
JAZZMIN_SETTINGS = {
    "site_title": "Crop Doctor Admin",
    "site_header": "Crop Doctor Management",
    "site_brand": "CropDoctor",
    "login_logo": None,
    "login_logo_dark": None,
    "site_logo_classes": "img-circle",
    "welcome_sign": "Welcome to Crop Doctor Admin Panel",
    "copyright": "Crop Doctor © 2026. All rights reserved.",
    "search_model": ["users.User", "scan.ScanHistory", "subscriptions.UserSubscription"],
    "user_avatar": None,
    "topmenu_links": [
        {"name": "Home", "url": "admin:index",
            "permissions": ["auth.view_user"]},
        {"name": "API Docs", "url": "/docs/", "new_window": True},
    ],
    "usermenu_links": [
        {"model": "auth.user"},
    ],
    "show_sidebar": True,
    "navigation_expanded": True,
    "hide_apps": [],
    "hide_models": [],
    "order_with_respect_to": [
        "auth.user",
        "users.user",
        "scan.plant",
        "scan.scanhistory",
        "scan.diseasecatalogitem",
        "scan.diseasesolution",
        "subscriptions.subscriptionplan",
        "subscriptions.usersubscription",
        "forums.question",
        "forums.answer",
    ],
    "custom_css": None,
    "custom_js": None,
    "show_ui_builder": False,
    "changeform_format": "horizontal_tabs",
    "changeform_format_overrides": {
        "auth.user": "collapsible",
        "auth.group": "tab",
    },
    "icons": {
        "auth": "fas fa-users-cog",
        "auth.user": "fas fa-user",
        "auth.Group": "fas fa-users",
        "users.user": "fas fa-user-circle",
        "users": "fas fa-users-cog",
        "scan.plant": "fas fa-leaf",
        "scan.scanhistory": "fas fa-microscope",
        "scan.diseasecatalogitem": "fas fa-list",
        "scan.diseasesolution": "fas fa-prescription-bottle",
        "scan": "fas fa-stethoscope",
        "subscriptions.subscriptionplan": "fas fa-credit-card",
        "subscriptions.usersubscription": "fas fa-user-check",
        "subscriptions": "fas fa-layer-group",
        "forums.question": "fas fa-question-circle",
        "forums.answer": "fas fa-comments",
        "forums": "fas fa-comments",
    },
    "default_icon_parents": "fas fa-chevron-right",
    "default_icon_children": "fas fa-arrow-right",
    "related_modal_active": True,
    "custom_url_icon_map": {},
    "show_form_bottom_submit_button": True,
    "language_chooser": False,
    "version": "3.0.0",
}
