from celery import shared_task

from apps.auth.services import process_due_account_closure_requests


@shared_task
def process_due_account_closures():
    return process_due_account_closure_requests()
