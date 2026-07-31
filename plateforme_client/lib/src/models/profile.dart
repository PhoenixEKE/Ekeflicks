//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'profile.g.dart';

/// Profile
///
/// Properties:
/// * [id] 
/// * [user] 
/// * [name] 
/// * [type] 
/// * [avatar] 
/// * [avatarUrl] 
/// * [country] 
/// * [age] 
/// * [phone] 
/// * [isActive] 
@BuiltValue()
abstract class Profile implements Built<Profile, ProfileBuilder> {
  @BuiltValueField(wireName: r'id')
  int? get id;

  @BuiltValueField(wireName: r'user')
  int? get user;

  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'type')
  ProfileTypeEnum? get type;
  // enum typeEnum {  main,  child,  guest,  };

  @BuiltValueField(wireName: r'avatar')
  String? get avatar;

  @BuiltValueField(wireName: r'avatar_url')
  String? get avatarUrl;

  @BuiltValueField(wireName: r'country')
  ProfileCountryEnum? get country;
  // enum countryEnum {  AF,  AX,  AL,  DZ,  AS,  AD,  AO,  AI,  AQ,  AG,  AR,  AM,  AW,  AU,  AT,  AZ,  BS,  BH,  BD,  BB,  BY,  BE,  BZ,  BJ,  BM,  BT,  BO,  BQ,  BA,  BW,  BV,  BR,  IO,  BN,  BG,  BF,  BI,  CV,  KH,  CM,  CA,  KY,  CF,  TD,  CL,  CN,  CX,  CC,  CO,  KM,  CG,  CD,  CK,  CR,  CI,  HR,  CU,  CW,  CY,  CZ,  DK,  DJ,  DM,  DO,  EC,  EG,  SV,  GQ,  ER,  EE,  SZ,  ET,  FK,  FO,  FJ,  FI,  FR,  GF,  PF,  TF,  GA,  GM,  GE,  DE,  GH,  GI,  GR,  GL,  GD,  GP,  GU,  GT,  GG,  GN,  GW,  GY,  HT,  HM,  VA,  HN,  HK,  HU,  IS,  IN,  ID,  IR,  IQ,  IE,  IM,  IL,  IT,  JM,  JP,  JE,  JO,  KZ,  KE,  KI,  KW,  KG,  LA,  LV,  LB,  LS,  LR,  LY,  LI,  LT,  LU,  MO,  MG,  MW,  MY,  MV,  ML,  MT,  MH,  MQ,  MR,  MU,  YT,  MX,  FM,  MD,  MC,  MN,  ME,  MS,  MA,  MZ,  MM,  NA,  NR,  NP,  NL,  NC,  NZ,  NI,  NE,  NG,  NU,  NF,  KP,  MK,  MP,  NO,  OM,  PK,  PW,  PS,  PA,  PG,  PY,  PE,  PH,  PN,  PL,  PT,  PR,  QA,  RE,  RO,  RU,  RW,  BL,  SH,  KN,  LC,  MF,  PM,  VC,  WS,  SM,  ST,  SA,  SN,  RS,  SC,  SL,  SG,  SX,  SK,  SI,  SB,  SO,  ZA,  GS,  KR,  SS,  ES,  LK,  SD,  SR,  SJ,  SE,  CH,  SY,  TW,  TJ,  TZ,  TH,  TL,  TG,  TK,  TO,  TT,  TN,  TR,  TM,  TC,  TV,  UG,  UA,  AE,  GB,  UM,  US,  UY,  UZ,  VU,  VE,  VN,  VG,  VI,  WF,  EH,  YE,  ZM,  ZW,  };

  @BuiltValueField(wireName: r'age')
  int? get age;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  @BuiltValueField(wireName: r'is_active')
  bool? get isActive;

  Profile._();

  factory Profile([void updates(ProfileBuilder b)]) = _$Profile;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProfileBuilder b) {
    b.isActive = true;
  }

  @BuiltValueSerializer(custom: true)
  static Serializer<Profile> get serializer => _$ProfileSerializer();
}

class _$ProfileSerializer implements PrimitiveSerializer<Profile> {
  @override
  final Iterable<Type> types = const [Profile, _$Profile];

