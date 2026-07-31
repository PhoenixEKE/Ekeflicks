from django.urls import include, path
from rest_framework.routers import DefaultRouter

from apps.profiles.views import ProfileTypeViewSet, ProfileViewSet

router = DefaultRouter()
router.register('profile-types', ProfileTypeViewSet, basename='profile-type')
router.register('profiles', ProfileViewSet, basename='profile')

urlpatterns = [
    path('', include(router.urls)),
]
