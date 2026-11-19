from drf_yasg import openapi


API_INFO = openapi.Info(
    title='EkeFlicks API',
    default_version='v1',
    description=(
        'API backend for EkeFlicks. Toutes les routes metier sont versionnees '
        'sous /api/v1/. Les listes utilisent le contrat Page et les erreurs le '
        'media type application/problem+json.'
    ),
    terms_of_service='https://www.ekeflicks.com/terms/',
    contact=openapi.Contact(email='support@ekeflicks.com'),
    license=openapi.License(name='Proprietary'),
)

