# config/celery.py
import os
import logging
from celery import Celery

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')

app = Celery('ekeflicks')
app.config_from_object('django.conf:settings', namespace='CELERY')
app.autodiscover_tasks()

logger = logging.getLogger(__name__)

@app.task(bind=True)
def debug_task(self):
    logger.debug("Request: %r", self.request)
