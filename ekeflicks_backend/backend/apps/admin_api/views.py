import hashlib
from datetime import timedelta

from django.contrib.auth import authenticate
from django.contrib.auth.models import Group, Permission
from django.db import transaction
from django.utils import timezone
from rest_framework import exceptions, generics, status, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken

from apps.admin_api.security import AdminPermission, audit, verify_totp
from apps.admin_api.serializers import (
    AdminSessionSerializer, AdminUserSerializer, PermissionSerializer,
    RoleAssignmentSerializer, RoleSerializer,
)
from apps.auth.serializers import AccountClosureRequestSerializer, EmailChangeSupportRequestSerializer
from core.models.users import AccountClosureRequest, AdminMFADevice, EmailChangeSupportRequest, User, UserSession


def token_hash(value):
    return hashlib.sha256(value.encode()).hexdigest()


def issue_session(user, request):
    refresh = RefreshToken.for_user(user)
    expires_at = timezone.now() + timedelta(seconds=int(refresh['exp']) - int(timezone.now().timestamp()))
    session = UserSession.objects.create(
        user=user,
        device_id=request.data.get('device_id', '')[:255],
        device_type=request.data.get('device_type', 'admin-web')[:50],
        expires_at=expires_at,
    )
    refresh['sid'] = session.pk
    access = refresh.access_token
    access['sid'] = session.pk
    value = str(refresh)
    session.refresh_token = token_hash(value)
    session.save(update_fields=['refresh_token'])
    return session, value, str(access)


class AdminLoginView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        user = authenticate(request, email=request.data.get('email'), password=request.data.get('password'))
        if not user or not user.is_active or not user.is_staff:
            raise exceptions.AuthenticationFailed('Identifiants administrateur incorrects.')
        try:
            device = user.admin_mfa_device
        except AdminMFADevice.DoesNotExist as exc:
            raise exceptions.AuthenticationFailed('Le MFA doit être configuré par un super-administrateur.') from exc
        if not device.confirmed_at or not verify_totp(device, request.data.get('otp', '')):
            raise exceptions.AuthenticationFailed('Code MFA invalide ou déjà utilisé.')
        session, refresh, access = issue_session(user, request)
        return Response({'access': access, 'refresh': refresh, 'session_id': session.pk, 'user': AdminUserSerializer(user).data})


class AdminRefreshView(generics.GenericAPIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    @transaction.atomic
    def post(self, request):
        value = request.data.get('refresh', '')
        try:
            old = RefreshToken(value)
            session = UserSession.objects.select_for_update().get(pk=old.get('sid'), is_active=True)
        except Exception as exc:
            raise exceptions.AuthenticationFailed('Session expirée ou révoquée.') from exc
        if not hashlib.sha256(value.encode()).hexdigest() == session.refresh_token or session.expires_at <= timezone.now():
            raise exceptions.AuthenticationFailed('Session expirée ou révoquée.')
        try:
            old.blacklist()
        except AttributeError:
            pass
        session.is_active = False
        session.save(update_fields=['is_active'])
        new_session, refresh, access = issue_session(session.user, request)
        return Response({'access': access, 'refresh': refresh, 'session_id': new_session.pk})


class SessionViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, AdminPermission]
    serializer_class = AdminSessionSerializer

    def get_queryset(self):
        return UserSession.objects.filter(user=self.request.user).order_by('-created_at')

    def get_serializer_context(self):
        context = super().get_serializer_context()
        context['session_id'] = getattr(self.request.auth, 'payload', {}).get('sid')
        return context

    @action(detail=True, methods=['post'])
    def revoke(self, request, pk=None):
        session = self.get_object()
        session.is_active = False
        session.refresh_token = ''
        session.save(update_fields=['is_active', 'refresh_token'])
        audit(request, 'session.revoke', session)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['post'], url_path='revoke-all')
    def revoke_all(self, request):
        count = self.get_queryset().filter(is_active=True).update(is_active=False, refresh_token='')
        audit(request, 'session.revoke_all', request.user, {'count': count})
        return Response({'revoked': count})


class AdminUserViewSet(viewsets.ModelViewSet):
    serializer_class = AdminUserSerializer
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_user'

    def get_queryset(self):
        queryset = User.objects.prefetch_related('groups').order_by('-created_at')
        kind = self.request.query_params.get('kind')
        if kind == 'producer': queryset = queryset.filter(is_producer=True)
        if kind == 'customer': queryset = queryset.filter(is_producer=False, is_staff=False)
        search = self.request.query_params.get('search')
        if search: queryset = queryset.filter(email__icontains=search)
        return queryset

    def get_required_permission(self):
        return 'core.change_user' if self.action not in ('list', 'retrieve') else self.required_permission

    def perform_update(self, serializer):
        if not (self.request.user.is_superuser or self.request.user.has_perm('core.change_user')):
            raise exceptions.PermissionDenied()
        user = serializer.save()
        audit(self.request, 'user.update', user, {'fields': list(serializer.validated_data)})

    @action(detail=True, methods=['put'], permission_classes=[IsAuthenticated, AdminPermission])
    def roles(self, request, pk=None):
        if not request.user.is_superuser:
            raise exceptions.PermissionDenied('Seul un super-administrateur peut affecter des rôles.')
        serializer = RoleAssignmentSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = self.get_object()
        user.groups.set(serializer.validated_data['roles'])
        user.is_staff = True
        user.save(update_fields=['is_staff'])
        audit(request, 'user.roles', user, {'roles': [r.name for r in serializer.validated_data['roles']]})
        return Response(AdminUserSerializer(user).data)


class RoleViewSet(viewsets.ModelViewSet):
    queryset = Group.objects.prefetch_related('permissions').order_by('name')
    serializer_class = RoleSerializer
    permission_classes = [IsAuthenticated, AdminPermission]

    def initial(self, request, *args, **kwargs):
        super().initial(request, *args, **kwargs)
        if not request.user.is_superuser:
            raise exceptions.PermissionDenied('Gestion réservée au super-administrateur.')

    def perform_create(self, serializer):
        role = serializer.save()
        audit(self.request, 'role.create', role, {'permissions': list(role.permissions.values_list('codename', flat=True))})

    def perform_update(self, serializer):
        role = serializer.save()
        audit(self.request, 'role.update', role, {'permissions': list(role.permissions.values_list('codename', flat=True))})


class PermissionListView(generics.ListAPIView):
    queryset = Permission.objects.select_related('content_type').order_by('content_type__app_label', 'codename')
    serializer_class = PermissionSerializer
    permission_classes = [IsAuthenticated, AdminPermission]


class ClaimViewSet(viewsets.ReadOnlyModelViewSet):
    permission_classes = [IsAuthenticated, AdminPermission]
    required_permission = 'core.view_accountclosurerequest'

    def get_queryset(self):
        claim_type = self.request.query_params.get('type', 'closure')
        model = EmailChangeSupportRequest if claim_type == 'email' else AccountClosureRequest
        queryset = model.objects.select_related('user', 'reviewed_by').order_by('-created_at')
        state = self.request.query_params.get('status')
        return queryset.filter(status=state) if state else queryset

    def get_serializer_class(self):
        return EmailChangeSupportRequestSerializer if self.request.query_params.get('type') == 'email' else AccountClosureRequestSerializer