  @override
  final String wireName = r'Profile';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Profile object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.id != null) {
      yield r'id';
      yield serializers.serialize(
        object.id,
        specifiedType: const FullType(int),
      );
    }
    if (object.user != null) {
      yield r'user';
      yield serializers.serialize(
        object.user,
        specifiedType: const FullType(int),
      );
    }
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.type != null) {
      yield r'type';
      yield serializers.serialize(
        object.type,
        specifiedType: const FullType(ProfileTypeEnum),
      );
    }
    if (object.avatar != null) {
      yield r'avatar';
      yield serializers.serialize(
        object.avatar,
        specifiedType: const FullType(String),
      );
    }
    if (object.avatarUrl != null) {
      yield r'avatar_url';
      yield serializers.serialize(
        object.avatarUrl,
        specifiedType: const FullType(String),
      );
    }
    if (object.country != null) {
      yield r'country';
      yield serializers.serialize(
        object.country,
        specifiedType: const FullType(ProfileCountryEnum),
      );
    }
    if (object.age != null) {
      yield r'age';
      yield serializers.serialize(
        object.age,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.phone != null) {
      yield r'phone';
      yield serializers.serialize(
        object.phone,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.isActive != null) {
      yield r'is_active';
      yield serializers.serialize(
        object.isActive,
        specifiedType: const FullType(bool),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    Profile object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProfileBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.id = valueDes;
          break;
        case r'user':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.user = valueDes;
          break;
        case r'name':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.name = valueDes;
          break;
        case r'type':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProfileTypeEnum),
          ) as ProfileTypeEnum;
          result.type = valueDes;
          break;
        case r'avatar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.avatar = valueDes;
          break;
        case r'avatar_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.avatarUrl = valueDes;
          break;
        case r'country':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProfileCountryEnum),
          ) as ProfileCountryEnum;
          result.country = valueDes;
          break;
        case r'age':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.age = valueDes;
          break;
        case r'phone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.phone = valueDes;
          break;
        case r'is_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.isActive = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Profile deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProfileBuilder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class ProfileTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'main')
  static const ProfileTypeEnum main = _$profileTypeEnum_main;
  @BuiltValueEnumConst(wireName: r'child')
  static const ProfileTypeEnum child = _$profileTypeEnum_child;
  @BuiltValueEnumConst(wireName: r'guest')
  static const ProfileTypeEnum guest = _$profileTypeEnum_guest;

  static Serializer<ProfileTypeEnum> get serializer => _$profileTypeEnumSerializer;

  const ProfileTypeEnum._(String name): super(name);

  static BuiltSet<ProfileTypeEnum> get values => _$profileTypeEnumValues;
  static ProfileTypeEnum valueOf(String name) => _$profileTypeEnumValueOf(name);
}

class ProfileCountryEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'AF')
  static const ProfileCountryEnum AF = _$profileCountryEnum_AF;
  @BuiltValueEnumConst(wireName: r'AX')
  static const ProfileCountryEnum AX = _$profileCountryEnum_AX;
  @BuiltValueEnumConst(wireName: r'AL')
  static const ProfileCountryEnum AL = _$profileCountryEnum_AL;
  @BuiltValueEnumConst(wireName: r'DZ')
  static const ProfileCountryEnum DZ = _$profileCountryEnum_DZ;
  @BuiltValueEnumConst(wireName: r'AS')
  static const ProfileCountryEnum AS = _$profileCountryEnum_AS;
  @BuiltValueEnumConst(wireName: r'AD')
  static const ProfileCountryEnum AD = _$profileCountryEnum_AD;
  @BuiltValueEnumConst(wireName: r'AO')
  static const ProfileCountryEnum AO = _$profileCountryEnum_AO;
  @BuiltValueEnumConst(wireName: r'AI')
  static const ProfileCountryEnum AI = _$profileCountryEnum_AI;
  @BuiltValueEnumConst(wireName: r'AQ')
  static const ProfileCountryEnum AQ = _$profileCountryEnum_AQ;
  @BuiltValueEnumConst(wireName: r'AG')
  static const ProfileCountryEnum AG = _$profileCountryEnum_AG;
  @BuiltValueEnumConst(wireName: r'AR')
  static const ProfileCountryEnum AR = _$profileCountryEnum_AR;
  @BuiltValueEnumConst(wireName: r'AM')
  static const ProfileCountryEnum AM = _$profileCountryEnum_AM;
  @BuiltValueEnumConst(wireName: r'AW')
  static const ProfileCountryEnum AW = _$profileCountryEnum_AW;
  @BuiltValueEnumConst(wireName: r'AU')
  static const ProfileCountryEnum AU = _$profileCountryEnum_AU;
  @BuiltValueEnumConst(wireName: r'AT')
  static const ProfileCountryEnum AT = _$profileCountryEnum_AT;
  @BuiltValueEnumConst(wireName: r'AZ')
  static const ProfileCountryEnum AZ = _$profileCountryEnum_AZ;
  @BuiltValueEnumConst(wireName: r'BS')
  static const ProfileCountryEnum BS = _$profileCountryEnum_BS;
  @BuiltValueEnumConst(wireName: r'BH')
  static const ProfileCountryEnum BH = _$profileCountryEnum_BH;
  @BuiltValueEnumConst(wireName: r'BD')
  static const ProfileCountryEnum BD = _$profileCountryEnum_BD;
  @BuiltValueEnumConst(wireName: r'BB')
  static const ProfileCountryEnum BB = _$profileCountryEnum_BB;
  @BuiltValueEnumConst(wireName: r'BY')
  static const ProfileCountryEnum BY = _$profileCountryEnum_BY;
  @BuiltValueEnumConst(wireName: r'BE')
  static const ProfileCountryEnum BE = _$profileCountryEnum_BE;
  @BuiltValueEnumConst(wireName: r'BZ')
  static const ProfileCountryEnum BZ = _$profileCountryEnum_BZ;
  @BuiltValueEnumConst(wireName: r'BJ')
  static const ProfileCountryEnum BJ = _$profileCountryEnum_BJ;
  @BuiltValueEnumConst(wireName: r'BM')
  static const ProfileCountryEnum BM = _$profileCountryEnum_BM;
  @BuiltValueEnumConst(wireName: r'BT')
  static const ProfileCountryEnum BT = _$profileCountryEnum_BT;
  @BuiltValueEnumConst(wireName: r'BO')
  static const ProfileCountryEnum BO = _$profileCountryEnum_BO;
  @BuiltValueEnumConst(wireName: r'BQ')
  static const ProfileCountryEnum BQ = _$profileCountryEnum_BQ;
  @BuiltValueEnumConst(wireName: r'BA')
  static const ProfileCountryEnum BA = _$profileCountryEnum_BA;
  @BuiltValueEnumConst(wireName: r'BW')
  static const ProfileCountryEnum BW = _$profileCountryEnum_BW;
  @BuiltValueEnumConst(wireName: r'BV')
  static const ProfileCountryEnum BV = _$profileCountryEnum_BV;
  @BuiltValueEnumConst(wireName: r'BR')
  static const ProfileCountryEnum BR = _$profileCountryEnum_BR;
  @BuiltValueEnumConst(wireName: r'IO')
  static const ProfileCountryEnum IO = _$profileCountryEnum_IO;
  @BuiltValueEnumConst(wireName: r'BN')
  static const ProfileCountryEnum BN = _$profileCountryEnum_BN;
  @BuiltValueEnumConst(wireName: r'BG')
  static const ProfileCountryEnum BG = _$profileCountryEnum_BG;
  @BuiltValueEnumConst(wireName: r'BF')
  static const ProfileCountryEnum BF = _$profileCountryEnum_BF;
  @BuiltValueEnumConst(wireName: r'BI')
  static const ProfileCountryEnum BI = _$profileCountryEnum_BI;
  @BuiltValueEnumConst(wireName: r'CV')
  static const ProfileCountryEnum CV = _$profileCountryEnum_CV;
  @BuiltValueEnumConst(wireName: r'KH')
  static const ProfileCountryEnum KH = _$profileCountryEnum_KH;
  @BuiltValueEnumConst(wireName: r'CM')
  static const ProfileCountryEnum CM = _$profileCountryEnum_CM;
  @BuiltValueEnumConst(wireName: r'CA')
  static const ProfileCountryEnum CA = _$profileCountryEnum_CA;
  @BuiltValueEnumConst(wireName: r'KY')
  static const ProfileCountryEnum KY = _$profileCountryEnum_KY;
  @BuiltValueEnumConst(wireName: r'CF')
  static const ProfileCountryEnum CF = _$profileCountryEnum_CF;
  @BuiltValueEnumConst(wireName: r'TD')
  static const ProfileCountryEnum TD = _$profileCountryEnum_TD;
  @BuiltValueEnumConst(wireName: r'CL')
  static const ProfileCountryEnum CL = _$profileCountryEnum_CL;
  @BuiltValueEnumConst(wireName: r'CN')
  static const ProfileCountryEnum CN = _$profileCountryEnum_CN;
  @BuiltValueEnumConst(wireName: r'CX')
  static const ProfileCountryEnum CX = _$profileCountryEnum_CX;
  @BuiltValueEnumConst(wireName: r'CC')
  static const ProfileCountryEnum CC = _$profileCountryEnum_CC;
  @BuiltValueEnumConst(wireName: r'CO')
  static const ProfileCountryEnum CO = _$profileCountryEnum_CO;
  @BuiltValueEnumConst(wireName: r'KM')
  static const ProfileCountryEnum KM = _$profileCountryEnum_KM;
  @BuiltValueEnumConst(wireName: r'CG')
  static const ProfileCountryEnum CG = _$profileCountryEnum_CG;
  @BuiltValueEnumConst(wireName: r'CD')
  static const ProfileCountryEnum CD = _$profileCountryEnum_CD;
  @BuiltValueEnumConst(wireName: r'CK')
  static const ProfileCountryEnum CK = _$profileCountryEnum_CK;
  @BuiltValueEnumConst(wireName: r'CR')
  static const ProfileCountryEnum CR = _$profileCountryEnum_CR;
  @BuiltValueEnumConst(wireName: r'CI')
  static const ProfileCountryEnum CI = _$profileCountryEnum_CI;
  @BuiltValueEnumConst(wireName: r'HR')
  static const ProfileCountryEnum HR = _$profileCountryEnum_HR;
  @BuiltValueEnumConst(wireName: r'CU')
  static const ProfileCountryEnum CU = _$profileCountryEnum_CU;
  @BuiltValueEnumConst(wireName: r'CW')
  static const ProfileCountryEnum CW = _$profileCountryEnum_CW;
  @BuiltValueEnumConst(wireName: r'CY')
  static const ProfileCountryEnum CY = _$profileCountryEnum_CY;
  @BuiltValueEnumConst(wireName: r'CZ')
  static const ProfileCountryEnum CZ = _$profileCountryEnum_CZ;
  @BuiltValueEnumConst(wireName: r'DK')
  static const ProfileCountryEnum DK = _$profileCountryEnum_DK;
  @BuiltValueEnumConst(wireName: r'DJ')
  static const ProfileCountryEnum DJ = _$profileCountryEnum_DJ;
  @BuiltValueEnumConst(wireName: r'DM')
  static const ProfileCountryEnum DM = _$profileCountryEnum_DM;
  @BuiltValueEnumConst(wireName: r'DO')
  static const ProfileCountryEnum DO = _$profileCountryEnum_DO;
  @BuiltValueEnumConst(wireName: r'EC')
  static const ProfileCountryEnum EC = _$profileCountryEnum_EC;
  @BuiltValueEnumConst(wireName: r'EG')
  static const ProfileCountryEnum EG = _$profileCountryEnum_EG;
  @BuiltValueEnumConst(wireName: r'SV')
  static const ProfileCountryEnum SV = _$profileCountryEnum_SV;
  @BuiltValueEnumConst(wireName: r'GQ')
  static const ProfileCountryEnum GQ = _$profileCountryEnum_GQ;
  @BuiltValueEnumConst(wireName: r'ER')
  static const ProfileCountryEnum ER = _$profileCountryEnum_ER;
  @BuiltValueEnumConst(wireName: r'EE')
  static const ProfileCountryEnum EE = _$profileCountryEnum_EE;
  @BuiltValueEnumConst(wireName: r'SZ')
  static const ProfileCountryEnum SZ = _$profileCountryEnum_SZ;
  @BuiltValueEnumConst(wireName: r'ET')
  static const ProfileCountryEnum ET = _$profileCountryEnum_ET;
  @BuiltValueEnumConst(wireName: r'FK')
  static const ProfileCountryEnum FK = _$profileCountryEnum_FK;
  @BuiltValueEnumConst(wireName: r'FO')
  static const ProfileCountryEnum FO = _$profileCountryEnum_FO;
  @BuiltValueEnumConst(wireName: r'FJ')
  static const ProfileCountryEnum FJ = _$profileCountryEnum_FJ;
  @BuiltValueEnumConst(wireName: r'FI')
  static const ProfileCountryEnum FI = _$profileCountryEnum_FI;
  @BuiltValueEnumConst(wireName: r'FR')
  static const ProfileCountryEnum FR = _$profileCountryEnum_FR;
  @BuiltValueEnumConst(wireName: r'GF')
  static const ProfileCountryEnum GF = _$profileCountryEnum_GF;
  @BuiltValueEnumConst(wireName: r'PF')
  static const ProfileCountryEnum PF = _$profileCountryEnum_PF;
  @BuiltValueEnumConst(wireName: r'TF')
  static const ProfileCountryEnum TF = _$profileCountryEnum_TF;
  @BuiltValueEnumConst(wireName: r'GA')
  static const ProfileCountryEnum GA = _$profileCountryEnum_GA;
  @BuiltValueEnumConst(wireName: r'GM')
  static const ProfileCountryEnum GM = _$profileCountryEnum_GM;
  @BuiltValueEnumConst(wireName: r'GE')
  static const ProfileCountryEnum GE = _$profileCountryEnum_GE;
  @BuiltValueEnumConst(wireName: r'DE')
  static const ProfileCountryEnum DE = _$profileCountryEnum_DE;
  @BuiltValueEnumConst(wireName: r'GH')
  static const ProfileCountryEnum GH = _$profileCountryEnum_GH;
  @BuiltValueEnumConst(wireName: r'GI')
  static const ProfileCountryEnum GI = _$profileCountryEnum_GI;
  @BuiltValueEnumConst(wireName: r'GR')
  static const ProfileCountryEnum GR = _$profileCountryEnum_GR;
  @BuiltValueEnumConst(wireName: r'GL')
  static const ProfileCountryEnum GL = _$profileCountryEnum_GL;
  @BuiltValueEnumConst(wireName: r'GD')
  static const ProfileCountryEnum GD = _$profileCountryEnum_GD;
  @BuiltValueEnumConst(wireName: r'GP')
  static const ProfileCountryEnum GP = _$profileCountryEnum_GP;
  @BuiltValueEnumConst(wireName: r'GU')
  static const ProfileCountryEnum GU = _$profileCountryEnum_GU;
  @BuiltValueEnumConst(wireName: r'GT')
  static const ProfileCountryEnum GT = _$profileCountryEnum_GT;
  @BuiltValueEnumConst(wireName: r'GG')
  static const ProfileCountryEnum GG = _$profileCountryEnum_GG;
  @BuiltValueEnumConst(wireName: r'GN')
  static const ProfileCountryEnum GN = _$profileCountryEnum_GN;
  @BuiltValueEnumConst(wireName: r'GW')
  static const ProfileCountryEnum GW = _$profileCountryEnum_GW;
  @BuiltValueEnumConst(wireName: r'GY')
  static const ProfileCountryEnum GY = _$profileCountryEnum_GY;
  @BuiltValueEnumConst(wireName: r'HT')
  static const ProfileCountryEnum HT = _$profileCountryEnum_HT;
  @BuiltValueEnumConst(wireName: r'HM')
  static const ProfileCountryEnum HM = _$profileCountryEnum_HM;
  @BuiltValueEnumConst(wireName: r'VA')
  static const ProfileCountryEnum VA = _$profileCountryEnum_VA;
  @BuiltValueEnumConst(wireName: r'HN')
  static const ProfileCountryEnum HN = _$profileCountryEnum_HN;
  @BuiltValueEnumConst(wireName: r'HK')
  static const ProfileCountryEnum HK = _$profileCountryEnum_HK;
  @BuiltValueEnumConst(wireName: r'HU')
  static const ProfileCountryEnum HU = _$profileCountryEnum_HU;
  @BuiltValueEnumConst(wireName: r'IS')
  static const ProfileCountryEnum IS = _$profileCountryEnum_IS;
  @BuiltValueEnumConst(wireName: r'IN')
  static const ProfileCountryEnum IN = _$profileCountryEnum_IN;
  @BuiltValueEnumConst(wireName: r'ID')
  static const ProfileCountryEnum ID = _$profileCountryEnum_ID;
  @BuiltValueEnumConst(wireName: r'IR')
  static const ProfileCountryEnum IR = _$profileCountryEnum_IR;
  @BuiltValueEnumConst(wireName: r'IQ')
  static const ProfileCountryEnum IQ = _$profileCountryEnum_IQ;
  @BuiltValueEnumConst(wireName: r'IE')
  static const ProfileCountryEnum IE = _$profileCountryEnum_IE;
  @BuiltValueEnumConst(wireName: r'IM')
  static const ProfileCountryEnum IM = _$profileCountryEnum_IM;
  @BuiltValueEnumConst(wireName: r'IL')
  static const ProfileCountryEnum IL = _$profileCountryEnum_IL;
  @BuiltValueEnumConst(wireName: r'IT')
  static const ProfileCountryEnum IT = _$profileCountryEnum_IT;
  @BuiltValueEnumConst(wireName: r'JM')
  static const ProfileCountryEnum JM = _$profileCountryEnum_JM;
  @BuiltValueEnumConst(wireName: r'JP')
  static const ProfileCountryEnum JP = _$profileCountryEnum_JP;
  @BuiltValueEnumConst(wireName: r'JE')
  static const ProfileCountryEnum JE = _$profileCountryEnum_JE;
  @BuiltValueEnumConst(wireName: r'JO')
  static const ProfileCountryEnum JO = _$profileCountryEnum_JO;
  @BuiltValueEnumConst(wireName: r'KZ')
  static const ProfileCountryEnum KZ = _$profileCountryEnum_KZ;
  @BuiltValueEnumConst(wireName: r'KE')
  static const ProfileCountryEnum KE = _$profileCountryEnum_KE;
  @BuiltValueEnumConst(wireName: r'KI')
  static const ProfileCountryEnum KI = _$profileCountryEnum_KI;
  @BuiltValueEnumConst(wireName: r'KW')
  static const ProfileCountryEnum KW = _$profileCountryEnum_KW;
  @BuiltValueEnumConst(wireName: r'KG')
  static const ProfileCountryEnum KG = _$profileCountryEnum_KG;
  @BuiltValueEnumConst(wireName: r'LA')
  static const ProfileCountryEnum LA = _$profileCountryEnum_LA;
  @BuiltValueEnumConst(wireName: r'LV')
  static const ProfileCountryEnum LV = _$profileCountryEnum_LV;
  @BuiltValueEnumConst(wireName: r'LB')
  static const ProfileCountryEnum LB = _$profileCountryEnum_LB;
  @BuiltValueEnumConst(wireName: r'LS')
  static const ProfileCountryEnum LS = _$profileCountryEnum_LS;
  @BuiltValueEnumConst(wireName: r'LR')
  static const ProfileCountryEnum LR = _$profileCountryEnum_LR;
  @BuiltValueEnumConst(wireName: r'LY')
  static const ProfileCountryEnum LY = _$profileCountryEnum_LY;
  @BuiltValueEnumConst(wireName: r'LI')
  static const ProfileCountryEnum LI = _$profileCountryEnum_LI;
  @BuiltValueEnumConst(wireName: r'LT')
  static const ProfileCountryEnum LT = _$profileCountryEnum_LT;
  @BuiltValueEnumConst(wireName: r'LU')
  static const ProfileCountryEnum LU = _$profileCountryEnum_LU;
  @BuiltValueEnumConst(wireName: r'MO')
  static const ProfileCountryEnum MO = _$profileCountryEnum_MO;
  @BuiltValueEnumConst(wireName: r'MG')
  static const ProfileCountryEnum MG = _$profileCountryEnum_MG;
  @BuiltValueEnumConst(wireName: r'MW')
  static const ProfileCountryEnum MW = _$profileCountryEnum_MW;
  @BuiltValueEnumConst(wireName: r'MY')
  static const ProfileCountryEnum MY = _$profileCountryEnum_MY;
  @BuiltValueEnumConst(wireName: r'MV')
  static const ProfileCountryEnum MV = _$profileCountryEnum_MV;
  @BuiltValueEnumConst(wireName: r'ML')
  static const ProfileCountryEnum ML = _$profileCountryEnum_ML;
  @BuiltValueEnumConst(wireName: r'MT')
  static const ProfileCountryEnum MT = _$profileCountryEnum_MT;
  @BuiltValueEnumConst(wireName: r'MH')
  static const ProfileCountryEnum MH = _$profileCountryEnum_MH;
  @BuiltValueEnumConst(wireName: r'MQ')
  static const ProfileCountryEnum MQ = _$profileCountryEnum_MQ;
  @BuiltValueEnumConst(wireName: r'MR')
  static const ProfileCountryEnum MR = _$profileCountryEnum_MR;
  @BuiltValueEnumConst(wireName: r'MU')
  static const ProfileCountryEnum MU = _$profileCountryEnum_MU;
  @BuiltValueEnumConst(wireName: r'YT')
  static const ProfileCountryEnum YT = _$profileCountryEnum_YT;
  @BuiltValueEnumConst(wireName: r'MX')
  static const ProfileCountryEnum MX = _$profileCountryEnum_MX;
  @BuiltValueEnumConst(wireName: r'FM')
  static const ProfileCountryEnum FM = _$profileCountryEnum_FM;
  @BuiltValueEnumConst(wireName: r'MD')
  static const ProfileCountryEnum MD = _$profileCountryEnum_MD;
  @BuiltValueEnumConst(wireName: r'MC')
  static const ProfileCountryEnum MC = _$profileCountryEnum_MC;
  @BuiltValueEnumConst(wireName: r'MN')
  static const ProfileCountryEnum MN = _$profileCountryEnum_MN;
  @BuiltValueEnumConst(wireName: r'ME')
  static const ProfileCountryEnum ME = _$profileCountryEnum_ME;
  @BuiltValueEnumConst(wireName: r'MS')
  static const ProfileCountryEnum MS = _$profileCountryEnum_MS;
  @BuiltValueEnumConst(wireName: r'MA')
  static const ProfileCountryEnum MA = _$profileCountryEnum_MA;
  @BuiltValueEnumConst(wireName: r'MZ')
  static const ProfileCountryEnum MZ = _$profileCountryEnum_MZ;
  @BuiltValueEnumConst(wireName: r'MM')
  static const ProfileCountryEnum MM = _$profileCountryEnum_MM;
  @BuiltValueEnumConst(wireName: r'NA')
  static const ProfileCountryEnum NA = _$profileCountryEnum_NA;
  @BuiltValueEnumConst(wireName: r'NR')
  static const ProfileCountryEnum NR = _$profileCountryEnum_NR;
  @BuiltValueEnumConst(wireName: r'NP')
  static const ProfileCountryEnum NP = _$profileCountryEnum_NP;
  @BuiltValueEnumConst(wireName: r'NL')
  static const ProfileCountryEnum NL = _$profileCountryEnum_NL;
  @BuiltValueEnumConst(wireName: r'NC')
  static const ProfileCountryEnum NC = _$profileCountryEnum_NC;
  @BuiltValueEnumConst(wireName: r'NZ')
  static const ProfileCountryEnum NZ = _$profileCountryEnum_NZ;
  @BuiltValueEnumConst(wireName: r'NI')
  static const ProfileCountryEnum NI = _$profileCountryEnum_NI;
  @BuiltValueEnumConst(wireName: r'NE')
  static const ProfileCountryEnum NE = _$profileCountryEnum_NE;
  @BuiltValueEnumConst(wireName: r'NG')
  static const ProfileCountryEnum NG = _$profileCountryEnum_NG;
  @BuiltValueEnumConst(wireName: r'NU')
  static const ProfileCountryEnum NU = _$profileCountryEnum_NU;
  @BuiltValueEnumConst(wireName: r'NF')
  static const ProfileCountryEnum NF = _$profileCountryEnum_NF;
  @BuiltValueEnumConst(wireName: r'KP')
  static const ProfileCountryEnum KP = _$profileCountryEnum_KP;
  @BuiltValueEnumConst(wireName: r'MK')
  static const ProfileCountryEnum MK = _$profileCountryEnum_MK;
  @BuiltValueEnumConst(wireName: r'MP')
  static const ProfileCountryEnum MP = _$profileCountryEnum_MP;
  @BuiltValueEnumConst(wireName: r'NO')
  static const ProfileCountryEnum NO = _$profileCountryEnum_NO;
  @BuiltValueEnumConst(wireName: r'OM')
  static const ProfileCountryEnum OM = _$profileCountryEnum_OM;
  @BuiltValueEnumConst(wireName: r'PK')
  static const ProfileCountryEnum PK = _$profileCountryEnum_PK;
  @BuiltValueEnumConst(wireName: r'PW')
  static const ProfileCountryEnum PW = _$profileCountryEnum_PW;
  @BuiltValueEnumConst(wireName: r'PS')
  static const ProfileCountryEnum PS = _$profileCountryEnum_PS;
  @BuiltValueEnumConst(wireName: r'PA')
  static const ProfileCountryEnum PA = _$profileCountryEnum_PA;
  @BuiltValueEnumConst(wireName: r'PG')
  static const ProfileCountryEnum PG = _$profileCountryEnum_PG;
  @BuiltValueEnumConst(wireName: r'PY')
  static const ProfileCountryEnum PY = _$profileCountryEnum_PY;
  @BuiltValueEnumConst(wireName: r'PE')
  static const ProfileCountryEnum PE = _$profileCountryEnum_PE;
  @BuiltValueEnumConst(wireName: r'PH')
  static const ProfileCountryEnum PH = _$profileCountryEnum_PH;
  @BuiltValueEnumConst(wireName: r'PN')
  static const ProfileCountryEnum PN = _$profileCountryEnum_PN;
  @BuiltValueEnumConst(wireName: r'PL')
  static const ProfileCountryEnum PL = _$profileCountryEnum_PL;
  @BuiltValueEnumConst(wireName: r'PT')
  static const ProfileCountryEnum PT = _$profileCountryEnum_PT;
  @BuiltValueEnumConst(wireName: r'PR')
  static const ProfileCountryEnum PR = _$profileCountryEnum_PR;
  @BuiltValueEnumConst(wireName: r'QA')
  static const ProfileCountryEnum QA = _$profileCountryEnum_QA;
  @BuiltValueEnumConst(wireName: r'RE')
  static const ProfileCountryEnum RE = _$profileCountryEnum_RE;
  @BuiltValueEnumConst(wireName: r'RO')
  static const ProfileCountryEnum RO = _$profileCountryEnum_RO;
  @BuiltValueEnumConst(wireName: r'RU')
  static const ProfileCountryEnum RU = _$profileCountryEnum_RU;
  @BuiltValueEnumConst(wireName: r'RW')
  static const ProfileCountryEnum RW = _$profileCountryEnum_RW;
  @BuiltValueEnumConst(wireName: r'BL')
  static const ProfileCountryEnum BL = _$profileCountryEnum_BL;
  @BuiltValueEnumConst(wireName: r'SH')
  static const ProfileCountryEnum SH = _$profileCountryEnum_SH;
  @BuiltValueEnumConst(wireName: r'KN')
  static const ProfileCountryEnum KN = _$profileCountryEnum_KN;
  @BuiltValueEnumConst(wireName: r'LC')
  static const ProfileCountryEnum LC = _$profileCountryEnum_LC;
  @BuiltValueEnumConst(wireName: r'MF')
  static const ProfileCountryEnum MF = _$profileCountryEnum_MF;
  @BuiltValueEnumConst(wireName: r'PM')
  static const ProfileCountryEnum PM = _$profileCountryEnum_PM;
  @BuiltValueEnumConst(wireName: r'VC')
  static const ProfileCountryEnum VC = _$profileCountryEnum_VC;
  @BuiltValueEnumConst(wireName: r'WS')
  static const ProfileCountryEnum WS = _$profileCountryEnum_WS;
  @BuiltValueEnumConst(wireName: r'SM')
  static const ProfileCountryEnum SM = _$profileCountryEnum_SM;
  @BuiltValueEnumConst(wireName: r'ST')
  static const ProfileCountryEnum ST = _$profileCountryEnum_ST;
  @BuiltValueEnumConst(wireName: r'SA')
  static const ProfileCountryEnum SA = _$profileCountryEnum_SA;
  @BuiltValueEnumConst(wireName: r'SN')
  static const ProfileCountryEnum SN = _$profileCountryEnum_SN;
  @BuiltValueEnumConst(wireName: r'RS')
  static const ProfileCountryEnum RS = _$profileCountryEnum_RS;
  @BuiltValueEnumConst(wireName: r'SC')
  static const ProfileCountryEnum SC = _$profileCountryEnum_SC;
  @BuiltValueEnumConst(wireName: r'SL')
  static const ProfileCountryEnum SL = _$profileCountryEnum_SL;
  @BuiltValueEnumConst(wireName: r'SG')
  static const ProfileCountryEnum SG = _$profileCountryEnum_SG;
  @BuiltValueEnumConst(wireName: r'SX')
  static const ProfileCountryEnum SX = _$profileCountryEnum_SX;
  @BuiltValueEnumConst(wireName: r'SK')
  static const ProfileCountryEnum SK = _$profileCountryEnum_SK;
  @BuiltValueEnumConst(wireName: r'SI')
  static const ProfileCountryEnum SI = _$profileCountryEnum_SI;
  @BuiltValueEnumConst(wireName: r'SB')
  static const ProfileCountryEnum SB = _$profileCountryEnum_SB;
  @BuiltValueEnumConst(wireName: r'SO')
  static const ProfileCountryEnum SO = _$profileCountryEnum_SO;
  @BuiltValueEnumConst(wireName: r'ZA')
  static const ProfileCountryEnum ZA = _$profileCountryEnum_ZA;
  @BuiltValueEnumConst(wireName: r'GS')
  static const ProfileCountryEnum GS = _$profileCountryEnum_GS;
  @BuiltValueEnumConst(wireName: r'KR')
  static const ProfileCountryEnum KR = _$profileCountryEnum_KR;
  @BuiltValueEnumConst(wireName: r'SS')
  static const ProfileCountryEnum SS = _$profileCountryEnum_SS;
  @BuiltValueEnumConst(wireName: r'ES')
  static const ProfileCountryEnum ES = _$profileCountryEnum_ES;
  @BuiltValueEnumConst(wireName: r'LK')
  static const ProfileCountryEnum LK = _$profileCountryEnum_LK;
  @BuiltValueEnumConst(wireName: r'SD')
  static const ProfileCountryEnum SD = _$profileCountryEnum_SD;
  @BuiltValueEnumConst(wireName: r'SR')
  static const ProfileCountryEnum SR = _$profileCountryEnum_SR;
  @BuiltValueEnumConst(wireName: r'SJ')
  static const ProfileCountryEnum SJ = _$profileCountryEnum_SJ;
  @BuiltValueEnumConst(wireName: r'SE')
  static const ProfileCountryEnum SE = _$profileCountryEnum_SE;
  @BuiltValueEnumConst(wireName: r'CH')
  static const ProfileCountryEnum CH = _$profileCountryEnum_CH;
  @BuiltValueEnumConst(wireName: r'SY')
  static const ProfileCountryEnum SY = _$profileCountryEnum_SY;
  @BuiltValueEnumConst(wireName: r'TW')
  static const ProfileCountryEnum TW = _$profileCountryEnum_TW;
  @BuiltValueEnumConst(wireName: r'TJ')
  static const ProfileCountryEnum TJ = _$profileCountryEnum_TJ;
  @BuiltValueEnumConst(wireName: r'TZ')
  static const ProfileCountryEnum TZ = _$profileCountryEnum_TZ;
  @BuiltValueEnumConst(wireName: r'TH')
  static const ProfileCountryEnum TH = _$profileCountryEnum_TH;
  @BuiltValueEnumConst(wireName: r'TL')
  static const ProfileCountryEnum TL = _$profileCountryEnum_TL;
  @BuiltValueEnumConst(wireName: r'TG')
  static const ProfileCountryEnum TG = _$profileCountryEnum_TG;
  @BuiltValueEnumConst(wireName: r'TK')
  static const ProfileCountryEnum TK = _$profileCountryEnum_TK;
  @BuiltValueEnumConst(wireName: r'TO')
  static const ProfileCountryEnum TO = _$profileCountryEnum_TO;
  @BuiltValueEnumConst(wireName: r'TT')
  static const ProfileCountryEnum TT = _$profileCountryEnum_TT;
  @BuiltValueEnumConst(wireName: r'TN')
  static const ProfileCountryEnum TN = _$profileCountryEnum_TN;
  @BuiltValueEnumConst(wireName: r'TR')
  static const ProfileCountryEnum TR = _$profileCountryEnum_TR;
  @BuiltValueEnumConst(wireName: r'TM')
  static const ProfileCountryEnum TM = _$profileCountryEnum_TM;
  @BuiltValueEnumConst(wireName: r'TC')
  static const ProfileCountryEnum TC = _$profileCountryEnum_TC;
  @BuiltValueEnumConst(wireName: r'TV')
  static const ProfileCountryEnum TV = _$profileCountryEnum_TV;
  @BuiltValueEnumConst(wireName: r'UG')
  static const ProfileCountryEnum UG = _$profileCountryEnum_UG;
  @BuiltValueEnumConst(wireName: r'UA')
  static const ProfileCountryEnum UA = _$profileCountryEnum_UA;
  @BuiltValueEnumConst(wireName: r'AE')
  static const ProfileCountryEnum AE = _$profileCountryEnum_AE;
  @BuiltValueEnumConst(wireName: r'GB')
  static const ProfileCountryEnum GB = _$profileCountryEnum_GB;
  @BuiltValueEnumConst(wireName: r'UM')
  static const ProfileCountryEnum UM = _$profileCountryEnum_UM;
  @BuiltValueEnumConst(wireName: r'US')
  static const ProfileCountryEnum US = _$profileCountryEnum_US;
  @BuiltValueEnumConst(wireName: r'UY')
  static const ProfileCountryEnum UY = _$profileCountryEnum_UY;
  @BuiltValueEnumConst(wireName: r'UZ')
  static const ProfileCountryEnum UZ = _$profileCountryEnum_UZ;
  @BuiltValueEnumConst(wireName: r'VU')
  static const ProfileCountryEnum VU = _$profileCountryEnum_VU;
  @BuiltValueEnumConst(wireName: r'VE')
  static const ProfileCountryEnum VE = _$profileCountryEnum_VE;
  @BuiltValueEnumConst(wireName: r'VN')
  static const ProfileCountryEnum VN = _$profileCountryEnum_VN;
  @BuiltValueEnumConst(wireName: r'VG')
  static const ProfileCountryEnum VG = _$profileCountryEnum_VG;
  @BuiltValueEnumConst(wireName: r'VI')
  static const ProfileCountryEnum VI = _$profileCountryEnum_VI;
  @BuiltValueEnumConst(wireName: r'WF')
  static const ProfileCountryEnum WF = _$profileCountryEnum_WF;
  @BuiltValueEnumConst(wireName: r'EH')
  static const ProfileCountryEnum EH = _$profileCountryEnum_EH;
  @BuiltValueEnumConst(wireName: r'YE')
  static const ProfileCountryEnum YE = _$profileCountryEnum_YE;
  @BuiltValueEnumConst(wireName: r'ZM')
  static const ProfileCountryEnum ZM = _$profileCountryEnum_ZM;
  @BuiltValueEnumConst(wireName: r'ZW')
  static const ProfileCountryEnum ZW = _$profileCountryEnum_ZW;

  static Serializer<ProfileCountryEnum> get serializer => _$profileCountryEnumSerializer;

  const ProfileCountryEnum._(String name): super(name);

  static BuiltSet<ProfileCountryEnum> get values => _$profileCountryEnumValues;
  static ProfileCountryEnum valueOf(String name) => _$profileCountryEnumValueOf(name);
}

