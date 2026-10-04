from django.utils import timezone
from rest_framework import serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.admin_api.security import AdminPermission, audit
from core.models import AdCampaign, AdEvent, Content


class AdminAdCampaignSerializer(serializers.ModelSerializer):
    content_ids = serializers.PrimaryKeyRelatedField(
        source="contents",
        queryset=Content.objects.all(),
        many=True,
        required=False,
    )

    class Meta:
        model = AdCampaign
        fields = [
            "id", "name", "advertiser", "status", "delivery_mode", "formats",
            "media_url", "vast_tag_url", "image_url", "media_duration_seconds",
            "cta_label", "cta_url", "target_countries", "contextual_genres",
            "interest_tags", "target_age_min", "target_age_max", "content_ids",
            "cue_points_seconds", "active_from", "active_until", "priority",
            "delivery_weight", "frequency_cap_per_day", "skip_after_seconds",
            "created_by", "created_at", "updated_at",
        ]
        read_only_fields = ["id", "created_by", "created_at", "updated_at"]

    def validate_formats(self, value):
        allowed = set(AdCampaign.FORMAT_CHOICES)
        if not isinstance(value, list) or not value:
            raise serializers.ValidationError("Choisissez au moins un format publicitaire.")
        normalized = list(dict.fromkeys(str(item).strip().lower() for item in value))
        invalid = sorted(set(normalized) - allowed)
        if invalid:
            raise serializers.ValidationError("Formats autorisés : preroll, midroll, pause.")
        return normalized

    def validate(self, attrs):
        def value(key, fallback=None):
            return attrs.get(key, getattr(self.instance, key, fallback) if self.instance else fallback)

        delivery = value("delivery_mode", "client_side")
        formats = value("formats", ["preroll"])
        media_url = (value("media_url", "") or "").strip()
        vast_url = (value("vast_tag_url", "") or "").strip()
        image_url = (value("image_url", "") or "").strip()
        cta_url = (value("cta_url", "") or "").strip()
        if delivery == "client_side" and any(slot in formats for slot in ("preroll", "midroll")) and not media_url:
            raise serializers.ValidationError({"media_url": "Une vidéo HTTPS est requise pour les pré-roll et mid-roll côté lecteur."})
        if delivery == "ssai" and "pause" in formats:
            raise serializers.ValidationError({"formats": "La publicité sur pause est déclenchée par le lecteur et ne peut pas être insérée par SSAI."})
        if "pause" in formats and not image_url:
            raise serializers.ValidationError({"image_url": "Un visuel HTTPS est obligatoire pour la publicité sur pause."})
        if delivery == "ssai" and not (media_url or vast_url):
            raise serializers.ValidationError({"media_url": "Une création vidéo ou une balise VAST est requise pour le flux SSAI."})
        for field_name, url in (("media_url", media_url), ("vast_tag_url", vast_url), ("image_url", image_url), ("cta_url", cta_url)):
            if url and not url.lower().startswith("https://"):
                raise serializers.ValidationError({field_name: "Les URL des créations et du CTA doivent utiliser HTTPS."})

        countries = value("target_countries", []) or []
        if not isinstance(countries, list) or any(len(str(code).strip()) != 2 for code in countries):
            raise serializers.ValidationError({"target_countries": "Utilisez des codes pays ISO à deux lettres."})
        attrs["target_countries"] = list(dict.fromkeys(str(code).strip().upper() for code in countries))

        min_age = value("target_age_min")
        max_age = value("target_age_max")
        if min_age is not None and not 18 <= int(min_age) <= 120:
            raise serializers.ValidationError({"target_age_min": "Le ciblage par âge est réservé aux adultes (18 ans et plus)."})
        if max_age is not None and not 18 <= int(max_age) <= 120:
            raise serializers.ValidationError({"target_age_max": "Le ciblage par âge est réservé aux adultes (18 ans et plus)."})
        if min_age is not None and max_age is not None and int(min_age) > int(max_age):
            raise serializers.ValidationError({"target_age_max": "L’âge maximal doit être supérieur ou égal à l’âge minimal."})

        cues = value("cue_points_seconds", []) or []
        if not isinstance(cues, list):
            raise serializers.ValidationError({"cue_points_seconds": "Les repères mid-roll doivent être une liste de secondes."})
        try:
            cues = sorted(set(int(point) for point in cues))
        except (TypeError, ValueError):
            raise serializers.ValidationError({"cue_points_seconds": "Chaque repère doit être un nombre entier de secondes."})
        if any(point <= 0 for point in cues):
            raise serializers.ValidationError({"cue_points_seconds": "Chaque repère mid-roll doit être supérieur à zéro."})
        if "midroll" in formats and not cues:
            raise serializers.ValidationError({"cue_points_seconds": "Ajoutez au moins un repère pour une campagne mid-roll."})
        attrs["cue_points_seconds"] = cues

        active_from = value("active_from")
        active_until = value("active_until")
        if active_from and active_until and active_until <= active_from:
            raise serializers.ValidationError({"active_until": "La fin doit être postérieure au début."})
        if int(value("frequency_cap_per_day", 3) or 0) < 1:
            raise serializers.ValidationError({"frequency_cap_per_day": "La fréquence quotidienne doit être au moins égale à 1."})
        return attrs


class AdminAdCampaignViewSet(viewsets.ModelViewSet):
    serializer_class = AdminAdCampaignSerializer
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = "core.view_adcampaign"
    http_method_names = ["get", "post", "put", "patch", "delete", "head", "options"]

    def get_required_permission(self):
        if self.action == "create":
            return "core.add_adcampaign"
        if self.action in {"update", "partial_update", "destroy", "set_status"}:
            return "core.change_adcampaign"
        return self.required_permission

    def get_queryset(self):
        queryset = AdCampaign.objects.prefetch_related("contents").select_related("created_by").order_by("-priority", "-created_at")
        state = self.request.query_params.get("status")
        search = self.request.query_params.get("search", "").strip()
        if state:
            queryset = queryset.filter(status=state)
        if search:
            queryset = queryset.filter(name__icontains=search) | queryset.filter(advertiser__icontains=search)
        return queryset

    def perform_create(self, serializer):
        campaign = serializer.save(created_by=self.request.user)
        audit(self.request, "ad_campaign.created", campaign, {"formats": campaign.formats, "delivery_mode": campaign.delivery_mode})

    def perform_update(self, serializer):
        campaign = serializer.save()
        audit(self.request, "ad_campaign.updated", campaign, {"status": campaign.status, "formats": campaign.formats})

    def destroy(self, request, *args, **kwargs):
        campaign = self.get_object()
        campaign.status = "archived"
        campaign.save(update_fields=["status", "updated_at"])
        audit(request, "ad_campaign.archived", campaign)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=True, methods=["post"], url_path="status")
    def set_status(self, request, pk=None):
        campaign = self.get_object()
        next_status = str(request.data.get("status", "")).strip().lower()
        if next_status not in {"draft", "active", "paused"}:
            raise serializers.ValidationError({"status": "Valeurs autorisées : draft, active, paused."})
        campaign.status = next_status
        campaign.save(update_fields=["status", "updated_at"])
        audit(request, "ad_campaign.status_changed", campaign, {"status": next_status})
        return Response(self.get_serializer(campaign).data)
