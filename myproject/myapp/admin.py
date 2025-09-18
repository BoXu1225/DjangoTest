from django.contrib import admin
from .models import Calculation

@admin.register(Calculation)
class CalculationAdmin(admin.ModelAdmin):
    list_display = ('x', 'y', 'result', 'server_id', 'task_id', 'created_at', 'processed_at')
    list_filter = ('server_id', 'created_at', 'processed_at')
    search_fields = ('task_id', 'x', 'y', 'result')
    readonly_fields = ('task_id', 'created_at', 'processed_at', 'processing_duration')
    ordering = ('-processed_at',)

    fieldsets = (
        ('Calculation', {
            'fields': ('x', 'y', 'result')
        }),
        ('Server Information', {
            'fields': ('server_id', 'task_id')
        }),
        ('Timestamps', {
            'fields': ('created_at', 'processed_at', 'processing_duration')
        }),
    )

    def processing_duration(self, obj):
        """Display processing duration in the admin"""
        duration = obj.processing_duration
        if duration:
            return f"{duration.total_seconds():.2f} seconds"
        return "N/A"
    processing_duration.short_description = "Processing Duration"
