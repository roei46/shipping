import sentry_sdk

from config import settings


def init_sentry():
    sentry_sdk.init(
        dsn=settings.sentry_dsn,
        environment=settings.sentry_environment,
        send_default_pii=True,
        traces_sample_rate=1.0,
        profile_session_sample_rate=1.0,
        profile_lifecycle="trace",
        enable_logs=True,
    )
