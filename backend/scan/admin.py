from django.contrib import admin
from .models import ScanHistory, DiseaseSolution, MissingSolutionLog

admin.site.register(ScanHistory)
admin.site.register(DiseaseSolution)
admin.site.register(MissingSolutionLog)
