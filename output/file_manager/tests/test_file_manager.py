"""file_manager モジュールの pytest テストコード。"""

import sys
from pathlib import Path

# テスト対象モジュールのパスを追加
sys.path.insert(0, str(Path(__file__).parent.parent / "src"))

import pytest

from file_manager import read_text, write_text, file_exists, copy_file


class TestReadText:
    """read_text 関数のテスト。"""

    def test_read_text_normal(self, tmp_path: Path) -> None:
        """正常系: ファイルの内容が正しく読み込まれること。"""
        p = tmp_path / "file.txt"
        p.write_text("こんにちは", encoding='utf-8')
        assert read_text(p) == "こんにちは"

    def test_read_text_missing_raises(self, tmp_path: Path) -> None:
        """異常系: 存在しないファイルで FileNotFoundError が発生する。"""
        with pytest.raises(FileNotFoundError):
            read_text(tmp_path / "missing.txt")


class TestWriteText:
    """write_text 関数のテスト。"""

    def test_write_text_creates_file_and_parent(self, tmp_path: Path) -> None:
        """親ディレクトリがない場合に自動作成され書き込まれること。"""
        out = tmp_path / "subdir" / "out.txt"
        write_text(out, "データ")
        assert out.read_text(encoding='utf-8') == "データ"


class TestFileExists:
    """file_exists 関数のテスト。"""

    def test_file_exists_true(self, tmp_path: Path) -> None:
        p = tmp_path / "f.txt"
        p.write_text("x", encoding='utf-8')
        assert file_exists(p) is True

    def test_file_exists_false(self, tmp_path: Path) -> None:
        assert file_exists(tmp_path / "nope.txt") is False


class TestCopyFile:
    """copy_file 関数のテスト。"""

    def test_copy_file_to_path(self, tmp_path: Path) -> None:
        src = tmp_path / "src.txt"
        src.write_text("abc", encoding='utf-8')
        dst = tmp_path / "dst.txt"
        result = copy_file(src, dst)
        assert result == dst
        assert dst.read_text(encoding='utf-8') == "abc"

    def test_copy_file_to_directory(self, tmp_path: Path) -> None:
        src = tmp_path / "src2.txt"
        src.write_text("xyz", encoding='utf-8')
        dst_dir = tmp_path / "backup"
        dst_dir.mkdir()
        result = copy_file(src, dst_dir)
        expected = dst_dir / src.name
        assert result == expected
        assert expected.read_text(encoding='utf-8') == "xyz"

    def test_copy_missing_raises(self, tmp_path: Path) -> None:
        with pytest.raises(FileNotFoundError):
            copy_file(tmp_path / "no_src.txt", tmp_path / "dst.txt")
