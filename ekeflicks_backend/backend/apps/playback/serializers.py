from rest_framework import serializers

from apps.catalog.serializers import ContentListSerializer, EpisodeSerializer
from apps.common.serializers import get_request_user, validate_profile_owner
from apps.profiles.serializers import ProfileSummarySerializer
from core.models import (
    Content,
    CustomList,
    Episode,
    Favorite,
    ListItem,
    Profile,
    Rating,
    ViewingSession,
    WatchHistory,
)


class FavoriteSerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)
    content = ContentListSerializer(read_only=True)
    profile_id = serializers.PrimaryKeyRelatedField(
        source='profile',
        queryset=Profile.objects.all(),
        write_only=True,
    )
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
    )

    class Meta:
        model = Favorite
        fields = ['id', 'profile', 'profile_id', 'content', 'content_id', 'created_at']
        read_only_fields = ['id', 'profile', 'content', 'created_at']

    def validate_profile_id(self, profile):
        return validate_profile_owner(self, profile)

    def create(self, validated_data):
        favorite, _created = Favorite.objects.get_or_create(**validated_data)
        return favorite


class RatingSerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)
    content = ContentListSerializer(read_only=True)
    profile_id = serializers.PrimaryKeyRelatedField(
        source='profile',
        queryset=Profile.objects.all(),
        write_only=True,
    )
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
    )

    class Meta:
        model = Rating
        fields = [
            'id',
            'profile',
            'profile_id',
            'content',
            'content_id',
            'rating',
            'review',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'profile', 'content', 'created_at', 'updated_at']

    def validate_profile_id(self, profile):
        profile = validate_profile_owner(self, profile)
        if profile.type and not profile.type.can_rate_content:
            raise serializers.ValidationError("Ce profil ne peut pas noter les contenus.")
        return profile

    def validate_rating(self, value):
        if value < 0 or value > 5:
            raise serializers.ValidationError('La note doit etre comprise entre 0 et 5.')
        return value

    def create(self, validated_data):
        rating, _created = Rating.objects.update_or_create(
            profile=validated_data['profile'],
            content=validated_data['content'],
            defaults={
                'rating': validated_data.get('rating'),
                'review': validated_data.get('review', ''),
            },
        )
        return rating


class WatchHistorySerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)
    content = ContentListSerializer(read_only=True)
    episode = EpisodeSerializer(read_only=True)
    profile_id = serializers.PrimaryKeyRelatedField(
        source='profile',
        queryset=Profile.objects.all(),
        write_only=True,
    )
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
    )
    episode_id = serializers.PrimaryKeyRelatedField(
        source='episode',
        queryset=Episode.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = WatchHistory
        fields = [
            'id',
            'profile',
            'profile_id',
            'content',
            'content_id',
            'episode',
            'episode_id',
            'progress',
            'last_position',
            'watched_duration',
            'completed',
            'watched_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'profile', 'content', 'episode', 'watched_at', 'updated_at']

    def validate_profile_id(self, profile):
        return validate_profile_owner(self, profile)

    def validate_progress(self, value):
        if value < 0 or value > 100:
            raise serializers.ValidationError('La progression doit etre comprise entre 0 et 100.')
        return value

    def validate(self, attrs):
        episode = attrs.get('episode') or getattr(self.instance, 'episode', None)
        content = attrs.get('content') or getattr(self.instance, 'content', None)
        if episode and content and episode.content_id != content.id:
            raise serializers.ValidationError(
                {'episode_id': "L'episode doit appartenir au contenu."}
            )
        return attrs

    def create(self, validated_data):
        episode = validated_data.get('episode')
        defaults = {
            'progress': validated_data.get('progress', 0),
            'last_position': validated_data.get('last_position', 0),
            'watched_duration': validated_data.get('watched_duration', 0),
            'completed': validated_data.get('completed', False),
        }

        history = WatchHistory.objects.filter(
            profile=validated_data['profile'],
            content=validated_data['content'],
            episode=episode,
        ).order_by('-updated_at').first()
        if history:
            for field, value in defaults.items():
                setattr(history, field, value)
            history.save(update_fields=[*defaults.keys(), 'updated_at'])
            return history

        return WatchHistory.objects.create(
            profile=validated_data['profile'],
            content=validated_data['content'],
            episode=episode,
            **defaults,
        )


class ListItemSerializer(serializers.ModelSerializer):
    content = ContentListSerializer(read_only=True)
    list_id = serializers.PrimaryKeyRelatedField(
        source='list',
        queryset=CustomList.objects.all(),
        write_only=True,
    )
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
    )

    class Meta:
        model = ListItem
        fields = ['id', 'list', 'list_id', 'content', 'content_id', 'added_order', 'added_at']
        read_only_fields = ['id', 'list', 'content', 'added_at']

    def validate_list_id(self, custom_list):
        user = get_request_user(self)
        if not user or not user.is_authenticated or custom_list.profile.user_id != user.id:
            raise serializers.ValidationError("Liste invalide pour cet utilisateur.")
        return custom_list

    def create(self, validated_data):
        item, _created = ListItem.objects.get_or_create(
            list=validated_data['list'],
            content=validated_data['content'],
            defaults={'added_order': validated_data.get('added_order', 0)},
        )
        return item


class CustomListSerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)
    profile_id = serializers.PrimaryKeyRelatedField(
        source='profile',
        queryset=Profile.objects.all(),
        write_only=True,
    )
    items = ListItemSerializer(many=True, read_only=True)

    class Meta:
        model = CustomList
        fields = [
            'id',
            'profile',
            'profile_id',
            'name',
            'description',
            'is_public',
            'items',
            'created_at',
            'updated_at',
        ]
        read_only_fields = ['id', 'profile', 'items', 'created_at', 'updated_at']

    def validate_profile_id(self, profile):
        profile = validate_profile_owner(self, profile)
        if profile.type and not profile.type.can_create_lists:
            raise serializers.ValidationError("Ce profil ne peut pas creer de listes.")
        return profile


class ViewingSessionSerializer(serializers.ModelSerializer):
    profile = ProfileSummarySerializer(read_only=True)
    content = ContentListSerializer(read_only=True)
    episode = EpisodeSerializer(read_only=True)
    profile_id = serializers.PrimaryKeyRelatedField(
        source='profile',
        queryset=Profile.objects.all(),
        write_only=True,
    )
    content_id = serializers.PrimaryKeyRelatedField(
        source='content',
        queryset=Content.objects.all(),
        write_only=True,
    )
    episode_id = serializers.PrimaryKeyRelatedField(
        source='episode',
        queryset=Episode.objects.all(),
        write_only=True,
        required=False,
        allow_null=True,
    )

    class Meta:
        model = ViewingSession
        fields = [
            'id',
            'profile',
            'profile_id',
            'content',
            'content_id',
            'episode',
            'episode_id',
            'session_id',
            'start_time',
            'end_time',
            'duration_watched',
            'was_completed',
            'device_type',
            'quality_played',
        ]
        read_only_fields = ['id', 'profile', 'content', 'episode', 'session_id', 'start_time']

    def validate_profile_id(self, profile):
        return validate_profile_owner(self, profile)

    def validate(self, attrs):
        episode = attrs.get('episode') or getattr(self.instance, 'episode', None)
        content = attrs.get('content') or getattr(self.instance, 'content', None)
        if episode and content and episode.content_id != content.id:
            raise serializers.ValidationError(
                {'episode_id': "L'episode doit appartenir au contenu."}
            )
        return attrs
