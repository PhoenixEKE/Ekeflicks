from django.test import SimpleTestCase

from apps.catalog.xml_metadata import (
    MAX_XML_SIZE_BYTES,
    SCHEMA_ROOT,
    SCHEMA_VERSION,
    XmlMetadataError,
    parse_xml_metadata_bytes,
    validate_xml_upload_metadata,
)


class XmlMetadataParserTests(SimpleTestCase):
    databases = []

    def assert_xml_error(
        self,
        xml: bytes,
        expected_code: str,
    ):
        with self.assertRaises(
            XmlMetadataError
        ) as ctx:
            parse_xml_metadata_bytes(
                xml
            )

        self.assertEqual(
            ctx.exception.code,
            expected_code,
        )

    def test_schema_constants(self):
        self.assertEqual(
            SCHEMA_ROOT,
            "ekeflicks-metadata",
        )

        self.assertEqual(
            SCHEMA_VERSION,
            "1.0",
        )

        self.assertEqual(
            MAX_XML_SIZE_BYTES,
            2 * 1024 * 1024,
        )

    def test_valid_film_xml_normalizes_to_movie(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">

            <title>Film Test</title>
            <original-title>Original Test</original-title>

            <synopsis>Synopsis Test</synopsis>
            <long-synopsis>Long synopsis Test</long-synopsis>

            <genres>
              <genre>Drame</genre>
              <genre>Action</genre>
            </genres>

            <production-year>2026</production-year>

            <directors>
              <director>Director One</director>
            </directors>

            <cast>
              <person>Actor One</person>
              <person>Actor Two</person>
            </cast>

            <screenwriters>
              <screenwriter>Writer One</screenwriter>
            </screenwriters>

            <producers>
              <producer>Producer One</producer>
            </producers>

            <age-rating>12+</age-rating>
            <duration-minutes>90</duration-minutes>

            <original-language>fr</original-language>

            <audio-languages>
              <language>fr</language>
              <language>en</language>
            </audio-languages>

            <subtitle-languages>
              <language>en</language>
            </subtitle-languages>

            <country-of-origin>CI</country-of-origin>

          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        self.assertTrue(
            result["valid"]
        )

        self.assertEqual(
            result["schema"],
            "ekeflicks-metadata",
        )

        self.assertEqual(
            result["schema_version"],
            "1.0",
        )

        content = result[
            "recognized"
        ]["content"]

        self.assertEqual(
            content["type"],
            "movie",
        )

        self.assertEqual(
            content["title"],
            "Film Test",
        )

        self.assertEqual(
            content["original_title"],
            "Original Test",
        )

        self.assertEqual(
            content["synopsis"],
            "Synopsis Test",
        )

        self.assertEqual(
            content["description"],
            "Long synopsis Test",
        )

        self.assertEqual(
            content["genres"],
            [
                "Drame",
                "Action",
            ],
        )

        self.assertEqual(
            content["release_year"],
            2026,
        )

        self.assertEqual(
            content["directors"],
            ["Director One"],
        )

        self.assertEqual(
            content["cast"],
            [
                "Actor One",
                "Actor Two",
            ],
        )

        self.assertEqual(
            content["screenwriters"],
            ["Writer One"],
        )

        self.assertEqual(
            content["producers"],
            ["Producer One"],
        )

        self.assertEqual(
            content["age_rating"],
            "12+",
        )

        self.assertEqual(
            content["duration"],
            90,
        )

        self.assertEqual(
            content["language"],
            "Français",
        )

        self.assertEqual(
            content["audio_languages"],
            [
                "Français",
                "Anglais",
            ],
        )

        self.assertEqual(
            content["subtitle_languages"],
            ["Anglais"],
        )

        self.assertEqual(
            content["country"],
            "Côte d'Ivoire",
        )

        self.assertEqual(
            result["recognized"]["seasons"],
            [],
        )

    def test_movie_alias_is_rejected_by_public_schema(self):
        xml = b'''
        <ekeflicks-metadata version="1.0">
          <content type="movie">
            <title>Movie Alias</title>
          </content>
        </ekeflicks-metadata>
        '''

        with self.assertRaises(
            XmlMetadataError
        ) as context:
            parse_xml_metadata_bytes(
                xml
            )

        self.assertEqual(
            context.exception.code,
            "xml_invalid_content_type",
        )

    def test_valid_series_with_seasons_and_episodes(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">

          <content type="series">

            <title>Series Test</title>

            <seasons>

              <season number="1">

                <title>Saison 1</title>
                <description>Description saison 1</description>

                <episodes>

                  <episode number="1">
                    <title>Episode 1</title>
                    <description>Description episode 1</description>
                    <duration-minutes>26</duration-minutes>
                  </episode>

                  <episode number="2">
                    <title>Episode 2</title>
                    <duration-minutes>24</duration-minutes>
                  </episode>

                </episodes>

              </season>

              <season number="2">

                <title>Saison 2</title>

                <episodes>

                  <episode number="1">
                    <title>Episode 1 S2</title>
                    <duration-minutes>28</duration-minutes>
                  </episode>

                </episodes>

              </season>

            </seasons>

          </content>

        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        content = result[
            "recognized"
        ]["content"]

        seasons = result[
            "recognized"
        ]["seasons"]

        self.assertEqual(
            content["type"],
            "series",
        )

        self.assertEqual(
            len(seasons),
            2,
        )

        self.assertEqual(
            seasons[0]["season_number"],
            1,
        )

        self.assertEqual(
            seasons[1]["season_number"],
            2,
        )

        self.assertEqual(
            len(seasons[0]["episodes"]),
            2,
        )

        self.assertEqual(
            len(seasons[1]["episodes"]),
            1,
        )

        self.assertEqual(
            seasons[0]["episodes"][0]["episode_number"],
            1,
        )

        self.assertEqual(
            seasons[0]["episodes"][1]["episode_number"],
            2,
        )

        self.assertEqual(
            seasons[1]["episodes"][0]["episode_number"],
            1,
        )

        self.assertEqual(
            seasons[0]["episodes"][0]["duration"],
            26,
        )

    def test_xml_declaration_is_optional(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">
            <title>Film</title>
          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        )

        self.assertTrue(
            result.valid
        )

    def test_utf8_xml_declaration_is_supported(self):
        xml = """<?xml version="1.0" encoding="UTF-8"?>
        <ekeflicks-metadata version="1.0">
          <content type="film">
            <title>Été à Abidjan</title>
          </content>
        </ekeflicks-metadata>
        """.encode("utf-8")

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        self.assertEqual(
            result["recognized"]["content"]["title"],
            "Été à Abidjan",
        )

    def test_empty_scalar_is_treated_as_absent(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">
            <title>   </title>
            <original-title></original-title>
          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        content = result[
            "recognized"
        ]["content"]

        self.assertNotIn(
            "title",
            content,
        )

        self.assertNotIn(
            "original_title",
            content,
        )

    def test_empty_list_items_are_ignored(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">

            <genres>
              <genre></genre>
              <genre>   </genre>
              <genre>Drame</genre>
            </genres>

          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        self.assertEqual(
            result["recognized"]["content"]["genres"],
            ["Drame"],
        )

    def test_multiple_directors_generate_warning(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">

            <directors>
              <director>A</director>
              <director>B</director>
            </directors>

          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        codes = [
            warning["code"]
            for warning in result["warnings"]
        ]

        self.assertIn(
            "multiple_directors_truncated",
            codes,
        )

        self.assertEqual(
            result["recognized"]["content"]["directors"],
            ["A", "B"],
        )

    def test_multiple_screenwriters_generate_warning(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">

            <screenwriters>
              <screenwriter>A</screenwriter>
              <screenwriter>B</screenwriter>
            </screenwriters>

          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        codes = [
            warning["code"]
            for warning in result["warnings"]
        ]

        self.assertIn(
            "multiple_screenwriters_truncated",
            codes,
        )

        self.assertEqual(
            result["recognized"]["content"]["screenwriters"],
            ["A", "B"],
        )

    def test_unknown_root_attribute_generates_warning(self):
        xml = b"""
        <ekeflicks-metadata
          version="1.0"
          future="x"
        >
          <content type="film"/>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        warnings = result[
            "warnings"
        ]

        self.assertTrue(
            any(
                item["code"] == "unknown_attribute"
                and item.get("attribute") == "future"
                for item in warnings
            )
        )

    def test_unknown_content_attribute_generates_warning(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content
            type="film"
            future="x"
          />
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        warnings = result[
            "warnings"
        ]

        self.assertTrue(
            any(
                item["code"] == "unknown_attribute"
                and item.get("attribute") == "future"
                for item in warnings
            )
        )

    def test_unknown_content_field_generates_warning_and_ignored_path(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">

            <title>Film</title>

            <future-field>
              value
            </future-field>

          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        codes = [
            warning["code"]
            for warning in result["warnings"]
        ]

        self.assertIn(
            "unknown_field",
            codes,
        )

        self.assertIn(
            "/ekeflicks-metadata/content/future-field",
            result["ignored_fields"],
        )

    def test_unknown_child_inside_genres_must_generate_warning(self):
        """
        Contract A5.12-C:
        unknown elements are ignored + warning,
        including nested list containers.
        """

        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">

            <genres>
              <genre>Drame</genre>
              <future-genre>Test</future-genre>
            </genres>

          </content>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        codes = [
            warning["code"]
            for warning in result["warnings"]
        ]

        self.assertIn(
            "unknown_field",
            codes,
        )

    def test_malformed_xml_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">
              <content type="film">
            """,
            "xml_malformed",
        )

    def test_wrong_root_is_rejected(self):
        self.assert_xml_error(
            b"""
            <metadata version="1.0">
              <content type="film"/>
            </metadata>
            """,
            "xml_unsupported_root",
        )

    def test_missing_version_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata>
              <content type="film"/>
            </ekeflicks-metadata>
            """,
            "xml_unsupported_version",
        )

    def test_wrong_version_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="2.0">
              <content type="film"/>
            </ekeflicks-metadata>
            """,
            "xml_unsupported_version",
        )

    def test_missing_content_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0"/>
            """,
            "xml_missing_content",
        )

    def test_multiple_content_nodes_are_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">
              <content type="film"/>
              <content type="film"/>
            </ekeflicks-metadata>
            """,
            "xml_duplicate_field",
        )

    def test_missing_content_type_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">
              <content/>
            </ekeflicks-metadata>
            """,
            "xml_invalid_content_type",
        )

    def test_invalid_content_type_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">
              <content type="documentary"/>
            </ekeflicks-metadata>
            """,
            "xml_invalid_content_type",
        )

    def test_content_type_is_case_normalized(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="FILM"/>
        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        self.assertEqual(
            result["recognized"]["content"]["type"],
            "movie",
        )

    def test_duplicate_scalar_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="film">
                <title>A</title>
                <title>B</title>
              </content>

            </ekeflicks-metadata>
            """,
            "xml_duplicate_field",
        )

    def test_duplicate_list_container_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="film">

                <genres>
                  <genre>Drame</genre>
                </genres>

                <genres>
                  <genre>Action</genre>
                </genres>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_duplicate_field",
        )

    def test_duplicate_seasons_container_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">
                <seasons/>
                <seasons/>
              </content>

            </ekeflicks-metadata>
            """,
            "xml_duplicate_field",
        )

    def test_duplicate_season_number_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>
                  <season number="1"/>
                  <season number="1"/>
                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_duplicate_season_number",
        )

    def test_duplicate_episode_number_within_same_season_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>

                  <season number="1">

                    <episodes>
                      <episode number="1"/>
                      <episode number="1"/>
                    </episodes>

                  </season>

                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_duplicate_episode_number",
        )

    def test_same_episode_number_in_different_seasons_is_allowed(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">

          <content type="series">

            <seasons>

              <season number="1">
                <episodes>
                  <episode number="1"/>
                </episodes>
              </season>

              <season number="2">
                <episodes>
                  <episode number="1"/>
                </episodes>
              </season>

            </seasons>

          </content>

        </ekeflicks-metadata>
        """

        result = parse_xml_metadata_bytes(
            xml
        ).as_dict()

        self.assertEqual(
            len(
                result[
                    "recognized"
                ]["seasons"]
            ),
            2,
        )

    def test_missing_season_number_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>
                  <season/>
                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_zero_season_number_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>
                  <season number="0"/>
                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_negative_season_number_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>
                  <season number="-1"/>
                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_missing_episode_number_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>

                  <season number="1">
                    <episodes>
                      <episode/>
                    </episodes>
                  </season>

                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_zero_episode_number_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>

                  <season number="1">
                    <episodes>
                      <episode number="0"/>
                    </episodes>
                  </season>

                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_zero_production_year_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="film">
                <production-year>0</production-year>
              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_non_integer_production_year_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="film">
                <production-year>202X</production-year>
              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_zero_duration_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="film">
                <duration-minutes>0</duration-minutes>
              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_non_integer_episode_duration_is_rejected(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="series">

                <seasons>

                  <season number="1">

                    <episodes>

                      <episode number="1">
                        <duration-minutes>ABC</duration-minutes>
                      </episode>

                    </episodes>

                  </season>

                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_seasons_are_forbidden_for_movie(self):
        self.assert_xml_error(
            b"""
            <ekeflicks-metadata version="1.0">

              <content type="film">

                <seasons>
                  <season number="1"/>
                </seasons>

              </content>

            </ekeflicks-metadata>
            """,
            "xml_invalid_value",
        )

    def test_doctype_is_rejected(self):
        self.assert_xml_error(
            b"""<!DOCTYPE metadata>
            <ekeflicks-metadata version="1.0">
              <content type="film"/>
            </ekeflicks-metadata>
            """,
            "xml_doctype_forbidden",
        )

    def test_entity_declaration_is_rejected(self):
        self.assert_xml_error(
            b"""<!DOCTYPE metadata [
              <!ENTITY x "test">
            ]>
            <ekeflicks-metadata version="1.0">
              <content type="film">
                <title>&x;</title>
              </content>
            </ekeflicks-metadata>
            """,
            "xml_doctype_forbidden",
        )

    def test_doctype_after_first_64k_is_still_rejected(self):
        """
        Security regression:
        forbidden XML constructs must not become legal merely
        because they appear after the manual 64 KiB prefix scan.
        """

        padding = (
            b"<!--"
            + (b"x" * 70000)
            + b"-->"
        )

        xml = (
            padding
            + b"""
            <!DOCTYPE metadata>
            <ekeflicks-metadata version="1.0">
              <content type="film"/>
            </ekeflicks-metadata>
            """
        )

        self.assert_xml_error(
            xml,
            "xml_doctype_forbidden",
        )

    def test_entity_after_first_64k_never_escapes_xml_error_contract(self):
        """
        defusedxml exceptions must be normalized into
        XmlMetadataError rather than leaking parser exceptions.
        """

        padding = (
            b"<!--"
            + (b"x" * 70000)
            + b"-->"
        )

        xml = (
            padding
            + b"""
            <!DOCTYPE metadata [
              <!ENTITY x "danger">
            ]>
            <ekeflicks-metadata version="1.0">
              <content type="film">
                <title>&x;</title>
              </content>
            </ekeflicks-metadata>
            """
        )

        with self.assertRaises(
            XmlMetadataError
        ) as ctx:
            parse_xml_metadata_bytes(
                xml
            )

        self.assertIn(
            ctx.exception.code,
            {
                "xml_doctype_forbidden",
                "xml_entity_forbidden",
            },
        )

    def test_empty_bytes_are_rejected(self):
        self.assert_xml_error(
            b"",
            "xml_empty",
        )

    def test_parse_size_limit_is_enforced(self):
        data = (
            b"x"
            * (
                MAX_XML_SIZE_BYTES
                + 1
            )
        )

        self.assert_xml_error(
            data,
            "xml_too_large",
        )

    def test_xinclude_is_explicitly_rejected(self):
        xml = b"""
        <ekeflicks-metadata
            xmlns:xi="http://www.w3.org/2001/XInclude"
            version="1.0">
          <content type="film">
            <title>XInclude Test</title>
            <xi:include
                href="http://example.com/external.xml"
                parse="xml"
            />
          </content>
        </ekeflicks-metadata>
        """

        with self.assertRaises(
            XmlMetadataError
        ) as context:
            parse_xml_metadata_bytes(
                xml
            )

        self.assertEqual(
            context.exception.code,
            "xml_xinclude_forbidden",
        )

    def test_language_country_codes_normalize_for_form(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">
            <title>Normalization Test</title>
            <original-language>fr</original-language>
            <audio-languages>
              <language>fr</language>
              <language>en</language>
            </audio-languages>
            <subtitle-languages>
              <language>en</language>
            </subtitle-languages>
            <country-of-origin>CI</country-of-origin>
          </content>
        </ekeflicks-metadata>
        """

        result = (
            parse_xml_metadata_bytes(
                xml
            )
            .as_dict()
        )

        content = result[
            "recognized"
        ][
            "content"
        ]

        self.assertEqual(
            content["language"],
            "Français",
        )

        self.assertEqual(
            content["audio_languages"],
            [
                "Français",
                "Anglais",
            ],
        )

        self.assertEqual(
            content["subtitle_languages"],
            [
                "Anglais",
            ],
        )

        self.assertEqual(
            content["country"],
            "Côte d'Ivoire",
        )

        unsupported = [
            warning
            for warning in result["warnings"]
            if warning.get("code")
            == "unsupported_optional_value"
        ]

        self.assertEqual(
            unsupported,
            [],
        )

    def test_unknown_language_country_values_are_preserved(self):
        xml = b"""
        <ekeflicks-metadata version="1.0">
          <content type="film">
            <title>Unknown Values</title>
            <original-language>baoule</original-language>
            <audio-languages>
              <language>baoule</language>
            </audio-languages>
            <subtitle-languages>
              <language>dioula</language>
            </subtitle-languages>
            <country-of-origin>ZZ</country-of-origin>
          </content>
        </ekeflicks-metadata>
        """

        result = (
            parse_xml_metadata_bytes(
                xml
            )
            .as_dict()
        )

        content = result[
            "recognized"
        ][
            "content"
        ]

        self.assertEqual(
            content["language"],
            "baoule",
        )

        self.assertEqual(
            content["audio_languages"],
            [
                "baoule",
            ],
        )

        self.assertEqual(
            content["subtitle_languages"],
            [
                "dioula",
            ],
        )

        self.assertEqual(
            content["country"],
            "ZZ",
        )

        unsupported = [
            warning
            for warning in result["warnings"]
            if warning.get("code")
            == "unsupported_optional_value"
        ]

        self.assertEqual(
            [
                (
                    warning.get("field"),
                    warning.get("value"),
                )
                for warning in unsupported
            ],
            [
                (
                    "language",
                    "baoule",
                ),
                (
                    "audio_languages",
                    "baoule",
                ),
                (
                    "subtitle_languages",
                    "dioula",
                ),
                (
                    "country",
                    "ZZ",
                ),
            ],
        )

        self.assertTrue(
            all(
                warning.get("message")
                for warning in unsupported
            )
        )


class XmlMetadataUploadValidationTests(
    SimpleTestCase
):
    databases = []

    def assert_upload_error(
        self,
        *,
        expected_code,
        **kwargs,
    ):
        with self.assertRaises(
            XmlMetadataError
        ) as ctx:
            validate_xml_upload_metadata(
                **kwargs
            )

        self.assertEqual(
            ctx.exception.code,
            expected_code,
        )

    def test_application_xml_is_allowed(self):
        validate_xml_upload_metadata(
            filename="metadata.xml",
            content_type="application/xml",
            size=100,
        )

    def test_text_xml_is_allowed(self):
        validate_xml_upload_metadata(
            filename="metadata.xml",
            content_type="text/xml",
            size=100,
        )

    def test_text_xml_with_charset_is_allowed(self):
        validate_xml_upload_metadata(
            filename="metadata.xml",
            content_type="text/xml; charset=utf-8",
            size=100,
        )

    def test_octet_stream_with_xml_extension_is_allowed(self):
        validate_xml_upload_metadata(
            filename="metadata.xml",
            content_type="application/octet-stream",
            size=100,
        )

    def test_uppercase_xml_extension_is_allowed(self):
        validate_xml_upload_metadata(
            filename="metadata.XML",
            content_type="application/xml",
            size=100,
        )

    def test_missing_mime_uses_octet_stream_fallback(self):
        validate_xml_upload_metadata(
            filename="metadata.xml",
            content_type=None,
            size=100,
        )

    def test_invalid_extension_is_rejected(self):
        self.assert_upload_error(
            filename="metadata.txt",
            content_type="application/xml",
            size=100,
            expected_code="xml_invalid_extension",
        )

    def test_no_extension_is_rejected(self):
        self.assert_upload_error(
            filename="metadata",
            content_type="application/xml",
            size=100,
            expected_code="xml_invalid_extension",
        )

    def test_double_extension_is_rejected(self):
        self.assert_upload_error(
            filename="metadata.xml.txt",
            content_type="application/xml",
            size=100,
            expected_code="xml_invalid_extension",
        )

    def test_invalid_mime_is_rejected(self):
        self.assert_upload_error(
            filename="metadata.xml",
            content_type="text/plain",
            size=100,
            expected_code="xml_invalid_mime",
        )

    def test_empty_upload_is_rejected(self):
        self.assert_upload_error(
            filename="metadata.xml",
            content_type="application/xml",
            size=0,
            expected_code="xml_empty",
        )

    def test_negative_upload_size_is_rejected_as_empty(self):
        self.assert_upload_error(
            filename="metadata.xml",
            content_type="application/xml",
            size=-1,
            expected_code="xml_empty",
        )

    def test_exact_size_limit_is_allowed(self):
        validate_xml_upload_metadata(
            filename="metadata.xml",
            content_type="application/xml",
            size=MAX_XML_SIZE_BYTES,
        )

    def test_over_size_limit_is_rejected(self):
        self.assert_upload_error(
            filename="metadata.xml",
            content_type="application/xml",
            size=MAX_XML_SIZE_BYTES + 1,
            expected_code="xml_too_large",
        )
