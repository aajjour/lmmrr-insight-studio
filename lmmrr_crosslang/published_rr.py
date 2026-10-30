"""Python entry point for *published* lmmRRdiag R recursive residuals.

Runs the author-supplied R source via Rscript. The Python prototype core and its
published-R bridge are intentionally separate; this file is NOT a native port.
No bootstrap or calibration is performed by this interface.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
from typing import Any, Mapping

DOI = "10.1080/00949655.2026.2748404"
_ROOT = Path(__file__).resolve().parent.parent

class RRBridgeError(RuntimeError):
    """Failure in the Python/R bridge or the published-R implementation."""


def _root(repo_root: str | os.PathLike[str] | None) -> Path:
    root = Path(repo_root).expanduser().resolve() if repo_root is not None else _ROOT
    if not (root / "R" / "published_rr_bridge.R").is_file():
        raise RRBridgeError(f"Missing R bridge at {root / 'R/published_rr_bridge.R'}")
    src = root / "reference" / "published_r" / "lmmRRdiag" / "R"
    if not (src / "recursive_residuals.R").is_file():
        raise RRBridgeError(
            f"Published R source is missing: {src}. "
            "Import it from the publication master before using Python RR."
        )
    return root


def _rscript(executable: str | None) -> str:
    candidate = executable or shutil.which("Rscript")
    if candidate is None or not shutil.which(candidate):
        raise RRBridgeError("Rscript is not available; install R and make Rscript available in PATH")
    return candidate


def _invoke(config: dict[str, Any], *, root: Path, rscript: str | None, timeout: int) -> dict[str, Any]:
    if timeout < 1:
        raise ValueError("timeout must be positive")
    with tempfile.TemporaryDirectory(prefix="lmmrr_published_bridge_") as temp:
        config_file = Path(temp) / "request.json"
        output_file = Path(temp) / "response.json"
        config["repo_root"] = str(root)
        config["output_json"] = str(output_file)
        config_file.write_text(json.dumps(config, allow_nan=False), encoding="utf-8")
        try:
            proc = subprocess.run(
                [_rscript(rscript), str(root / "R" / "published_rr_bridge.R"), str(config_file)],
                cwd=root,
                text=True,
                capture_output=True,
                timeout=timeout,
                check=False,
            )
        except subprocess.TimeoutExpired as exc:
            raise RRBridgeError(f"R execution exceeded {timeout}s (no bootstrap was requested)") from exc
        data: dict[str, Any] | None = None
        if output_file.is_file():
            try:
                data = json.loads(output_file.read_text(encoding="utf-8"))
            except json.JSONDecodeError as exc:
                raise RRBridgeError("R returned malformed JSON") from exc
        if proc.returncode != 0 or not data or not data.get("ok"):
            reason = (data or {}).get("error", "R bridge failed without a valid result")
            stderr = (proc.stderr or "").strip()[-1800:]
            raise RRBridgeError(f"{reason}\n{stderr}".strip())
        return data


def inspect_published_rr(*, repo_root: str | os.PathLike[str] | None = None,
                         rscript: str | None = None, timeout: int = 60) -> dict[str, Any]:
    """Inspect the actual published R functions and their formal arguments.

    Inspection does not fit an LMM and never calls a bootstrap routine.
    """
    root = _root(repo_root)
    return _invoke({"mode": "inspect"}, root=root, rscript=rscript, timeout=timeout)


def run_published_rr(
    data: Any,
    formula: str,
    *,
    output_dir: str | os.PathLike[str],
    reml: bool = True,
    rr_options: Mapping[str, Any] | None = None,
    repo_root: str | os.PathLike[str] | None = None,
    rscript: str | None = None,
    timeout: int = 180,
) -> dict[str, Any]:
    """Fit an LMM through lme4 and call published rr_recursive_residuals_lmer.

    Parameters
    ----------
    data : CSV path or a pandas DataFrame-like object with ``to_csv``
        Pass a file or DataFrame. R, not statsmodels, fits the LMM.
    formula : str
        Full lme4 mixed model formula, e.g. ``'y ~ x + (x | group)'``.
    output_dir : path
        Destination for original R result summary and numeric components.
    rr_options : mapping, optional
        Named arguments forwarded directly to the original R function.
        Inspect its signature first. Bootstrap/refit arguments are rejected.

    Returns
    -------
    dict
        Original R routine metadata plus paths to its captured numeric outputs.
        No p-values or significance declarations are manufactured.
    """
    if not isinstance(formula, str) or "~" not in formula or "|" not in formula:
        raise ValueError("formula must be an lme4 mixed-model formula with a random-effects term")
    opts = dict(rr_options or {})
    for key in opts:
        if not isinstance(key, str) or not key:
            raise ValueError("R option names must be nonempty strings")
        if any(token in key.lower() for token in ("boot", "refit")):
            raise ValueError("bootstrap/refit options are intentionally disabled in this interface")
    root = _root(repo_root)
    out = Path(output_dir).expanduser().resolve()
    out.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="lmmrr_published_data_") as temp:
        if isinstance(data, (str, os.PathLike)):
            csv_path = Path(data).expanduser().resolve()
            if not csv_path.is_file() or csv_path.suffix.lower() != ".csv":
                raise ValueError("data must point to an existing CSV file")
        elif hasattr(data, "to_csv"):
            csv_path = Path(temp) / "data.csv"
            data.to_csv(csv_path, index=False)
        else:
            raise TypeError("data must be a CSV file path or DataFrame-like object")
        response = _invoke({
            "mode": "run",
            "csv": str(csv_path),
            "formula": formula,
            "reml": bool(reml),
            "rr_options": opts,
            "output_dir": str(out),
        }, root=root, rscript=rscript, timeout=timeout)
    source_csv = response.get("numeric_csv")
    if source_csv and Path(source_csv).is_file():
        from .published_plot import make_report
        report = make_report(source_csv, out / "published_rr_numeric_explorer.html")
        response["numeric_html"] = str(report)
    return response


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        description="Call the published lmmRRdiag recursive residuals from Python (R-backed; bootstrap disabled)."
    )
    parser.add_argument("--inspect", action="store_true", help="print published function signatures")
    parser.add_argument("--data", help="CSV input")
    parser.add_argument("--formula", help="lme4 formula, including random-effects term")
    parser.add_argument("--output", default="results/published_python_rr")
    parser.add_argument("--rr-options", default="{}", help="JSON object forwarded as named R arguments")
    parser.add_argument("--repo-root", default=None)
    parser.add_argument("--rscript", default=None)
    parser.add_argument("--timeout", type=int, default=180)
    parser.add_argument("--ml", action="store_true", help="use ML instead of REML")
    args = parser.parse_args(argv)
    try:
        if args.inspect:
            result = inspect_published_rr(repo_root=args.repo_root, rscript=args.rscript)
        else:
            if not args.data or not args.formula:
                parser.error("--data and --formula required unless --inspect")
            opts = json.loads(args.rr_options)
            if not isinstance(opts, dict):
                parser.error("--rr-options must be a JSON object")
            result = run_published_rr(args.data, args.formula,
                output_dir=args.output, reml=not args.ml, rr_options=opts,
                repo_root=args.repo_root, rscript=args.rscript, timeout=args.timeout)
    except (RRBridgeError, ValueError, TypeError) as exc:
        parser.exit(2, f"LMM RR R-backed error: {exc}\n")
    print(json.dumps(result, indent=2, ensure_ascii=False))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
