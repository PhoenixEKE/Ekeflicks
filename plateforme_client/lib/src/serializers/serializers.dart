//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:app_ekeflicks/src/serializers/date_serializer.dart';
import 'package:app_ekeflicks/src/models/date.dart';

import 'package:app_ekeflicks/src/models/auth_logout_all_create_request.dart';
import 'package:app_ekeflicks/src/models/auth_logout_create_request.dart';
import 'package:app_ekeflicks/src/models/password_reset_confirm.dart';
import 'package:app_ekeflicks/src/models/password_reset_request.dart';
import 'package:app_ekeflicks/src/models/profile.dart';
import 'package:app_ekeflicks/src/models/profile_create.dart';
import 'package:app_ekeflicks/src/models/profiles_list200_response.dart';
import 'package:app_ekeflicks/src/models/token_obtain_pair.dart';
import 'package:app_ekeflicks/src/models/token_refresh.dart';
import 'package:app_ekeflicks/src/models/user.dart';
import 'package:app_ekeflicks/src/models/user_create.dart';
import 'package:app_ekeflicks/src/models/users_list200_response.dart';

part 'serializers.g.dart';

@SerializersFor([
  AuthLogoutAllCreateRequest,
  AuthLogoutCreateRequest,
  PasswordResetConfirm,
  PasswordResetRequest,
  Profile,
  ProfileCreate,
  ProfilesList200Response,
  TokenObtainPair,
  TokenRefresh,
  User,
  UserCreate,
  UsersList200Response,
  UserSubscriptionEnum,
  UserRoleEnum,
  UserStatusEnum,
])
Serializers serializers = (_$serializers.toBuilder()
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
