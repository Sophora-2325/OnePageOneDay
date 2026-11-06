#!/usr/bin/env python3
"""一页英语 Android 发布包构建器。

工程路径含中文时，Gradle 以 GBK 把路径传给 Dart，Dart 按 UTF-8 解码成乱码，
AOT snapshotter 报 `Unable to read file: .../app.dill`。所以先把源码同步到
纯 ASCII 临时目录再构建，产物拷回 <project>/dist/。

用法：
    python tools/build_android.py                    # 通用包 + 三个 ABI 分包
    python tools/build_android.py --universal-only  # 只出通用包
    python tools/build_android.py --install         # 出包后覆盖安装到已连接真机
"""
from __future__ import annotations

import argparse
import hashlib
import os
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]
APK_DIR = pathlib.Path("build/app/outputs/flutter-apk")
IGNORE = shutil.ignore_patterns(
    ".git", "build", ".gradle", ".dart_tool", ".idea",
    "*.iml", ".cxx", "*.log", "node_modules",
)
VARIANTS = {
    "app-release.apk": "universal",
    "app-arm64-v8a-release.apk": "arm64-v8a",
    "app-armeabi-v7a-release.apk": "armeabi-v7a",
    "app-x86_64-release.apk": "x86_64",
}


def app_version() -> str:
    text = (ROOT / "pubspec.yaml").read_text(encoding="utf-8")
    m = re.search(r"^version:\s*(\S+)", text, re.M)
    if not m:
        raise SystemExit("pubspec.yaml 缺少 version 字段")
    return m.group(1)


def sync_to_ascii(work: pathlib.Path) -> pathlib.Path:
    """工程路径已是 ASCII 时直接原地构建，避免多余副本。"""
    if str(ROOT).isascii():
        return ROOT
    assert work.parent.name.startswith("yiye_build_"), work
    if work.exists():
        shutil.rmtree(work)
    work.parent.mkdir(parents=True, exist_ok=True)
    shutil.copytree(ROOT, work, ignore=IGNORE)
    # sqlite3 的 native build hook 默认从 GitHub 下载预编译 .so；本目录每次重建，
    # 不带上缓存就只能在构建时联网，代理 502 会直接让 release 构建失败。
    # 复用真实工程上次成功构建留下的 shared 缓存，hook 校验 SHA256 后直接用。
    shared = pathlib.Path(".dart_tool") / "hooks_runner" / "shared"
    if (ROOT / shared).is_dir():
        dst = work / shared
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(ROOT / shared, dst)
        count = len(list(dst.rglob("*.so")))
        print(f"  复用 sqlite3 预编译缓存：{count} 个 .so", flush=True)
    for must in ("pubspec.yaml", "android/app/build.gradle.kts", "lib/main.dart"):
        if not (work / must).exists():
            raise SystemExit(f"同步后缺关键文件：{must}")
    return work


def find_adb() -> str | None:
    found = shutil.which("adb")
    if found:
        return found
    local = pathlib.Path(os.environ.get("LOCALAPPDATA", "")) / "Android" / "Sdk" / "platform-tools" / "adb.exe"
    return str(local) if local.is_file() else None


def run(cmd: list[str], cwd: pathlib.Path) -> None:
    # Windows 下 shutil.which 通常解析到 flutter.bat，CreateProcess 不能直接执行。
    if pathlib.Path(cmd[0]).suffix.lower() in (".bat", ".cmd"):
        cmd = ["cmd", "/c", *cmd]
    print(">>", " ".join(cmd), flush=True)
    if subprocess.run(cmd, cwd=cwd).returncode:
        raise SystemExit(f"命令失败：{' '.join(cmd)}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--universal-only", action="store_true")
    ap.add_argument("--install", action="store_true", help="出包后 adb install -r 覆盖安装")
    args = ap.parse_args()

    version = app_version()
    short = version.split("+")[0]
    work = sync_to_ascii(pathlib.Path(tempfile.gettempdir()) / f"yiye_build_{short.replace('.', '')}" / "cet6_app")
    print(f"版本 {version}｜构建目录 {work}", flush=True)

    flutter = shutil.which("flutter") or shutil.which("flutter.bat")
    if not flutter:
        raise SystemExit("找不到 flutter 命令")
    run([flutter, "build", "apk", "--release"], work)
    if not args.universal_only:
        run([flutter, "build", "apk", "--release", "--split-per-abi"], work)

    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    for src_name, abi in VARIANTS.items():
        src = work / APK_DIR / src_name
        if not src.exists():
            continue
        name = f"yiye-{short}-{abi}.apk"
        dst = dist / name
        shutil.copy2(src, dst)
        print(f"  {name:36s} {dst.stat().st_size / 1024 / 1024:6.1f} MB")
    # 校验和覆盖 dist 下该版本的全部包，避免只出单包时把已有包漏掉。
    lines = [
        f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.name}"
        for p in sorted(dist.glob(f"yiye-{short}-*.apk"))
    ]
    # 写 bytes 固定 LF；Windows 的 write_text 会转 CRLF，sha256sum -c 会把 \r 当文件名。
    (dist / "SHA256SUMS.txt").write_bytes(("\n".join(lines) + "\n").encode("utf-8"))
    print(f"产物目录：{dist}｜校验和 {len(lines)} 项", flush=True)

    if args.install:
        adb = find_adb()
        if not adb:
            print("未找到 adb，跳过安装（可把 Android SDK/platform-tools 加入 PATH）", file=sys.stderr)
            return
        # 用 ASCII 构建目录里的原包安装，避开中文路径传参编码问题。
        apk = work / APK_DIR / "app-arm64-v8a-release.apk"
        if not apk.exists():
            print("缺 arm64 分包，跳过安装", file=sys.stderr)
            return
        run([adb, "install", "-r", str(apk)], ROOT)


if __name__ == "__main__":
    main()
