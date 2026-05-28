import json
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent
CONFIG_PATH = REPO_ROOT / "e156-submission" / "config.json"
DOC_PATHS = [
    REPO_ROOT / "F1000_Software_Tool_Article.md",
    REPO_ROOT / "F1000_Reviewer_Rerun_Manifest.md",
    REPO_ROOT / "F1000_Submission_Checklist_RealReview.md",
]
SCRIPT_PATHS = [
    REPO_ROOT / "demo" / "validation.R",
    REPO_ROOT / "demo" / "real_data_validation.R",
]


def test_submission_config_uses_repo_relative_root():
    payload = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))

    assert payload["path"] == ".."
    assert (CONFIG_PATH.parent / payload["path"]).resolve() == REPO_ROOT.resolve()


def test_reviewer_docs_do_not_reference_stale_local_windows_paths():
    for path in DOC_PATHS:
        text = path.read_text(encoding="utf-8")
        assert r"C:\Models\FATIHA_Project" not in text, path
        assert r"C:\HTML apps\reviewer Report.txt" not in text, path


def test_validation_scripts_use_repo_local_and_env_driven_paths():
    for path in SCRIPT_PATHS:
        text = path.read_text(encoding="utf-8")
        assert r"C:\Models\FATIHA_Project" not in text, path
        assert "C:/Models/FATIHA_Project" not in text, path
        assert r"C:\Users\user\OneDrive - NHS\Documents\Pairwise70\data" not in text, path
        assert "C:/Users/user/OneDrive - NHS/Documents/Pairwise70/data" not in text, path
