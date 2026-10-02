from django.urls import path

from apps.common.faq_api import FrequentlyAskedQuestionsView, ProducerEkeChatView


urlpatterns = [
    path('faq/', FrequentlyAskedQuestionsView.as_view(), name='faq-list'),
    path('producer-assistant/chat/', ProducerEkeChatView.as_view(), name='producer-eke-chat'),
]
