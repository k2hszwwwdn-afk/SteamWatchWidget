import tempfile
import unittest
from pathlib import Path

from tools.scan_games import installed_games, library_paths, read_field


class ScanGamesTests(unittest.TestCase):
    def test_reads_escaped_vdf_fields(self):
        self.assertEqual(read_field('"name"\t"Game \\"One\\"" ', "name"), 'Game "One"')

    def test_discovers_additional_libraries(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            root = Path(temporary_directory) / "Steam"
            extra = Path(temporary_directory) / "Library"
            (root / "steamapps").mkdir(parents=True)
            (extra / "steamapps").mkdir(parents=True)
            (root / "steamapps/libraryfolders.vdf").write_text(
                f'"libraryfolders"\n{{\n"0"\n{{\n"path"\t"{root}"\n}}\n'
                f'"1"\n{{\n"path"\t"{extra}"\n}}\n}}\n',
                encoding="utf-8",
            )

            self.assertEqual(library_paths([root]), [root.resolve(), extra.resolve()])

    def test_lists_only_installed_games_with_existing_content(self):
        with tempfile.TemporaryDirectory() as temporary_directory:
            library = Path(temporary_directory)
            steamapps = library / "steamapps"
            common = steamapps / "common"
            common.mkdir(parents=True)
            (common / "Example Game").mkdir()
            (common / "SteamLinuxRuntime").mkdir()

            manifests = {
                "appmanifest_100.acf": (
                    '"appid" "100"\n"name" "Example Game"\n'
                    '"StateFlags" "4"\n"installdir" "Example Game"\n'
                ),
                "appmanifest_200.acf": (
                    '"appid" "200"\n"name" "Queued Game"\n'
                    '"StateFlags" "2"\n"installdir" "Queued Game"\n'
                ),
                "appmanifest_300.acf": (
                    '"appid" "300"\n"name" "Steam Linux Runtime 1.0"\n'
                    '"StateFlags" "4"\n"installdir" "SteamLinuxRuntime"\n'
                ),
                "appmanifest_400.acf": (
                    '"appid" "400"\n"name" "Missing Content"\n'
                    '"StateFlags" "4"\n"installdir" "Missing Content"\n'
                ),
            }
            for filename, contents in manifests.items():
                (steamapps / filename).write_text(contents, encoding="utf-8")

            self.assertEqual(
                installed_games([library]),
                [{"appid": "100", "name": "Example Game", "artworkPath": ""}],
            )


if __name__ == "__main__":
    unittest.main()
