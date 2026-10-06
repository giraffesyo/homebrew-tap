import io
import tarfile
import unittest

from update import release_version, source_checksum, updated_formula


class ReleaseUpdateTests(unittest.TestCase):
    def test_tag_validation(self):
        self.assertEqual(release_version({"tag_name": "timeclock-v1.2.3"}, "timeclock-v"), "1.2.3")
        for release in ({"tag_name": "v1.2.3", "draft": True},
                        {"tag_name": "v1.2.3", "prerelease": True},
                        {"tag_name": 'v1.2.3"; system "oops"'},
                        {"tag_name": "v1.2.3-rc1"}):
            with self.subTest(release=release), self.assertRaises(ValueError):
                release_version(release, "v")

    def test_release_must_contain_the_cli(self):
        data = io.BytesIO()
        with tarfile.open(fileobj=data, mode="w:gz") as archive:
            for name in ("root/go.mod", "root/cmd/timeclock/main.go"):
                entry = tarfile.TarInfo(name)
                entry.size = 4
                archive.addfile(entry, io.BytesIO(b"test"))
        self.assertEqual(len(source_checksum(data.getvalue(), "cmd/timeclock/main.go")), 64)
        with self.assertRaises(ValueError):
            source_checksum(data.getvalue(), "cmd/understudy/main.go")

    def test_only_source_metadata_changes(self):
        original = '  url "old"\n  version "1.0.0"\n  sha256 "old"\n  head "keep"\n'
        self.assertEqual(updated_formula(original, "new", "1.1.0", "checksum"),
                         '  url "new"\n  version "1.1.0"\n  sha256 "checksum"\n  head "keep"\n')
        with self.assertRaises(ValueError):
            updated_formula('  url "old"\n', "new", "1.1.0", "checksum")


if __name__ == "__main__":
    unittest.main()
