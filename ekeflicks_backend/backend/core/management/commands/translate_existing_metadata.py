from django.core.management.base import BaseCommand

from apps.catalog.tasks import translate_content_fields, translate_reference_texts
from core.models import Content, Genre, TechnicalSpecification


class Command(BaseCommand):
    help = 'Queue bilingual translations for existing producer metadata and the current technical specification.'

    def add_arguments(self, parser):
        parser.add_argument('--limit', type=int, default=0)

    def handle(self, *args, **options):
        limit = options['limit']
        contents = Content.objects.order_by('created_at').values_list('pk', flat=True)
        genres = Genre.objects.order_by('pk').values_list('pk', flat=True)
        specifications = TechnicalSpecification.objects.filter(
            is_published=True,
        ).values_list('pk', flat=True)
        if limit > 0:
            contents = contents[:limit]
            genres = genres[:limit]
            specifications = specifications[:limit]

        queued = 0
        for content_id in contents.iterator(chunk_size=500):
            translate_content_fields.delay(str(content_id))
            queued += 1
        for genre_id in genres.iterator(chunk_size=500):
            translate_reference_texts.delay('genre', str(genre_id))
            queued += 1
        for specification_id in specifications.iterator(chunk_size=500):
            translate_reference_texts.delay('technical_specification', str(specification_id))
            queued += 1

        self.stdout.write(self.style.SUCCESS(f'Queued {queued} translation task(s).'))
