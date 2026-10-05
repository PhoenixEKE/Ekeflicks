from django.db.models import Max, Q
from rest_framework import serializers, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from apps.admin_api.security import AdminPermission, audit
from core.models import AdCampaign, Content


def _eligible_ad_contents():
    return Content.objects.filter(
        producer_submission_status="approved",
        type__in=("movie", "series"),
        video_assets__status="ready",
        video_assets__moderation_status="approved",
    ).distinct()


class AdminAdCampaignSerializer(serializers.ModelSerializer):
    content_ids = serializers.PrimaryKeyRelatedField(
        source="contents",
        queryset=Content.objects.all(),
        many=True,
        required=False,
    )
    content_cue_points = serializers.JSONField(required=False)
    content_details = serializers.SerializerMethodField()

    class Meta:
        model = AdCampaign
        fields = [
            "id", "name", "advertiser", "status", "delivery_mode", "formats",
            "media_url", "vast_tag_url", "image_url", "media_duration_seconds",
            "cta_label", "cta_url", "target_countries", "contextual_genres",
            "interest_tags", "target_age_min", "target_age_max", "content_ids",
            "content_details", "cue_points_seconds", "content_cue_points",
            "active_from", "active_until", "priority", "delivery_weight",
            "frequency_cap_per_day", "skip_after_seconds", "created_by",
            "created_at", "updated_at",
        ]
        read_only_fields = ["id", "content_details", "created_by", "created_at", "updated_at"]

    def get_content_details(self, obj):
        details = []
        for content in obj.contents.all():
            ready_assets = [
                asset for asset in content.video_assets.all()
                if asset.status == "ready" and asset.moderation_status == "approved"
            ]
            details.append({
                "id": content.pk,
                "title": content.title,
                "type": content.type,
                "duration": content.duration,
                "duration_seconds": max((asset.duration_seconds or 0 for asset in ready_assets), default=0),
                "poster_url": content.poster_url,
            })
        return details

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

        content_ids_were_submitted = "contents" in attrs
        selected_contents = attrs.get("contents")
        if selected_contents is None:
            selected_contents = list(self.instance.contents.all()) if self.instance else []
        selected_ids = {str(item.pk) for item in selected_contents}
        existing_ids = {str(pk) for pk in self.instance.contents.values_list("pk", flat=True)} if self.instance else set()
        if content_ids_were_submitted:
            eligible_ids = {str(pk) for pk in _eligible_ad_contents().values_list("pk", flat=True)}
            unavailable = [item.title for item in selected_contents if str(item.pk) not in eligible_ids and str(item.pk) not in existing_ids]
            if unavailable:
                raise serializers.ValidationError({
                    "content_ids": "Seuls les films et séries approuvés avec une vidéo prête peuvent être ciblés."
                })

        cues = value("cue_points_seconds", []) or []
        if not isinstance(cues, list):
            raise serializers.ValidationError({"cue_points_seconds": "Les repères mid-roll doivent être une liste de secondes."})
        try:
            cues = sorted(set(int(point) for point in cues))
        except (TypeError, ValueError):
            raise serializers.ValidationError({"cue_points_seconds": "Chaque repère doit être un nombre entier de secondes."})
        if any(point <= 0 for point in cues):
            raise serializers.ValidationError({"cue_points_seconds": "Chaque repère mid-roll doit être supérieur à zéro."})
        attrs["cue_points_seconds"] = cues

        explicit_content_cues = "content_cue_points" in attrs
        raw_content_cues = attrs.get("content_cue_points", getattr(self.instance, "content_cue_points", {}) if self.instance else {})
        if raw_content_cues is None:
            raw_content_cues = {}
        if not isinstance(raw_content_cues, dict):
            raise serializers.ValidationError({"content_cue_points": "Les repères doivent être associés à chaque titre."})
        content_cues = {}
        for raw_content_id, raw_points in raw_content_cues.items():
            content_id = str(raw_content_id)
            if content_id not in selected_ids:
                if explicit_content_cues:
                    raise serializers.ValidationError({"content_cue_points": "Les repères ne peuvent cibler que les titres sélectionnés."})
                continue
            if not isinstance(raw_points, list):
                raise serializers.ValidationError({"content_cue_points": "Chaque titre doit avoir une liste de secondes."})
            try:
                points = sorted(set(int(point) for point in raw_points))
            except (TypeError, ValueError):
                raise serializers.ValidationError({"content_cue_points": "Chaque repère doit être un nombre entier de secondes."})
            if any(point <= 0 for point in points):
                raise serializers.ValidationError({"content_cue_points": "Chaque repère mid-roll doit être supérieur à zéro."})
            content_cues[content_id] = points

        if "midroll" in formats:
            if selected_ids and (content_ids_were_submitted or explicit_content_cues):
                missing_titles = [
                    item.title for item in selected_contents
                    if not content_cues.get(str(item.pk))
                ]
                if missing_titles:
                    raise serializers.ValidationError({
                        "content_cue_points": "Ajoutez au moins un repère mid-roll pour chaque titre sélectionné."
                    })
            elif not selected_ids and not cues:
                raise serializers.ValidationError({"cue_points_seconds": "Ajoutez au moins un repère mid-roll pour une campagne globale."})
            elif selected_ids and not cues and not all(content_cues.get(content_id) for content_id in selected_ids):
                raise serializers.ValidationError({"content_cue_points": "Ajoutez des repères mid-roll pour les titres sélectionnés."})

        if explicit_content_cues or not self.instance:
            attrs["content_cue_points"] = content_cues

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
        queryset = AdCampaign.objects.prefetch_related("contents__video_assets").select_related("created_by").order_by("-priority", "-created_at")
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

    @action(detail=False, methods=["get"], url_path="content-options")
    def content_options(self, request):
        queryset = _eligible_ad_contents().annotate(
            duration_seconds=Max("video_assets__duration_seconds"),
        ).order_by("title")
        search = request.query_params.get("search", "").strip()
        if search:
            queryset = queryset.filter(Q(title__icontains=search) | Q(original_title__icontains=search))
        results = [{
            "id": content.pk,
            "title": content.title,
            "type": content.type,
            "duration": content.duration,
            "duration_seconds": content.duration_seconds or 0,
            "poster_url": content.poster_url,
        } for content in queryset[:200]]
        return Response(results)

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
