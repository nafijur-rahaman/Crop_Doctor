import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'crop_doctor_server.settings')
django.setup()

from users.models import User

if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser('admin', 'admin@gmail.com', '123')
    print("Superuser 'admin' created with password '123'")
else:
    print("Superuser 'admin' already exists")