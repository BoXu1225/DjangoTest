from django.db import models
from django.utils import timezone

class Calculation(models.Model):
    """Model to record calculation parameters and results"""

    # Input parameters
    x = models.IntegerField(help_text="First number")
    y = models.IntegerField(help_text="Second number")

    # Result
    result = models.IntegerField(help_text="Calculation result")

    # Metadata
    server_id = models.IntegerField(help_text="ID of the server that processed this calculation")
    task_id = models.CharField(max_length=255, help_text="Celery task ID", blank=True, null=True)

    # Timestamps
    created_at = models.DateTimeField(default=timezone.now, help_text="When the task was created")
    processed_at = models.DateTimeField(auto_now_add=True, help_text="When the task was completed")

    class Meta:
        ordering = ['-processed_at']
        verbose_name = "Calculation"
        verbose_name_plural = "Calculations"

    def __str__(self):
        return f"Server {self.server_id}: {self.x} + {self.y} = {self.result}"

    @property
    def processing_duration(self):
        """Calculate how long the task took to process"""
        if self.created_at and self.processed_at:
            return self.processed_at - self.created_at
        return None
