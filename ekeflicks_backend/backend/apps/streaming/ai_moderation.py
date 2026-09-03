import subprocess
from pathlib import Path

import numpy as np
import onnxruntime as ort
from PIL import Image


DEFAULT_SAMPLE_INTERVAL_SECONDS = 5

CLASS_NAMES = [
    "nsfl",
    "nsfw",
    "sfw",
]


def extract_moderation_frames(
    source_input,
    output_dir,
    interval_seconds=DEFAULT_SAMPLE_INTERVAL_SECONDS,
):
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    pattern = output_dir / "frame_%06d.jpg"

    command = [
        "ffmpeg",
        "-hide_banner",
        "-loglevel", "error",
        "-i", str(source_input),
        "-vf",
        f"fps=1/{interval_seconds},scale=640:-2",
        "-q:v", "3",
        str(pattern),
    ]

    subprocess.run(
        command,
        check=True,
        timeout=1800,
    )

    frames = sorted(output_dir.glob("frame_*.jpg"))

    return [
        {
            "path": frame_path,
            "timestamp": float(index * interval_seconds),
        }
        for index, frame_path in enumerate(frames)
    ]


def load_moderation_session(model_path):
    return ort.InferenceSession(
        str(model_path),
        providers=["CPUExecutionProvider"],
    )


def preprocess_moderation_image(image_path):
    image = Image.open(image_path).convert("RGB")
    image = image.resize((224, 224))

    array = np.asarray(image, dtype=np.float32)

    # HWC -> CHW
    array = np.transpose(array, (2, 0, 1))

    # Add batch dimension
    array = np.expand_dims(array, axis=0)

    return np.ascontiguousarray(array, dtype=np.float32)


def classify_moderation_frame(session, image_path):
    tensor = preprocess_moderation_image(image_path)

    probabilities = session.run(
        ["probabilities"],
        {
            "image": tensor,
        },
    )[0][0]

    return {
        name: float(probabilities[index])
        for index, name in enumerate(CLASS_NAMES)
    }


DEFAULT_NSFW_REVIEW_THRESHOLD = 0.70
DEFAULT_NSFL_REVIEW_THRESHOLD = 0.60


def analyze_moderation_frames(
    session,
    frames,
    nsfw_threshold=DEFAULT_NSFW_REVIEW_THRESHOLD,
    nsfl_threshold=DEFAULT_NSFL_REVIEW_THRESHOLD,
):
    """
    Analyze sampled video frames and aggregate AI moderation results.

    The AI never rejects content automatically.
    Threshold crossings only request human review.
    """

    maxima = {
        "sfw": 0.0,
        "nsfw": 0.0,
        "nsfl": 0.0,
    }

    sums = {
        "sfw": 0.0,
        "nsfw": 0.0,
        "nsfl": 0.0,
    }

    events = []
    flags = set()

    analyzed = 0

    for frame in frames:
        scores = classify_moderation_frame(
            session,
            frame["path"],
        )

        analyzed += 1

        for category in maxima:
            score = float(scores.get(category, 0.0))
            maxima[category] = max(maxima[category], score)
            sums[category] += score

        timestamp = float(frame["timestamp"])

        if scores["nsfw"] >= nsfw_threshold:
            flags.add("ai_nsfw_review")

            events.append({
                "type": "ai_nsfw",
                "timestamp": timestamp,
                "score": round(float(scores["nsfw"]), 6),
            })

        if scores["nsfl"] >= nsfl_threshold:
            flags.add("ai_graphic_content_review")

            events.append({
                "type": "ai_nsfl",
                "timestamp": timestamp,
                "score": round(float(scores["nsfl"]), 6),
            })

    averages = {
        category: (
            round(sums[category] / analyzed, 6)
            if analyzed
            else 0.0
        )
        for category in sums
    }

    maximum_scores = {
        category: round(value, 6)
        for category, value in maxima.items()
    }

    moderation_scores = {
        "frames_analyzed": analyzed,
        "max": maximum_scores,
        "average": averages,
        "thresholds": {
            "nsfw_review": nsfw_threshold,
            "nsfl_review": nsfl_threshold,
        },
        "classes": ["nsfl", "nsfw", "sfw"],
    }

    return {
        "scores": moderation_scores,
        "events": events,
        "flags": sorted(flags),
    }
