import json
import subprocess

import numpy as np


# Candidate ladder.
# These are starting points. The final bitrate is adjusted according
# to the measured complexity of the source.
CANDIDATE_RENDITIONS = [
    {
        'quality': '360p',
        'width': 640,
        'height': 360,
        'base_bandwidth': 700_000,
        'min_bandwidth': 450_000,
        'max_bandwidth': 1_000_000,
    },
    {
        'quality': '480p',
        'width': 854,
        'height': 480,
        'base_bandwidth': 1_200_000,
        'min_bandwidth': 750_000,
        'max_bandwidth': 1_800_000,
    },
    {
        'quality': '720p',
        'width': 1280,
        'height': 720,
        'base_bandwidth': 2_500_000,
        'min_bandwidth': 1_500_000,
        'max_bandwidth': 3_500_000,
    },
    {
        'quality': '1080p',
        'width': 1920,
        'height': 1080,
        'base_bandwidth': 4_500_000,
        'min_bandwidth': 2_800_000,
        'max_bandwidth': 6_500_000,
    },
    {
        'quality': '1440p',
        'width': 2560,
        'height': 1440,
        'base_bandwidth': 8_000_000,
        'min_bandwidth': 5_000_000,
        'max_bandwidth': 12_000_000,
    },
    {
        'quality': '2160p',
        'width': 3840,
        'height': 2160,
        'base_bandwidth': 15_000_000,
        'min_bandwidth': 9_000_000,
        'max_bandwidth': 22_000_000,
    },
]


def probe_source_dimensions(source_input):
    command = [
        'ffprobe',
        '-v', 'error',
        '-select_streams', 'v:0',
        '-show_entries',
        'stream=width,height,avg_frame_rate,bit_rate',
        '-of', 'json',
        str(source_input),
    ]

    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
        timeout=120,
    )

    payload = json.loads(result.stdout or '{}')
    streams = payload.get('streams') or []

    if not streams:
        raise ValueError('No video stream found')

    stream = streams[0]

    return {
        'width': int(stream.get('width') or 0),
        'height': int(stream.get('height') or 0),
        'frame_rate': stream.get('avg_frame_rate') or '',
        'bit_rate': int(stream.get('bit_rate') or 0),
    }


def select_candidate_renditions(source_width, source_height):
    """
    Never upscale beyond the source dimensions.

    Portrait videos are compared using their long/short dimensions so that
    orientation does not incorrectly eliminate valid renditions.
    """
    source_long = max(source_width, source_height)
    source_short = min(source_width, source_height)

    selected = []

    for rendition in CANDIDATE_RENDITIONS:
        rendition_long = max(rendition['width'], rendition['height'])
        rendition_short = min(rendition['width'], rendition['height'])

        if (
            rendition_long <= source_long
            and rendition_short <= source_short
        ):
            selected.append(dict(rendition))

    # Very small sources still need one playable rendition.
    if not selected:
        smallest = dict(CANDIDATE_RENDITIONS[0])

        smallest['width'] = source_width
        smallest['height'] = source_height
        smallest['quality'] = f'{source_height}p'

        selected.append(smallest)

    return selected


def complexity_multiplier(complexity_score):
    """
    Convert normalized complexity [0..1] to a bitrate multiplier.

    Low complexity  -> ~0.75
    Medium          -> ~1.00
    High complexity -> ~1.25
    """
    score = max(0.0, min(1.0, float(complexity_score)))

    return 0.75 + (score * 0.50)


def build_per_title_ladder(
    source_width,
    source_height,
    complexity_score=0.5,
):
    candidates = select_candidate_renditions(
        source_width,
        source_height,
    )

    multiplier = complexity_multiplier(complexity_score)

    ladder = []

    for rendition in candidates:
        bitrate = int(
            rendition['base_bandwidth'] * multiplier
        )

        bitrate = max(
            rendition['min_bandwidth'],
            min(rendition['max_bandwidth'], bitrate),
        )

        ladder.append({
            'quality': rendition['quality'],
            'width': rendition['width'],
            'height': rendition['height'],
            'bandwidth': bitrate,
        })

    return ladder


def detect_shots(
    source_input,
    scene_threshold=0.35,
):
    """
    Detect scene cuts using FFmpeg scene score metadata.

    Returns:
        [
            {
                "timestamp": 12.48,
                "score": 0.62,
            },
            ...
        ]
    """
    command = [
        'ffmpeg',
        '-hide_banner',
        '-i', str(source_input),
        '-vf',
        (
            f"select='gt(scene,{scene_threshold})',"
            "metadata=print"
        ),
        '-an',
        '-f', 'null',
        '-',
    ]

    result = subprocess.run(
        command,
        capture_output=True,
        text=True,
        timeout=1800,
    )

    stderr = result.stderr or ''

    shots = []
    current_timestamp = None

    for line in stderr.splitlines():
        if 'pts_time:' in line:
            try:
                value = line.split('pts_time:', 1)[1].split()[0]
                current_timestamp = float(value)
            except (ValueError, IndexError):
                current_timestamp = None

        if 'lavfi.scene_score=' in line:
            try:
                score = float(
                    line.split('lavfi.scene_score=', 1)[1].split()[0]
                )
            except (ValueError, IndexError):
                continue

            shots.append({
                'timestamp': current_timestamp,
                'score': score,
            })

    return shots


