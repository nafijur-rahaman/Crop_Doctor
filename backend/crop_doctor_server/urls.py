from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/', include('scan.urls')),
    path('api/', include('subscriptions.urls')),
    path('api/', include('forums.urls')),
   
]
