//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'profile_create.g.dart';

/// ProfileCreate
///
/// Properties:
/// * [name] 
/// * [type] 
/// * [avatar] 
/// * [country] 
/// * [age] 
/// * [phone] 
@BuiltValue()
abstract class ProfileCreate implements Built<ProfileCreate, ProfileCreateBuilder> {
  @BuiltValueField(wireName: r'name')
  String get name;

  @BuiltValueField(wireName: r'type')
  ProfileCreateTypeEnum? get type;
  // enum typeEnum {  main,  child,  guest,  };

  @BuiltValueField(wireName: r'avatar')
  String? get avatar;

  @BuiltValueField(wireName: r'country')
  ProfileCreateCountryEnum? get country;
  // enum countryEnum {  AF,  AX,  AL,  DZ,  AS,  AD,  AO,  AI,  AQ,  AG,  AR,  AM,  AW,  AU,  AT,  AZ,  BS,  BH,  BD,  BB,  BY,  BE,  BZ,  BJ,  BM,  BT,  BO,  BQ,  BA,  BW,  BV,  BR,  IO,  BN,  BG,  BF,  BI,  CV,  KH,  CM,  CA,  KY,  CF,  TD,  CL,  CN,  CX,  CC,  CO,  KM,  CG,  CD,  CK,  CR,  CI,  HR,  CU,  CW,  CY,  CZ,  DK,  DJ,  DM,  DO,  EC,  EG,  SV,  GQ,  ER,  EE,  SZ,  ET,  FK,  FO,  FJ,  FI,  FR,  GF,  PF,  TF,  GA,  GM,  GE,  DE,  GH,  GI,  GR,  GL,  GD,  GP,  GU,  GT,  GG,  GN,  GW,  GY,  HT,  HM,  VA,  HN,  HK,  HU,  IS,  IN,  ID,  IR,  IQ,  IE,  IM,  IL,  IT,  JM,  JP,  JE,  JO,  KZ,  KE,  KI,  KW,  KG,  LA,  LV,  LB,  LS,  LR,  LY,  LI,  LT,  LU,  MO,  MG,  MW,  MY,  MV,  ML,  MT,  MH,  MQ,  MR,  MU,  YT,  MX,  FM,  MD,  MC,  MN,  ME,  MS,  MA,  MZ,  MM,  NA,  NR,  NP,  NL,  NC,  NZ,  NI,  NE,  NG,  NU,  NF,  KP,  MK,  MP,  NO,  OM,  PK,  PW,  PS,  PA,  PG,  PY,  PE,  PH,  PN,  PL,  PT,  PR,  QA,  RE,  RO,  RU,  RW,  BL,  SH,  KN,  LC,  MF,  PM,  VC,  WS,  SM,  ST,  SA,  SN,  RS,  SC,  SL,  SG,  SX,  SK,  SI,  SB,  SO,  ZA,  GS,  KR,  SS,  ES,  LK,  SD,  SR,  SJ,  SE,  CH,  SY,  TW,  TJ,  TZ,  TH,  TL,  TG,  TK,  TO,  TT,  TN,  TR,  TM,  TC,  TV,  UG,  UA,  AE,  GB,  UM,  US,  UY,  UZ,  VU,  VE,  VN,  VG,  VI,  WF,  EH,  YE,  ZM,  ZW,  };

  @BuiltValueField(wireName: r'age')
  int? get age;

  @BuiltValueField(wireName: r'phone')
  String? get phone;

  ProfileCreate._();

  factory ProfileCreate([void updates(ProfileCreateBuilder b)]) = _$ProfileCreate;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ProfileCreateBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ProfileCreate> get serializer => _$ProfileCreateSerializer();
}

class _$ProfileCreateSerializer implements PrimitiveSerializer<ProfileCreate> {
  @override
  final Iterable<Type> types = const [ProfileCreate, _$ProfileCreate];

  @override
  final String wireName = r'ProfileCreate';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ProfileCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'name';
    yield serializers.serialize(
      object.name,
      specifiedType: const FullType(String),
    );
    if (object.type != null) {
      yield r'type';
      yield serializers.serialize(
        object.type,
        specifiedType: const FullType(ProfileCreateTypeEnum),
      );
    }
    if (object.avatar != null) {
      yield r'avatar';
      yield serializers.serialize(
        object.avatar,
        specifiedType: const FullType(String),
      );
    }
    if (object.country != null) {
      yield r'country';
      yield serializers.serialize(
        object.country,
        specifiedType: const FullType(ProfileCreateCountryEnum),
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
  }

  @override
  Object serialize(
    Serializers serializers,
    ProfileCreate object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ProfileCreateBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
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
            specifiedType: const FullType(ProfileCreateTypeEnum),
          ) as ProfileCreateTypeEnum;
          result.type = valueDes;
          break;
        case r'avatar':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.avatar = valueDes;
          break;
        case r'country':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ProfileCreateCountryEnum),
          ) as ProfileCreateCountryEnum;
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
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ProfileCreate deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ProfileCreateBuilder();
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

class ProfileCreateTypeEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'main')
  static const ProfileCreateTypeEnum main = _$profileCreateTypeEnum_main;
  @BuiltValueEnumConst(wireName: r'child')
  static const ProfileCreateTypeEnum child = _$profileCreateTypeEnum_child;
  @BuiltValueEnumConst(wireName: r'guest')
  static const ProfileCreateTypeEnum guest = _$profileCreateTypeEnum_guest;

  static Serializer<ProfileCreateTypeEnum> get serializer => _$profileCreateTypeEnumSerializer;

  const ProfileCreateTypeEnum._(String name): super(name);

  static BuiltSet<ProfileCreateTypeEnum> get values => _$profileCreateTypeEnumValues;
  static ProfileCreateTypeEnum valueOf(String name) => _$profileCreateTypeEnumValueOf(name);
}

class ProfileCreateCountryEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'AF')
  static const ProfileCreateCountryEnum AF = _$profileCreateCountryEnum_AF;
  @BuiltValueEnumConst(wireName: r'AX')
  static const ProfileCreateCountryEnum AX = _$profileCreateCountryEnum_AX;
  @BuiltValueEnumConst(wireName: r'AL')
  static const ProfileCreateCountryEnum AL = _$profileCreateCountryEnum_AL;
  @BuiltValueEnumConst(wireName: r'DZ')
  static const ProfileCreateCountryEnum DZ = _$profileCreateCountryEnum_DZ;
  @BuiltValueEnumConst(wireName: r'AS')
  static const ProfileCreateCountryEnum AS = _$profileCreateCountryEnum_AS;
  @BuiltValueEnumConst(wireName: r'AD')
  static const ProfileCreateCountryEnum AD = _$profileCreateCountryEnum_AD;
  @BuiltValueEnumConst(wireName: r'AO')
  static const ProfileCreateCountryEnum AO = _$profileCreateCountryEnum_AO;
  @BuiltValueEnumConst(wireName: r'AI')
  static const ProfileCreateCountryEnum AI = _$profileCreateCountryEnum_AI;
  @BuiltValueEnumConst(wireName: r'AQ')
  static const ProfileCreateCountryEnum AQ = _$profileCreateCountryEnum_AQ;
  @BuiltValueEnumConst(wireName: r'AG')
  static const ProfileCreateCountryEnum AG = _$profileCreateCountryEnum_AG;
  @BuiltValueEnumConst(wireName: r'AR')
  static const ProfileCreateCountryEnum AR = _$profileCreateCountryEnum_AR;
  @BuiltValueEnumConst(wireName: r'AM')
  static const ProfileCreateCountryEnum AM = _$profileCreateCountryEnum_AM;
  @BuiltValueEnumConst(wireName: r'AW')
  static const ProfileCreateCountryEnum AW = _$profileCreateCountryEnum_AW;
  @BuiltValueEnumConst(wireName: r'AU')
  static const ProfileCreateCountryEnum AU = _$profileCreateCountryEnum_AU;
  @BuiltValueEnumConst(wireName: r'AT')
  static const ProfileCreateCountryEnum AT = _$profileCreateCountryEnum_AT;
  @BuiltValueEnumConst(wireName: r'AZ')
  static const ProfileCreateCountryEnum AZ = _$profileCreateCountryEnum_AZ;
  @BuiltValueEnumConst(wireName: r'BS')
  static const ProfileCreateCountryEnum BS = _$profileCreateCountryEnum_BS;
  @BuiltValueEnumConst(wireName: r'BH')
  static const ProfileCreateCountryEnum BH = _$profileCreateCountryEnum_BH;
  @BuiltValueEnumConst(wireName: r'BD')
  static const ProfileCreateCountryEnum BD = _$profileCreateCountryEnum_BD;
  @BuiltValueEnumConst(wireName: r'BB')
  static const ProfileCreateCountryEnum BB = _$profileCreateCountryEnum_BB;
  @BuiltValueEnumConst(wireName: r'BY')
  static const ProfileCreateCountryEnum BY = _$profileCreateCountryEnum_BY;
  @BuiltValueEnumConst(wireName: r'BE')
  static const ProfileCreateCountryEnum BE = _$profileCreateCountryEnum_BE;
  @BuiltValueEnumConst(wireName: r'BZ')
  static const ProfileCreateCountryEnum BZ = _$profileCreateCountryEnum_BZ;
  @BuiltValueEnumConst(wireName: r'BJ')
  static const ProfileCreateCountryEnum BJ = _$profileCreateCountryEnum_BJ;
  @BuiltValueEnumConst(wireName: r'BM')
  static const ProfileCreateCountryEnum BM = _$profileCreateCountryEnum_BM;
  @BuiltValueEnumConst(wireName: r'BT')
  static const ProfileCreateCountryEnum BT = _$profileCreateCountryEnum_BT;
  @BuiltValueEnumConst(wireName: r'BO')
  static const ProfileCreateCountryEnum BO = _$profileCreateCountryEnum_BO;
  @BuiltValueEnumConst(wireName: r'BQ')
  static const ProfileCreateCountryEnum BQ = _$profileCreateCountryEnum_BQ;
  @BuiltValueEnumConst(wireName: r'BA')
  static const ProfileCreateCountryEnum BA = _$profileCreateCountryEnum_BA;
  @BuiltValueEnumConst(wireName: r'BW')
  static const ProfileCreateCountryEnum BW = _$profileCreateCountryEnum_BW;
  @BuiltValueEnumConst(wireName: r'BV')
  static const ProfileCreateCountryEnum BV = _$profileCreateCountryEnum_BV;
  @BuiltValueEnumConst(wireName: r'BR')
  static const ProfileCreateCountryEnum BR = _$profileCreateCountryEnum_BR;
  @BuiltValueEnumConst(wireName: r'IO')
  static const ProfileCreateCountryEnum IO = _$profileCreateCountryEnum_IO;
  @BuiltValueEnumConst(wireName: r'BN')
  static const ProfileCreateCountryEnum BN = _$profileCreateCountryEnum_BN;
  @BuiltValueEnumConst(wireName: r'BG')
  static const ProfileCreateCountryEnum BG = _$profileCreateCountryEnum_BG;
  @BuiltValueEnumConst(wireName: r'BF')
  static const ProfileCreateCountryEnum BF = _$profileCreateCountryEnum_BF;
  @BuiltValueEnumConst(wireName: r'BI')
  static const ProfileCreateCountryEnum BI = _$profileCreateCountryEnum_BI;
  @BuiltValueEnumConst(wireName: r'CV')
  static const ProfileCreateCountryEnum CV = _$profileCreateCountryEnum_CV;
  @BuiltValueEnumConst(wireName: r'KH')
  static const ProfileCreateCountryEnum KH = _$profileCreateCountryEnum_KH;
  @BuiltValueEnumConst(wireName: r'CM')
  static const ProfileCreateCountryEnum CM = _$profileCreateCountryEnum_CM;
  @BuiltValueEnumConst(wireName: r'CA')
  static const ProfileCreateCountryEnum CA = _$profileCreateCountryEnum_CA;
  @BuiltValueEnumConst(wireName: r'KY')
  static const ProfileCreateCountryEnum KY = _$profileCreateCountryEnum_KY;
  @BuiltValueEnumConst(wireName: r'CF')
  static const ProfileCreateCountryEnum CF = _$profileCreateCountryEnum_CF;
  @BuiltValueEnumConst(wireName: r'TD')
  static const ProfileCreateCountryEnum TD = _$profileCreateCountryEnum_TD;
  @BuiltValueEnumConst(wireName: r'CL')
  static const ProfileCreateCountryEnum CL = _$profileCreateCountryEnum_CL;
  @BuiltValueEnumConst(wireName: r'CN')
  static const ProfileCreateCountryEnum CN = _$profileCreateCountryEnum_CN;
  @BuiltValueEnumConst(wireName: r'CX')
  static const ProfileCreateCountryEnum CX = _$profileCreateCountryEnum_CX;
  @BuiltValueEnumConst(wireName: r'CC')
  static const ProfileCreateCountryEnum CC = _$profileCreateCountryEnum_CC;
  @BuiltValueEnumConst(wireName: r'CO')
  static const ProfileCreateCountryEnum CO = _$profileCreateCountryEnum_CO;
  @BuiltValueEnumConst(wireName: r'KM')
  static const ProfileCreateCountryEnum KM = _$profileCreateCountryEnum_KM;
  @BuiltValueEnumConst(wireName: r'CG')
  static const ProfileCreateCountryEnum CG = _$profileCreateCountryEnum_CG;
  @BuiltValueEnumConst(wireName: r'CD')
  static const ProfileCreateCountryEnum CD = _$profileCreateCountryEnum_CD;
  @BuiltValueEnumConst(wireName: r'CK')
  static const ProfileCreateCountryEnum CK = _$profileCreateCountryEnum_CK;
  @BuiltValueEnumConst(wireName: r'CR')
  static const ProfileCreateCountryEnum CR = _$profileCreateCountryEnum_CR;
  @BuiltValueEnumConst(wireName: r'CI')
  static const ProfileCreateCountryEnum CI = _$profileCreateCountryEnum_CI;
  @BuiltValueEnumConst(wireName: r'HR')
  static const ProfileCreateCountryEnum HR = _$profileCreateCountryEnum_HR;
  @BuiltValueEnumConst(wireName: r'CU')
  static const ProfileCreateCountryEnum CU = _$profileCreateCountryEnum_CU;
  @BuiltValueEnumConst(wireName: r'CW')
  static const ProfileCreateCountryEnum CW = _$profileCreateCountryEnum_CW;
  @BuiltValueEnumConst(wireName: r'CY')
  static const ProfileCreateCountryEnum CY = _$profileCreateCountryEnum_CY;
  @BuiltValueEnumConst(wireName: r'CZ')
  static const ProfileCreateCountryEnum CZ = _$profileCreateCountryEnum_CZ;
  @BuiltValueEnumConst(wireName: r'DK')
  static const ProfileCreateCountryEnum DK = _$profileCreateCountryEnum_DK;
  @BuiltValueEnumConst(wireName: r'DJ')
  static const ProfileCreateCountryEnum DJ = _$profileCreateCountryEnum_DJ;
  @BuiltValueEnumConst(wireName: r'DM')
  static const ProfileCreateCountryEnum DM = _$profileCreateCountryEnum_DM;
  @BuiltValueEnumConst(wireName: r'DO')
  static const ProfileCreateCountryEnum DO = _$profileCreateCountryEnum_DO;
  @BuiltValueEnumConst(wireName: r'EC')
  static const ProfileCreateCountryEnum EC = _$profileCreateCountryEnum_EC;
  @BuiltValueEnumConst(wireName: r'EG')
  static const ProfileCreateCountryEnum EG = _$profileCreateCountryEnum_EG;
  @BuiltValueEnumConst(wireName: r'SV')
  static const ProfileCreateCountryEnum SV = _$profileCreateCountryEnum_SV;
  @BuiltValueEnumConst(wireName: r'GQ')
  static const ProfileCreateCountryEnum GQ = _$profileCreateCountryEnum_GQ;
  @BuiltValueEnumConst(wireName: r'ER')
  static const ProfileCreateCountryEnum ER = _$profileCreateCountryEnum_ER;
  @BuiltValueEnumConst(wireName: r'EE')
  static const ProfileCreateCountryEnum EE = _$profileCreateCountryEnum_EE;
  @BuiltValueEnumConst(wireName: r'SZ')
  static const ProfileCreateCountryEnum SZ = _$profileCreateCountryEnum_SZ;
  @BuiltValueEnumConst(wireName: r'ET')
  static const ProfileCreateCountryEnum ET = _$profileCreateCountryEnum_ET;
  @BuiltValueEnumConst(wireName: r'FK')
  static const ProfileCreateCountryEnum FK = _$profileCreateCountryEnum_FK;
  @BuiltValueEnumConst(wireName: r'FO')
  static const ProfileCreateCountryEnum FO = _$profileCreateCountryEnum_FO;
  @BuiltValueEnumConst(wireName: r'FJ')
  static const ProfileCreateCountryEnum FJ = _$profileCreateCountryEnum_FJ;
  @BuiltValueEnumConst(wireName: r'FI')
  static const ProfileCreateCountryEnum FI = _$profileCreateCountryEnum_FI;
  @BuiltValueEnumConst(wireName: r'FR')
  static const ProfileCreateCountryEnum FR = _$profileCreateCountryEnum_FR;
  @BuiltValueEnumConst(wireName: r'GF')
  static const ProfileCreateCountryEnum GF = _$profileCreateCountryEnum_GF;
  @BuiltValueEnumConst(wireName: r'PF')
  static const ProfileCreateCountryEnum PF = _$profileCreateCountryEnum_PF;
  @BuiltValueEnumConst(wireName: r'TF')
  static const ProfileCreateCountryEnum TF = _$profileCreateCountryEnum_TF;
  @BuiltValueEnumConst(wireName: r'GA')
  static const ProfileCreateCountryEnum GA = _$profileCreateCountryEnum_GA;
  @BuiltValueEnumConst(wireName: r'GM')
  static const ProfileCreateCountryEnum GM = _$profileCreateCountryEnum_GM;
  @BuiltValueEnumConst(wireName: r'GE')
  static const ProfileCreateCountryEnum GE = _$profileCreateCountryEnum_GE;
  @BuiltValueEnumConst(wireName: r'DE')
  static const ProfileCreateCountryEnum DE = _$profileCreateCountryEnum_DE;
  @BuiltValueEnumConst(wireName: r'GH')
  static const ProfileCreateCountryEnum GH = _$profileCreateCountryEnum_GH;
  @BuiltValueEnumConst(wireName: r'GI')
  static const ProfileCreateCountryEnum GI = _$profileCreateCountryEnum_GI;
  @BuiltValueEnumConst(wireName: r'GR')
  static const ProfileCreateCountryEnum GR = _$profileCreateCountryEnum_GR;
  @BuiltValueEnumConst(wireName: r'GL')
  static const ProfileCreateCountryEnum GL = _$profileCreateCountryEnum_GL;
  @BuiltValueEnumConst(wireName: r'GD')
  static const ProfileCreateCountryEnum GD = _$profileCreateCountryEnum_GD;
  @BuiltValueEnumConst(wireName: r'GP')
  static const ProfileCreateCountryEnum GP = _$profileCreateCountryEnum_GP;
  @BuiltValueEnumConst(wireName: r'GU')
  static const ProfileCreateCountryEnum GU = _$profileCreateCountryEnum_GU;
  @BuiltValueEnumConst(wireName: r'GT')
  static const ProfileCreateCountryEnum GT = _$profileCreateCountryEnum_GT;
  @BuiltValueEnumConst(wireName: r'GG')
  static const ProfileCreateCountryEnum GG = _$profileCreateCountryEnum_GG;
  @BuiltValueEnumConst(wireName: r'GN')
  static const ProfileCreateCountryEnum GN = _$profileCreateCountryEnum_GN;
  @BuiltValueEnumConst(wireName: r'GW')
  static const ProfileCreateCountryEnum GW = _$profileCreateCountryEnum_GW;
  @BuiltValueEnumConst(wireName: r'GY')
  static const ProfileCreateCountryEnum GY = _$profileCreateCountryEnum_GY;
  @BuiltValueEnumConst(wireName: r'HT')
  static const ProfileCreateCountryEnum HT = _$profileCreateCountryEnum_HT;
  @BuiltValueEnumConst(wireName: r'HM')
  static const ProfileCreateCountryEnum HM = _$profileCreateCountryEnum_HM;
  @BuiltValueEnumConst(wireName: r'VA')
  static const ProfileCreateCountryEnum VA = _$profileCreateCountryEnum_VA;
  @BuiltValueEnumConst(wireName: r'HN')
  static const ProfileCreateCountryEnum HN = _$profileCreateCountryEnum_HN;
  @BuiltValueEnumConst(wireName: r'HK')
  static const ProfileCreateCountryEnum HK = _$profileCreateCountryEnum_HK;
  @BuiltValueEnumConst(wireName: r'HU')
  static const ProfileCreateCountryEnum HU = _$profileCreateCountryEnum_HU;
  @BuiltValueEnumConst(wireName: r'IS')
  static const ProfileCreateCountryEnum IS = _$profileCreateCountryEnum_IS;
  @BuiltValueEnumConst(wireName: r'IN')
  static const ProfileCreateCountryEnum IN = _$profileCreateCountryEnum_IN;
  @BuiltValueEnumConst(wireName: r'ID')
  static const ProfileCreateCountryEnum ID = _$profileCreateCountryEnum_ID;
  @BuiltValueEnumConst(wireName: r'IR')
  static const ProfileCreateCountryEnum IR = _$profileCreateCountryEnum_IR;
  @BuiltValueEnumConst(wireName: r'IQ')
  static const ProfileCreateCountryEnum IQ = _$profileCreateCountryEnum_IQ;
  @BuiltValueEnumConst(wireName: r'IE')
  static const ProfileCreateCountryEnum IE = _$profileCreateCountryEnum_IE;
  @BuiltValueEnumConst(wireName: r'IM')
  static const ProfileCreateCountryEnum IM = _$profileCreateCountryEnum_IM;
  @BuiltValueEnumConst(wireName: r'IL')
  static const ProfileCreateCountryEnum IL = _$profileCreateCountryEnum_IL;
  @BuiltValueEnumConst(wireName: r'IT')
  static const ProfileCreateCountryEnum IT = _$profileCreateCountryEnum_IT;
  @BuiltValueEnumConst(wireName: r'JM')
  static const ProfileCreateCountryEnum JM = _$profileCreateCountryEnum_JM;
  @BuiltValueEnumConst(wireName: r'JP')
  static const ProfileCreateCountryEnum JP = _$profileCreateCountryEnum_JP;
  @BuiltValueEnumConst(wireName: r'JE')
  static const ProfileCreateCountryEnum JE = _$profileCreateCountryEnum_JE;
  @BuiltValueEnumConst(wireName: r'JO')
  static const ProfileCreateCountryEnum JO = _$profileCreateCountryEnum_JO;
  @BuiltValueEnumConst(wireName: r'KZ')
  static const ProfileCreateCountryEnum KZ = _$profileCreateCountryEnum_KZ;
  @BuiltValueEnumConst(wireName: r'KE')
  static const ProfileCreateCountryEnum KE = _$profileCreateCountryEnum_KE;
  @BuiltValueEnumConst(wireName: r'KI')
  static const ProfileCreateCountryEnum KI = _$profileCreateCountryEnum_KI;
  @BuiltValueEnumConst(wireName: r'KW')
  static const ProfileCreateCountryEnum KW = _$profileCreateCountryEnum_KW;
  @BuiltValueEnumConst(wireName: r'KG')
  static const ProfileCreateCountryEnum KG = _$profileCreateCountryEnum_KG;
  @BuiltValueEnumConst(wireName: r'LA')
  static const ProfileCreateCountryEnum LA = _$profileCreateCountryEnum_LA;
  @BuiltValueEnumConst(wireName: r'LV')
  static const ProfileCreateCountryEnum LV = _$profileCreateCountryEnum_LV;
  @BuiltValueEnumConst(wireName: r'LB')
  static const ProfileCreateCountryEnum LB = _$profileCreateCountryEnum_LB;
  @BuiltValueEnumConst(wireName: r'LS')
  static const ProfileCreateCountryEnum LS = _$profileCreateCountryEnum_LS;
  @BuiltValueEnumConst(wireName: r'LR')
  static const ProfileCreateCountryEnum LR = _$profileCreateCountryEnum_LR;
  @BuiltValueEnumConst(wireName: r'LY')
  static const ProfileCreateCountryEnum LY = _$profileCreateCountryEnum_LY;
  @BuiltValueEnumConst(wireName: r'LI')
  static const ProfileCreateCountryEnum LI = _$profileCreateCountryEnum_LI;
  @BuiltValueEnumConst(wireName: r'LT')
  static const ProfileCreateCountryEnum LT = _$profileCreateCountryEnum_LT;
  @BuiltValueEnumConst(wireName: r'LU')
  static const ProfileCreateCountryEnum LU = _$profileCreateCountryEnum_LU;
  @BuiltValueEnumConst(wireName: r'MO')
  static const ProfileCreateCountryEnum MO = _$profileCreateCountryEnum_MO;
  @BuiltValueEnumConst(wireName: r'MG')
  static const ProfileCreateCountryEnum MG = _$profileCreateCountryEnum_MG;
  @BuiltValueEnumConst(wireName: r'MW')
  static const ProfileCreateCountryEnum MW = _$profileCreateCountryEnum_MW;
  @BuiltValueEnumConst(wireName: r'MY')
  static const ProfileCreateCountryEnum MY = _$profileCreateCountryEnum_MY;
  @BuiltValueEnumConst(wireName: r'MV')
  static const ProfileCreateCountryEnum MV = _$profileCreateCountryEnum_MV;
  @BuiltValueEnumConst(wireName: r'ML')
  static const ProfileCreateCountryEnum ML = _$profileCreateCountryEnum_ML;
  @BuiltValueEnumConst(wireName: r'MT')
  static const ProfileCreateCountryEnum MT = _$profileCreateCountryEnum_MT;
  @BuiltValueEnumConst(wireName: r'MH')
  static const ProfileCreateCountryEnum MH = _$profileCreateCountryEnum_MH;
  @BuiltValueEnumConst(wireName: r'MQ')
  static const ProfileCreateCountryEnum MQ = _$profileCreateCountryEnum_MQ;
  @BuiltValueEnumConst(wireName: r'MR')
  static const ProfileCreateCountryEnum MR = _$profileCreateCountryEnum_MR;
  @BuiltValueEnumConst(wireName: r'MU')
  static const ProfileCreateCountryEnum MU = _$profileCreateCountryEnum_MU;
  @BuiltValueEnumConst(wireName: r'YT')
  static const ProfileCreateCountryEnum YT = _$profileCreateCountryEnum_YT;
  @BuiltValueEnumConst(wireName: r'MX')
  static const ProfileCreateCountryEnum MX = _$profileCreateCountryEnum_MX;
  @BuiltValueEnumConst(wireName: r'FM')
  static const ProfileCreateCountryEnum FM = _$profileCreateCountryEnum_FM;
  @BuiltValueEnumConst(wireName: r'MD')
  static const ProfileCreateCountryEnum MD = _$profileCreateCountryEnum_MD;
  @BuiltValueEnumConst(wireName: r'MC')
  static const ProfileCreateCountryEnum MC = _$profileCreateCountryEnum_MC;
  @BuiltValueEnumConst(wireName: r'MN')
  static const ProfileCreateCountryEnum MN = _$profileCreateCountryEnum_MN;
  @BuiltValueEnumConst(wireName: r'ME')
  static const ProfileCreateCountryEnum ME = _$profileCreateCountryEnum_ME;
  @BuiltValueEnumConst(wireName: r'MS')
  static const ProfileCreateCountryEnum MS = _$profileCreateCountryEnum_MS;
  @BuiltValueEnumConst(wireName: r'MA')
  static const ProfileCreateCountryEnum MA = _$profileCreateCountryEnum_MA;
  @BuiltValueEnumConst(wireName: r'MZ')
  static const ProfileCreateCountryEnum MZ = _$profileCreateCountryEnum_MZ;
  @BuiltValueEnumConst(wireName: r'MM')
  static const ProfileCreateCountryEnum MM = _$profileCreateCountryEnum_MM;
  @BuiltValueEnumConst(wireName: r'NA')
  static const ProfileCreateCountryEnum NA = _$profileCreateCountryEnum_NA;
  @BuiltValueEnumConst(wireName: r'NR')
  static const ProfileCreateCountryEnum NR = _$profileCreateCountryEnum_NR;
  @BuiltValueEnumConst(wireName: r'NP')
  static const ProfileCreateCountryEnum NP = _$profileCreateCountryEnum_NP;
  @BuiltValueEnumConst(wireName: r'NL')
  static const ProfileCreateCountryEnum NL = _$profileCreateCountryEnum_NL;
  @BuiltValueEnumConst(wireName: r'NC')
  static const ProfileCreateCountryEnum NC = _$profileCreateCountryEnum_NC;
  @BuiltValueEnumConst(wireName: r'NZ')
  static const ProfileCreateCountryEnum NZ = _$profileCreateCountryEnum_NZ;
  @BuiltValueEnumConst(wireName: r'NI')
  static const ProfileCreateCountryEnum NI = _$profileCreateCountryEnum_NI;
  @BuiltValueEnumConst(wireName: r'NE')
  static const ProfileCreateCountryEnum NE = _$profileCreateCountryEnum_NE;
  @BuiltValueEnumConst(wireName: r'NG')
  static const ProfileCreateCountryEnum NG = _$profileCreateCountryEnum_NG;
  @BuiltValueEnumConst(wireName: r'NU')
  static const ProfileCreateCountryEnum NU = _$profileCreateCountryEnum_NU;
  @BuiltValueEnumConst(wireName: r'NF')
  static const ProfileCreateCountryEnum NF = _$profileCreateCountryEnum_NF;
  @BuiltValueEnumConst(wireName: r'KP')
  static const ProfileCreateCountryEnum KP = _$profileCreateCountryEnum_KP;
  @BuiltValueEnumConst(wireName: r'MK')
  static const ProfileCreateCountryEnum MK = _$profileCreateCountryEnum_MK;
  @BuiltValueEnumConst(wireName: r'MP')
  static const ProfileCreateCountryEnum MP = _$profileCreateCountryEnum_MP;
  @BuiltValueEnumConst(wireName: r'NO')
  static const ProfileCreateCountryEnum NO = _$profileCreateCountryEnum_NO;
  @BuiltValueEnumConst(wireName: r'OM')
  static const ProfileCreateCountryEnum OM = _$profileCreateCountryEnum_OM;
  @BuiltValueEnumConst(wireName: r'PK')
  static const ProfileCreateCountryEnum PK = _$profileCreateCountryEnum_PK;
  @BuiltValueEnumConst(wireName: r'PW')
  static const ProfileCreateCountryEnum PW = _$profileCreateCountryEnum_PW;
  @BuiltValueEnumConst(wireName: r'PS')
  static const ProfileCreateCountryEnum PS = _$profileCreateCountryEnum_PS;
  @BuiltValueEnumConst(wireName: r'PA')
  static const ProfileCreateCountryEnum PA = _$profileCreateCountryEnum_PA;
  @BuiltValueEnumConst(wireName: r'PG')
  static const ProfileCreateCountryEnum PG = _$profileCreateCountryEnum_PG;
  @BuiltValueEnumConst(wireName: r'PY')
  static const ProfileCreateCountryEnum PY = _$profileCreateCountryEnum_PY;
  @BuiltValueEnumConst(wireName: r'PE')
  static const ProfileCreateCountryEnum PE = _$profileCreateCountryEnum_PE;
  @BuiltValueEnumConst(wireName: r'PH')
  static const ProfileCreateCountryEnum PH = _$profileCreateCountryEnum_PH;
  @BuiltValueEnumConst(wireName: r'PN')
  static const ProfileCreateCountryEnum PN = _$profileCreateCountryEnum_PN;
  @BuiltValueEnumConst(wireName: r'PL')
  static const ProfileCreateCountryEnum PL = _$profileCreateCountryEnum_PL;
  @BuiltValueEnumConst(wireName: r'PT')
  static const ProfileCreateCountryEnum PT = _$profileCreateCountryEnum_PT;
  @BuiltValueEnumConst(wireName: r'PR')
  static const ProfileCreateCountryEnum PR = _$profileCreateCountryEnum_PR;
  @BuiltValueEnumConst(wireName: r'QA')
  static const ProfileCreateCountryEnum QA = _$profileCreateCountryEnum_QA;
  @BuiltValueEnumConst(wireName: r'RE')
  static const ProfileCreateCountryEnum RE = _$profileCreateCountryEnum_RE;
  @BuiltValueEnumConst(wireName: r'RO')
  static const ProfileCreateCountryEnum RO = _$profileCreateCountryEnum_RO;
  @BuiltValueEnumConst(wireName: r'RU')
  static const ProfileCreateCountryEnum RU = _$profileCreateCountryEnum_RU;
  @BuiltValueEnumConst(wireName: r'RW')
  static const ProfileCreateCountryEnum RW = _$profileCreateCountryEnum_RW;
  @BuiltValueEnumConst(wireName: r'BL')
  static const ProfileCreateCountryEnum BL = _$profileCreateCountryEnum_BL;
  @BuiltValueEnumConst(wireName: r'SH')
  static const ProfileCreateCountryEnum SH = _$profileCreateCountryEnum_SH;
  @BuiltValueEnumConst(wireName: r'KN')
  static const ProfileCreateCountryEnum KN = _$profileCreateCountryEnum_KN;
  @BuiltValueEnumConst(wireName: r'LC')
  static const ProfileCreateCountryEnum LC = _$profileCreateCountryEnum_LC;
  @BuiltValueEnumConst(wireName: r'MF')
  static const ProfileCreateCountryEnum MF = _$profileCreateCountryEnum_MF;
  @BuiltValueEnumConst(wireName: r'PM')
  static const ProfileCreateCountryEnum PM = _$profileCreateCountryEnum_PM;
  @BuiltValueEnumConst(wireName: r'VC')
  static const ProfileCreateCountryEnum VC = _$profileCreateCountryEnum_VC;
  @BuiltValueEnumConst(wireName: r'WS')
  static const ProfileCreateCountryEnum WS = _$profileCreateCountryEnum_WS;
  @BuiltValueEnumConst(wireName: r'SM')
  static const ProfileCreateCountryEnum SM = _$profileCreateCountryEnum_SM;
  @BuiltValueEnumConst(wireName: r'ST')
  static const ProfileCreateCountryEnum ST = _$profileCreateCountryEnum_ST;
  @BuiltValueEnumConst(wireName: r'SA')
  static const ProfileCreateCountryEnum SA = _$profileCreateCountryEnum_SA;
  @BuiltValueEnumConst(wireName: r'SN')
  static const ProfileCreateCountryEnum SN = _$profileCreateCountryEnum_SN;
  @BuiltValueEnumConst(wireName: r'RS')
  static const ProfileCreateCountryEnum RS = _$profileCreateCountryEnum_RS;
  @BuiltValueEnumConst(wireName: r'SC')
  static const ProfileCreateCountryEnum SC = _$profileCreateCountryEnum_SC;
  @BuiltValueEnumConst(wireName: r'SL')
  static const ProfileCreateCountryEnum SL = _$profileCreateCountryEnum_SL;
  @BuiltValueEnumConst(wireName: r'SG')
  static const ProfileCreateCountryEnum SG = _$profileCreateCountryEnum_SG;
  @BuiltValueEnumConst(wireName: r'SX')
  static const ProfileCreateCountryEnum SX = _$profileCreateCountryEnum_SX;
  @BuiltValueEnumConst(wireName: r'SK')
  static const ProfileCreateCountryEnum SK = _$profileCreateCountryEnum_SK;
  @BuiltValueEnumConst(wireName: r'SI')
  static const ProfileCreateCountryEnum SI = _$profileCreateCountryEnum_SI;
  @BuiltValueEnumConst(wireName: r'SB')
  static const ProfileCreateCountryEnum SB = _$profileCreateCountryEnum_SB;
  @BuiltValueEnumConst(wireName: r'SO')
  static const ProfileCreateCountryEnum SO = _$profileCreateCountryEnum_SO;
  @BuiltValueEnumConst(wireName: r'ZA')
  static const ProfileCreateCountryEnum ZA = _$profileCreateCountryEnum_ZA;
  @BuiltValueEnumConst(wireName: r'GS')
  static const ProfileCreateCountryEnum GS = _$profileCreateCountryEnum_GS;
  @BuiltValueEnumConst(wireName: r'KR')
  static const ProfileCreateCountryEnum KR = _$profileCreateCountryEnum_KR;
  @BuiltValueEnumConst(wireName: r'SS')
  static const ProfileCreateCountryEnum SS = _$profileCreateCountryEnum_SS;
  @BuiltValueEnumConst(wireName: r'ES')
  static const ProfileCreateCountryEnum ES = _$profileCreateCountryEnum_ES;
  @BuiltValueEnumConst(wireName: r'LK')
  static const ProfileCreateCountryEnum LK = _$profileCreateCountryEnum_LK;
  @BuiltValueEnumConst(wireName: r'SD')
  static const ProfileCreateCountryEnum SD = _$profileCreateCountryEnum_SD;
  @BuiltValueEnumConst(wireName: r'SR')
  static const ProfileCreateCountryEnum SR = _$profileCreateCountryEnum_SR;
  @BuiltValueEnumConst(wireName: r'SJ')
  static const ProfileCreateCountryEnum SJ = _$profileCreateCountryEnum_SJ;
  @BuiltValueEnumConst(wireName: r'SE')
  static const ProfileCreateCountryEnum SE = _$profileCreateCountryEnum_SE;
  @BuiltValueEnumConst(wireName: r'CH')
  static const ProfileCreateCountryEnum CH = _$profileCreateCountryEnum_CH;
  @BuiltValueEnumConst(wireName: r'SY')
  static const ProfileCreateCountryEnum SY = _$profileCreateCountryEnum_SY;
  @BuiltValueEnumConst(wireName: r'TW')
  static const ProfileCreateCountryEnum TW = _$profileCreateCountryEnum_TW;
  @BuiltValueEnumConst(wireName: r'TJ')
  static const ProfileCreateCountryEnum TJ = _$profileCreateCountryEnum_TJ;
  @BuiltValueEnumConst(wireName: r'TZ')
  static const ProfileCreateCountryEnum TZ = _$profileCreateCountryEnum_TZ;
  @BuiltValueEnumConst(wireName: r'TH')
  static const ProfileCreateCountryEnum TH = _$profileCreateCountryEnum_TH;
  @BuiltValueEnumConst(wireName: r'TL')
  static const ProfileCreateCountryEnum TL = _$profileCreateCountryEnum_TL;
  @BuiltValueEnumConst(wireName: r'TG')
  static const ProfileCreateCountryEnum TG = _$profileCreateCountryEnum_TG;
  @BuiltValueEnumConst(wireName: r'TK')
  static const ProfileCreateCountryEnum TK = _$profileCreateCountryEnum_TK;
  @BuiltValueEnumConst(wireName: r'TO')
  static const ProfileCreateCountryEnum TO = _$profileCreateCountryEnum_TO;
  @BuiltValueEnumConst(wireName: r'TT')
  static const ProfileCreateCountryEnum TT = _$profileCreateCountryEnum_TT;
  @BuiltValueEnumConst(wireName: r'TN')
  static const ProfileCreateCountryEnum TN = _$profileCreateCountryEnum_TN;
  @BuiltValueEnumConst(wireName: r'TR')
  static const ProfileCreateCountryEnum TR = _$profileCreateCountryEnum_TR;
  @BuiltValueEnumConst(wireName: r'TM')
  static const ProfileCreateCountryEnum TM = _$profileCreateCountryEnum_TM;
  @BuiltValueEnumConst(wireName: r'TC')
  static const ProfileCreateCountryEnum TC = _$profileCreateCountryEnum_TC;
  @BuiltValueEnumConst(wireName: r'TV')
  static const ProfileCreateCountryEnum TV = _$profileCreateCountryEnum_TV;
  @BuiltValueEnumConst(wireName: r'UG')
  static const ProfileCreateCountryEnum UG = _$profileCreateCountryEnum_UG;
  @BuiltValueEnumConst(wireName: r'UA')
  static const ProfileCreateCountryEnum UA = _$profileCreateCountryEnum_UA;
  @BuiltValueEnumConst(wireName: r'AE')
  static const ProfileCreateCountryEnum AE = _$profileCreateCountryEnum_AE;
  @BuiltValueEnumConst(wireName: r'GB')
  static const ProfileCreateCountryEnum GB = _$profileCreateCountryEnum_GB;
  @BuiltValueEnumConst(wireName: r'UM')
  static const ProfileCreateCountryEnum UM = _$profileCreateCountryEnum_UM;
  @BuiltValueEnumConst(wireName: r'US')
  static const ProfileCreateCountryEnum US = _$profileCreateCountryEnum_US;
  @BuiltValueEnumConst(wireName: r'UY')
  static const ProfileCreateCountryEnum UY = _$profileCreateCountryEnum_UY;
  @BuiltValueEnumConst(wireName: r'UZ')
  static const ProfileCreateCountryEnum UZ = _$profileCreateCountryEnum_UZ;
  @BuiltValueEnumConst(wireName: r'VU')
  static const ProfileCreateCountryEnum VU = _$profileCreateCountryEnum_VU;
  @BuiltValueEnumConst(wireName: r'VE')
  static const ProfileCreateCountryEnum VE = _$profileCreateCountryEnum_VE;
  @BuiltValueEnumConst(wireName: r'VN')
  static const ProfileCreateCountryEnum VN = _$profileCreateCountryEnum_VN;
  @BuiltValueEnumConst(wireName: r'VG')
  static const ProfileCreateCountryEnum VG = _$profileCreateCountryEnum_VG;
  @BuiltValueEnumConst(wireName: r'VI')
  static const ProfileCreateCountryEnum VI = _$profileCreateCountryEnum_VI;
  @BuiltValueEnumConst(wireName: r'WF')
  static const ProfileCreateCountryEnum WF = _$profileCreateCountryEnum_WF;
  @BuiltValueEnumConst(wireName: r'EH')
  static const ProfileCreateCountryEnum EH = _$profileCreateCountryEnum_EH;
  @BuiltValueEnumConst(wireName: r'YE')
  static const ProfileCreateCountryEnum YE = _$profileCreateCountryEnum_YE;
  @BuiltValueEnumConst(wireName: r'ZM')
  static const ProfileCreateCountryEnum ZM = _$profileCreateCountryEnum_ZM;
  @BuiltValueEnumConst(wireName: r'ZW')
  static const ProfileCreateCountryEnum ZW = _$profileCreateCountryEnum_ZW;

  static Serializer<ProfileCreateCountryEnum> get serializer => _$profileCreateCountryEnumSerializer;

  const ProfileCreateCountryEnum._(String name): super(name);

  static BuiltSet<ProfileCreateCountryEnum> get values => _$profileCreateCountryEnumValues;
  static ProfileCreateCountryEnum valueOf(String name) => _$profileCreateCountryEnumValueOf(name);
}