def calculate_complexity_score(
    shots,
    duration_seconds,
):
    """
    Complexity V1 based on:
    - scene cut frequency
    - average scene transition strength

    Returns normalized score [0..1].
    """
    duration = float(duration_seconds or 0)

    if duration <= 0:
        return 0.5

    shot_count = len(shots)

    cuts_per_minute = (
        shot_count / duration
    ) * 60.0

    if shots:
        average_scene_score = sum(
            float(shot.get('score') or 0)
            for shot in shots
        ) / len(shots)
    else:
        average_scene_score = 0.0

    # About 30 cuts/minute is considered highly dynamic
    # for this first version.
    normalized_cut_rate = min(
        1.0,
        cuts_per_minute / 30.0,
    )

    normalized_scene_strength = min(
        1.0,
        average_scene_score,
    )

    complexity = (
        normalized_cut_rate * 0.70
        + normalized_scene_strength * 0.30
    )

    return round(
        max(0.0, min(1.0, complexity)),
        4,
    )


def analyze_per_title_source(
    source_input,
    duration_seconds,
):
    source = probe_source_dimensions(source_input)

    shots = detect_shots(source_input)

    complexity_score = calculate_complexity_score(
        shots,
        duration_seconds,
    )

    ladder = build_per_title_ladder(
        source['width'],
        source['height'],
        complexity_score=complexity_score,
    )

    return {
        'source': source,
        'shot_count': len(shots),
        'shots': shots,
        'complexity_score': complexity_score,
        'ladder': ladder,
    }


def measure_visual_complexity(
    source_input,
    sample_fps=2,
    width=320,
    height=180,
):
    """
    Estimate temporal motion and spatial detail using sampled grayscale frames.

    Returns normalized values [0..1].
    """
    command = [
        'ffmpeg',
        '-hide_banner',
        '-loglevel', 'error',
        '-i', str(source_input),
        '-vf',
        f'fps={sample_fps},scale={width}:{height},format=gray',
        '-f', 'rawvideo',
        '-pix_fmt', 'gray',
        '-',
    ]

    result = subprocess.run(
        command,
        check=True,
        capture_output=True,
        timeout=1800,
    )

    frame_size = width * height
    raw = result.stdout or b''

    if len(raw) < frame_size:
        return {
            'frames_analyzed': 0,
            'motion_score': 0.0,
            'detail_score': 0.0,
        }

    frame_count = len(raw) // frame_size

    data = np.frombuffer(
        raw[:frame_count * frame_size],
        dtype=np.uint8,
    )

    frames = data.reshape(
        frame_count,
        height,
        width,
    ).astype(np.float32)

    motion_values = []

    for index in range(1, frame_count):
        difference = np.abs(
            frames[index] - frames[index - 1]
        )

        motion_values.append(
            float(np.mean(difference) / 255.0)
        )

    detail_values = []

    for frame in frames:
        horizontal = np.abs(
            frame[:, 1:] - frame[:, :-1]
        )

        vertical = np.abs(
            frame[1:, :] - frame[:-1, :]
        )

        detail = (
            float(np.mean(horizontal))
            + float(np.mean(vertical))
        ) / (2.0 * 255.0)

        detail_values.append(detail)

    raw_motion = (
        float(np.mean(motion_values))
        if motion_values
        else 0.0
    )

    raw_detail = (
        float(np.mean(detail_values))
        if detail_values
        else 0.0
    )

    # Normalize empirical image differences.
    # These constants will later be calibrated against real EKEFLICKS content.
    motion_score = min(
        1.0,
        raw_motion / 0.12,
    )

    detail_score = min(
        1.0,
        raw_detail / 0.12,
    )

    return {
        'frames_analyzed': frame_count,
        'raw_motion': round(raw_motion, 6),
        'raw_detail': round(raw_detail, 6),
        'motion_score': round(motion_score, 4),
        'detail_score': round(detail_score, 4),
    }


def calculate_complexity_score_v2(
    shots,
    duration_seconds,
    motion_score,
    detail_score,
):
    """
    Per-title complexity V2.

    Weighting:
      30% shot/cut activity
      50% temporal motion
      20% spatial detail
    """
    duration = float(duration_seconds or 0)

    if duration <= 0:
        return 0.5

    cuts_per_minute = (
        len(shots) / duration
    ) * 60.0

    normalized_cut_rate = min(
        1.0,
        cuts_per_minute / 30.0,
    )

    complexity = (
        normalized_cut_rate * 0.30
        + float(motion_score) * 0.50
        + float(detail_score) * 0.20
    )

    return round(
        max(0.0, min(1.0, complexity)),
        4,
    )


def analyze_per_title_source_v2(
    source_input,
    duration_seconds,
):
    source = probe_source_dimensions(source_input)

    shots = detect_shots(source_input)

    visual = measure_visual_complexity(
        source_input,
    )

    complexity_score = calculate_complexity_score_v2(
        shots,
        duration_seconds,
        visual['motion_score'],
        visual['detail_score'],
    )

    ladder = build_per_title_ladder(
        source['width'],
        source['height'],
        complexity_score=complexity_score,
    )

    return {
        'version': 'eke-per-title-v2',
        'source': source,
        'shot_count': len(shots),
        'shots': shots,
        'visual_complexity': visual,
        'complexity_score': complexity_score,
        'ladder': ladder,
    }
