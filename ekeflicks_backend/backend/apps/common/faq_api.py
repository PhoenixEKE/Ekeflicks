import re
import unicodedata
from datetime import timedelta
from statistics import median

from rest_framework import status
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView
from django.utils import timezone

from core.models import FrequentlyAskedQuestion


def _language(request, data=None):
    data = data if isinstance(data, dict) else {}
    value = (data.get('language') or request.query_params.get('language') or request.headers.get('Accept-Language', 'fr'))
    value = str(value).split(',', 1)[0].split(';', 1)[0].split('-', 1)[0].split('_', 1)[0].lower()
    return value if value in {'fr', 'en'} else 'fr'


class FrequentlyAskedQuestionsView(APIView):
    permission_classes = [AllowAny]

    def get(self, request):
        audience = str(request.query_params.get('audience', 'producer')).lower()
        if audience not in {'producer', 'client', 'admin'}:
            return Response({'audience': 'Audience invalide.'}, status=status.HTTP_400_BAD_REQUEST)
        if audience == 'admin' and not (request.user.is_authenticated and request.user.is_staff):
            return Response({'detail': 'Accès réservé à l’administration.'}, status=status.HTTP_403_FORBIDDEN)

        language = _language(request)
        entries = FrequentlyAskedQuestion.objects.filter(audience=audience, is_published=True)
        result = []
        for entry in entries:
            question = getattr(entry, f'question_{language}')
            answer = getattr(entry, f'answer_{language}')
            if not question or not answer:
                continue
            result.append({
                'id': str(entry.id),
                'audience': entry.audience,
                'category': entry.category,
                'question': question,
                'answer': answer,
                'sort_order': entry.sort_order,
            })
        return Response({'audience': audience, 'language': language, 'results': result})


_STOP_WORDS = {
    'a', 'au', 'aux', 'avec', 'comment', 'dans', 'de', 'des', 'du', 'elle', 'en',
    'est', 'et', 'je', 'la', 'le', 'les', 'mon', 'ma', 'mes', 'ou', 'pour', 'que',
    'qui', 'quoi', 'sur', 'un', 'une', 'what', 'how', 'where', 'when', 'why', 'can',
    'do', 'does', 'the', 'my', 'is', 'are', 'to', 'of', 'and', 'for', 'i', 'me',
}


def _tokens(text):
    normalized = unicodedata.normalize('NFKD', str(text or '').lower())
    normalized = ''.join(c for c in normalized if not unicodedata.combining(c))
    return {word for word in re.findall(r'[a-z0-9]{2,}', normalized) if word not in _STOP_WORDS}


