"""file_manager モジュール: テキストファイルの読み書き・存在確認・コピーを提供するユーティリティ

コメントは日本語で記述し、型ヒントと Google スタイルの docstring を用いる。
"""

from pathlib import Path
import shutil
from typing import Union


def read_text(file_path: Union[str, Path]) -> str:
    """テキストファイルを読み込み文字列を返す。

    Args:
        file_path: 読み込むファイルのパス（str または Path）。

    Returns:
        ファイルの内容を表す文字列。

    Raises:
        FileNotFoundError: ファイルが存在しない場合。
        OSError: 読み込みに失敗した場合。
    """
    p = Path(file_path)
    if not p.exists():
        # 存在しない場合は FileNotFoundError を送出
        raise FileNotFoundError(str(p))
    try:
        return p.read_text(encoding="utf-8")
    except OSError:
        # 読み込み失敗はそのまま伝播させる
        raise


def write_text(file_path: Union[str, Path], content: str) -> None:
    """文字列をテキストファイルに書き込む（上書き）。

    親ディレクトリが存在しない場合は自動作成する。

    Args:
        file_path: 書き込むファイルのパス（str または Path）。
        content: 書き込む文字列。

    Raises:
        OSError: 書き込みに失敗した場合。
    """
    p = Path(file_path)
    # 親ディレクトリを自動作成
    if p.parent:
        p.parent.mkdir(parents=True, exist_ok=True)
    try:
        p.write_text(content, encoding="utf-8")
    except OSError:
        raise


def file_exists(file_path: Union[str, Path]) -> bool:
    """ファイルが存在するかどうかを返す。

    Args:
        file_path: 確認するファイルのパス（str または Path）。

    Returns:
        ファイルが存在する場合は True、そうでない場合は False。
    """
    return Path(file_path).exists()


def copy_file(src_path: Union[str, Path], dst_path: Union[str, Path]) -> Path:
    """ファイルをコピーしてコピー先の Path を返す。

    Args:
        src_path: コピー元ファイルのパス（str または Path）。
        dst_path: コピー先ファイルのパスまたはディレクトリ（str または Path）。

    Returns:
        コピー先のファイルパス（Path）。

    Raises:
        FileNotFoundError: src_path が存在しない場合。
        OSError: コピーに失敗した場合。
    """
    src = Path(src_path)
    if not src.exists():
        raise FileNotFoundError(str(src))

    dst = Path(dst_path)
    # コピー先がディレクトリなら元ファイル名を付与
    if dst.is_dir():
        dst = dst / src.name

    # コピー先の親ディレクトリを作成
    if dst.parent:
        dst.parent.mkdir(parents=True, exist_ok=True)

    try:
        shutil.copy2(src, dst)
    except OSError:
        # コピー失敗は OSError を送出
        raise

    return dst
