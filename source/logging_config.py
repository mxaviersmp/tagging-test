import json
import logging
import os
import sys


class JsonFormatter(logging.Formatter):

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "severity": record.levelname,
            "message": record.getMessage(),
            "logger": record.name,
            "timestamp": self.formatTime(record, self.datefmt),
        }

        if "CLOUD_RUN_JOB" in os.environ:
            log_entry["job"] = os.getenv("CLOUD_RUN_JOB")
            log_entry["execution"] = os.getenv("CLOUD_RUN_EXECUTION")
            log_entry["taskIndex"] = os.getenv("CLOUD_RUN_TASK_INDEX")

        if record.exc_info:
            log_entry["stack"] = self.formatException(record.exc_info)

        return json.dumps(log_entry)


def setup_root_logger(level=logging.INFO):
    root = logging.getLogger()

    if root.hasHandlers():
        root.handlers.clear()

    root.setLevel(level)

    handler = logging.StreamHandler(sys.stdout)

    if "K_SERVICE" in os.environ or "CLOUD_RUN_JOB" in os.environ:
        formatter = JsonFormatter()
    else:
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )

    handler.setFormatter(formatter)
    root.addHandler(handler)