class ProducerEkeChatView(APIView):
    """Producer assistant grounded in published portal material and authorized data."""
    permission_classes = [AllowAny]

    @staticmethod
    def _support(reply, language):
        return Response({
            'reply': reply,
            'matches': [],
            'grounded': True,
            'needs_support': True,
            'support_path': '/support',
            'assistant': 'eke-producer-v1',
        })

    def _top10_answer(self, message, language):
        from core.models.recommendations import Top10Snapshot

        snapshot = (
            Top10Snapshot.objects.filter(scope=Top10Snapshot.SCOPE_GLOBAL, is_published=True)
            .prefetch_related('entries__content').order_by('-generated_at', '-id').first()
        )
        if snapshot is None:
            return None
        entries = list(snapshot.entries.select_related('content').order_by('position')[:10])
        if not entries:
            return None
        period_from = snapshot.window_start.date().isoformat()
        period_to = snapshot.window_end.date().isoformat()
        tokens = _tokens(message)
        asks_first = bool({'premier', 'premiere', 'position', 'numero', 'first', 'number', 'rank'} & tokens)
        if asks_first:
            entry = next((item for item in entries if item.position == 1), None)
            if entry is None:
                return None
            reply = (
                f"Le film en première position du Top 10 mondial publié est « {entry.content.title} » "
                f"pour la période du {period_from} au {period_to}. "
                "Le classement provient du dernier instantané publié par EKEFLICKS."
                if language == 'fr' else
                f"The published global Top 10 is led by “{entry.content.title}” for {period_from} to {period_to}. "
                "This ranking comes from EKEFLICKS’ latest published snapshot."
            )
        else:
            listing = '; '.join(f"{entry.position}. {entry.content.title}" for entry in entries)
            reply = (
                f"Voici le Top 10 mondial publié pour la période du {period_from} au {period_to}: {listing}."
                if language == 'fr' else
                f"Here is the published global Top 10 for {period_from} to {period_to}: {listing}."
            )
        return {'reply': reply, 'matches': [{'question': 'Top 10 publié', 'category': 'Analytics'}],
                'grounded': True, 'assistant': 'eke-producer-v1'}

    def _technical_spec_answer(self, message, language, request):
        if not request.user.is_authenticated:
            return self._support(
                'Connectez-vous à votre espace Producteur pour consulter le cahier des charges. '
                'Vous pouvez aussi poser une question générale dans la FAQ.' if language == 'fr' else
                'Sign in to your Producer portal to consult the technical specification, or ask a general question in the FAQ.',
                language,
            )
        from apps.catalog.technical_specifications import TechnicalSpecificationSerializer
        from core.models import TechnicalSpecification

        specification = TechnicalSpecification.objects.filter(is_published=True).order_by('-published_at', '-created_at').first()
        if specification is None:
            return None
        payload = TechnicalSpecificationSerializer(specification, context={'request': request}).data
        display = payload.get('display_text') or {}
        if language == 'en' and display.get('translation_language') != 'en':
            return self._support(
                'The English technical specification is not yet available. Contact Support for help.',
                language,
            )
        sections = display.get('sections') if isinstance(display, dict) else None
        sections = sections if isinstance(sections, list) else payload.get('sections', [])
        query = _tokens(message)
        ranked = []
        for section in sections:
            if not isinstance(section, dict):
                continue
            text = ' '.join(str(value) for value in section.values())
            score = len(query & _tokens(text))
            if score:
                ranked.append((score, section))
        ranked.sort(key=lambda item: -item[0])
        chosen = [section for _, section in ranked[:3]] or sections[:2]
        if not chosen:
            return None
        title = (display.get('title') if isinstance(display, dict) else None) or payload.get('title', 'Cahier des charges')
        result = [f"{title} — version {payload.get('version', '')}."]
        for section in chosen:
            section_title = section.get('title') or section.get('name') or ''
            items = section.get('items')
            item_text = []
            if isinstance(items, list):
                for item in items:
                    if isinstance(item, dict):
                        item_text.append(': '.join(str(item[key]) for key in ('label', 'value', 'description') if item.get(key)))
                    else:
                        item_text.append(str(item))
            elif section.get('description'):
                item_text.append(str(section['description']))
            result.append(f"{section_title}: {'; '.join(item_text)}" if section_title else '; '.join(item_text))
        return {'reply': '\n'.join(result), 'matches': [{'question': 'Cahier des charges publié', 'category': 'Dépôt'}],
                'grounded': True, 'assistant': 'eke-producer-v1'}

    def _contract_answer(self, message, language, request):
        user = request.user
        if not user.is_authenticated or not getattr(user, 'is_producer', False):
            return self._support(
                'Connectez-vous au compte Producteur concerné pour interroger son contrat.' if language == 'fr' else
                'Sign in to the relevant Producer account to ask about its agreement.', language)
        account = getattr(user, 'producer_account', None)
        if account is None or account.status in {'suspended', 'rejected', 'onboarding'}:
            return None
        from apps.auth.producer_contract_versions import get_current_contract_version
        from core.models import ProducerContractVersion, ProducerAgreement

        version = get_current_contract_version()
        contract = ProducerContractVersion.objects.filter(version=version).first()
        if contract is None or not contract.canonical_content.strip():
            return None
        text = contract.canonical_content
        contract_title = contract.title
        if language == 'en':
            translated = (contract.canonical_content_translations or {}).get('en')
            from apps.auth.producer_contract_versions import contract_content_sha256
            if (
                isinstance(translated, dict)
                and translated.get('source_hash') == contract_content_sha256(text)
                and translated.get('title_source_hash') == contract_content_sha256(contract.title)
                and translated.get('reviewed') is True
                and translated.get('title')
                and translated.get('value')
            ):
                text = translated.get('value') or text
                contract_title = translated['title']
            else:
                return self._support(
                    'The current agreement does not have a verified English translation yet. Contact Support for help.',
                    language,
                )
        accepted = account.agreements.filter(
            contract_version=version, status=ProducerAgreement.STATUS_SIGNED, signed_at__isnull=False,
        ).exists()
        query = _tokens(message)
        paragraphs = [part.strip() for part in re.split(r'\n+|(?<=[.!?])\s+', text) if part.strip()]
        ranked = sorted(((len(query & _tokens(part)), part) for part in paragraphs), reverse=True)
        excerpts = [part for score, part in ranked[:3] if score > 0]
        status_text = ('accepté' if accepted else 'à accepter') if language == 'fr' else ('accepted' if accepted else 'awaiting acceptance')
        header = (f"Contrat {contract_title}, version {version} ({status_text})." if language == 'fr'
                  else f"Agreement {contract_title}, version {version} ({status_text}).")
        if not excerpts:
            return self._support(
                header + (' Je n’ai pas trouvé la clause demandée. Ouvrez Mon contrat ou contactez Support.' if language == 'fr'
                          else ' I could not find the clause requested. Open My Agreement or contact Support.'), language)
        reply = header + '\n' + '\n'.join(excerpts)
        return {'reply': reply, 'matches': [{'question': 'Contrat producteur publié', 'category': 'Contrat'}],
                'grounded': True, 'assistant': 'eke-producer-v1'}

    def _owned_analytics_answer(self, message, language, request):
        from apps.common.permissions import is_active_producer_analytics_user
        if not is_active_producer_analytics_user(request.user):
            return self._support(
                'Les statistiques détaillées nécessitent un compte Producteur actif et vérifié. Pour une question sur votre accès, contactez le support.' if language == 'fr' else
                'Detailed statistics require an active, verified Producer account. Contact Support if you have an access question.', language)

        from core.models import Content
        from apps.analytics.services import (
            producer_content_video_analytics,
            producer_analytics_content_ids,
            producer_demo_analytics_enabled,
        )

        content_ids = producer_analytics_content_ids(request.user)
        if not content_ids:
            return None
        demo_data = producer_demo_analytics_enabled(request.user)
        demo_options = {'include_test': True} if demo_data else {}
        rows = producer_content_video_analytics(
            timezone.now() - timedelta(days=30), timezone.now(),
            allowed_content_ids=content_ids, limit=1000,
            **demo_options,
        )
        content_map = {str(item.id): item for item in Content.objects.filter(id__in=content_ids, producer=request.user)}
        query = _tokens(message)
        selected = []
        for row in rows:
            content = content_map.get(str(row.get('value')))
            if content is None:
                continue
            title_tokens = _tokens(content.title)
            title_score = len(query & title_tokens)
            if title_score:
                selected.append((title_score, row, content))
        if not selected:
            generic = {'pourquoi', 'mon', 'ma', 'mes', 'film', 'serie', 'est', 'pas', 'bien', 'vu', 'vue', 'vues',
                       'regarde', 'regardes', 'why', 'my', 'movie', 'series', 'film', 'is', 'not', 'well', 'seen',
                       'views', 'view', 'stats', 'statistics', 'statistique', 'statistiques', 'analytics'}
            if query - generic:
                return None
            # If the producer did not mention a title, summarize their lowest-viewed own titles.
            selected = [(0, row, content_map[str(row.get('value'))]) for row in rows if str(row.get('value')) in content_map]
        selected.sort(key=lambda item: (item[0] * -1, int(item[1].get('qualified_views') or 0)))
        if not selected:
            return None
        score, row, content = selected[0]
        if score == 0 and len(selected) > 1:
            chosen = selected[:3]
            if language == 'fr':
                lines = [f"{item.title}: {entry.get('qualified_views', 0)} vues qualifiées" for _, entry, item in chosen]
                reply = 'Voici vos contenus ayant le moins de vues qualifiées sur les 30 derniers jours: ' + '; '.join(lines)
            else:
                lines = [f"{item.title}: {entry.get('qualified_views', 0)} qualified views" for _, entry, item in chosen]
                reply = 'Your titles with the fewest qualified views in the last 30 days: ' + '; '.join(lines)
            if demo_data:
                reply += (' (données de démonstration incluses).' if language == 'fr' else ' (demonstration data included).')
            return {'reply': reply, 'matches': [{'question': 'Analytics propres au producteur', 'category': 'Analytics'}], 'grounded': True, 'assistant': 'eke-producer-v1'}

        views = int(row.get('qualified_views') or 0)
        starts = int(row.get('play_starts') or 0)
        viewers = int(row.get('unique_viewers') or 0)
        completion = float(row.get('completion_percent_avg') or 0)
        watch_minutes = round(float(row.get('watch_seconds') or 0) / 60, 1)
        peer_rows = [item for item in rows if str(item.get('value')) != str(row.get('value'))]
        peer_views = [int(item.get('qualified_views') or 0) for item in peer_rows]
        peer_completion = [float(item.get('completion_percent_avg') or 0) for item in peer_rows]
        observations = []
        if peer_rows:
            view_median = median(peer_views)
            completion_median = median(peer_completion)
            if views < view_median:
                observations.append(
                    f"{views} vues qualifiées, sous la médiane de vos autres contenus ({view_median:g})"
                    if language == 'fr' else
                    f"{views} qualified views, below the median for your other titles ({view_median:g})"
                )
            if completion < completion_median:
                observations.append(
                    f"complétion sous la médiane de vos autres contenus ({completion_median:.1f}%)"
                    if language == 'fr' else
                    f"completion below the median for your other titles ({completion_median:.1f}%)"
                )
        if starts == 0:
            reading = ('Aucun démarrage n’est mesuré sur cette période.' if language == 'fr'
                       else 'No play starts were measured in this period.')
        elif observations:
            reading = ('Par rapport à vos autres contenus: ' if language == 'fr' else 'Compared with your other titles: ') + '; '.join(observations) + '.'
        else:
            reading = ('Les chiffres décrivent la portée et la rétention, mais ne démontrent pas à eux seuls une cause.' if language == 'fr'
                       else 'These figures describe reach and retention but do not by themselves prove a cause.')
        reply = (
            f"Sur les 30 derniers jours, « {content.title} » a enregistré {views} vues qualifiées, "
            f"{starts} démarrages, {viewers} spectateurs uniques, {completion:.1f}% de complétion moyenne "
            f"et {watch_minutes} minutes regardées. {reading}"
            if language == 'fr' else
            f"In the last 30 days, “{content.title}” had {views} qualified views, {starts} play starts, "
            f"{viewers} unique viewers, {completion:.1f}% average completion and {watch_minutes} minutes watched. {reading}"
        )
        if demo_data:
            reply += (' Données de démonstration incluses.' if language == 'fr' else ' Demonstration data is included.')
        return {'reply': reply, 'matches': [{'question': 'Analytics propres au producteur', 'category': 'Analytics'}],
                'grounded': True, 'assistant': 'eke-producer-v1'}

    def post(self, request):
        message = str(request.data.get('message', '')).strip()
        if not message:
            return Response({'message': 'Saisissez une question.'}, status=status.HTTP_400_BAD_REQUEST)
        if len(message) > 1500:
            return Response({'message': 'La question doit faire au maximum 1 500 caractères.'}, status=status.HTTP_400_BAD_REQUEST)

        language = _language(request, request.data)
        query = _tokens(message)

        if {'top10', 'top', 'classement', 'ranking'} & query or ('10' in query and {'premier', 'premiere', 'position', 'film', 'serie', 'title'} & query):
            answer = self._top10_answer(message, language)
            if answer is not None:
                return Response(answer)
            return self._support(
                'Aucun Top 10 publié n’est disponible pour le moment. Envoyez votre question depuis Support.' if language == 'fr' else
                'There is no published Top 10 available right now. Send your question through Support.', language)
        if {'cahier', 'charges', 'specification', 'technical'} & query:
            answer = self._technical_spec_answer(message, language, request)
            if answer is not None:
                return Response(answer)
            return self._support(
                'Je ne trouve pas de cahier des charges publié correspondant. Contactez Support pour obtenir de l’aide.' if language == 'fr' else
                'I cannot find a matching published technical specification. Contact Support for help.', language)
        if {'contrat', 'contract', 'agreement', 'clause', 'exclusivite', 'exclusivity'} & query:
            answer = self._contract_answer(message, language, request)
            if answer is not None:
                return Response(answer)
            return self._support(
                'Je ne trouve pas le contrat publié ou la clause demandée. Consultez Mon contrat ou contactez Support.' if language == 'fr' else
                'I cannot find the published agreement or requested clause. Check My Agreement or contact Support.', language)
        if {'statistique', 'statistiques', 'analytics', 'vues', 'view', 'views', 'regarde', 'regardes', 'well', 'vu', 'vue'} & query:
            try:
                answer = self._owned_analytics_answer(message, language, request)
            except Exception:
                answer = self._support(
                    'Je ne peux pas obtenir les statistiques vérifiées pour le moment. Envoyez votre question depuis Support.' if language == 'fr' else
                    'I cannot retrieve verified statistics right now. Send your question through Support.', language)
            if answer is not None:
                return Response(answer)
            return self._support(
                'Je ne trouve pas de statistique vérifiée pour cette question. Vérifiez le titre et la période dans Analytics, ou contactez Support.' if language == 'fr' else
                'I cannot find verified statistics for that question. Check the title and period in Analytics, or contact Support.', language)

        ranked = []
        for faq in FrequentlyAskedQuestion.objects.filter(audience='producer', is_published=True):
            question = getattr(faq, f'question_{language}')
            answer = getattr(faq, f'answer_{language}')
            if not question or not answer:
                continue
            question_tokens = _tokens(question)
            answer_tokens = _tokens(answer)
            overlap = len(query & question_tokens) * 2.0 + len(query & answer_tokens) * 0.65
            denominator = max(1.0, len(query) + len(question_tokens) * 0.5)
            score = overlap / denominator
            if query and _tokens(message) == question_tokens:
                score += 1.0
            if score >= 0.13:
                ranked.append((score, faq, question, answer))
        ranked.sort(key=lambda row: (-row[0], row[1].sort_order))
        matches = ranked[:3]

        if not matches:
            reply = (
                'Je ne trouve pas de réponse vérifiée à cette question. Envoyez-la depuis Support pour obtenir une réponse de l’équipe EKEFLICKS.'
                if language == 'fr' else
                'I cannot find a verified answer to that question. Send it through Support to get a reply from the EKEFLICKS team.'
            )
            return self._support(reply, language)

        reply = '\n\n'.join(answer for _, _, _, answer in matches)
        return Response({
            'reply': reply,
            'matches': [
                {'question': question, 'answer': answer, 'category': faq.category, 'score': round(score, 3)}
                for score, faq, question, answer in matches
            ],
            'grounded': True,
            'assistant': 'eke-producer-v1',
        })
