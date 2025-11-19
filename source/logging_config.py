import json
import logging
import os
import sys


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "severity": record.levelname,
            "message": record.getMessage(),
            "name": record.name,
            "timestamp": self.formatTime(record, self.datefmt)
        }
        if record.exc_info:
            log_entry["message"] += "\n" + self.formatException(record.exc_info)
        return json.dumps(log_entry)


def setup_root_logger(level: int = logging.INFO) -> None:
    root_logger = logging.getLogger()

    if root_logger.hasHandlers():
        root_logger.handlers.clear()

    root_logger.setLevel(level)
    handler = logging.StreamHandler(sys.stdout)

    if "CLOUD_RUN_JOB" in os.environ:
        formatter = JsonFormatter()
    else:
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )

    handler.setFormatter(formatter)
    root_logger.addHandler(handler)
