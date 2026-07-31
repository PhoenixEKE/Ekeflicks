from rest_framework import permissions


class IsAdminOrReadOnly(permissions.BasePermission):
    """Allow public reads, but reserve writes for staff users."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return bool(request.user and request.user.is_authenticated and request.user.is_staff)


class IsStaffWriteAuthenticatedRead(permissions.BasePermission):
    """Allow authenticated reads, but reserve writes for staff users."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return bool(request.user and request.user.is_authenticated)
        return bool(request.user and request.user.is_authenticated and request.user.is_staff)


def is_producer_user(user):
    return bool(
        user
        and user.is_authenticated
        and (user.is_staff or getattr(user, 'is_producer', False))
    )


class IsAdminOrProducerOwnerOrReadOnly(permissions.BasePermission):
    """Allow public reads and producer writes on owned content."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return is_producer_user(request.user)

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        if request.user.is_staff:
            return True
        return getattr(obj, 'producer_id', None) == request.user.id


class IsStaffOrProducerAssetOwner(permissions.BasePermission):
    """Allow staff or the owning producer to manage a video asset."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return bool(request.user and request.user.is_authenticated)
        return is_producer_user(request.user)

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return bool(request.user and request.user.is_authenticated)
        if request.user.is_staff:
            return True
        return getattr(obj.content, 'producer_id', None) == request.user.id


class IsAdminOrProducerRelatedContentOrReadOnly(permissions.BasePermission):
    """Allow producers to manage objects attached to their own content."""

    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return True
        return is_producer_user(request.user)

    def has_object_permission(self, request, view, obj):
        if request.method in permissions.SAFE_METHODS:
            return True
        if request.user.is_staff:
            return True
        return getattr(obj.content, 'producer_id', None) == request.user.id
