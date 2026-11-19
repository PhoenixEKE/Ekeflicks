from rest_framework import serializers


def get_request_user(serializer):
    request = serializer.context.get('request')
    return getattr(request, 'user', None)


def validate_profile_owner(serializer, profile):
    user = get_request_user(serializer)
    if not user or not user.is_authenticated or profile.user_id != user.id:
        raise serializers.ValidationError("Profil invalide pour cet utilisateur.")
    return profile
